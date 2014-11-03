#import "BBYosemiteDarkSearchObjectView.h"

@implementation BBYosemiteDarkSearchObjectView
+ (Class)cellClass { return [BBObjectCell class]; }
@end

@implementation BBCollectingSearchObjectView
+ (Class)cellClass { return [BBObjectCell class]; }

- (void)textDidChange:(NSNotification *)notification
{
  NSString *string = [[notification object] string];

  // I have no idea what is meant by 'short circuit'
  if ([string isEqualToString:@" "]) {
    [self shortCircuit:self];
    return;
  }

  // Don't update text as we go along - wait untill didEnd
  //[self setObjectValue:[QSObject objectWithString:string]];

  [self setMatchedString:nil];
}

- (void)textDidEndEditing:(NSNotification *)notification
{
  NSString *string = [[[notification object] string] copy];

  // I have no idea what is meant by 'short circuit'
  if (![string isEqualToString:@" "]) {
    // only set the object value if it's not a 'short circuit'
    [self setObjectValue:[QSObject objectWithString:string]];
  }

  // Don't realign the image
  //[[self cell] setImagePosition:-1];

  [self setMatchedString:nil];
  [[[self currentEditor] enclosingScrollView] removeFromSuperview];
  [self setCurrentEditor:nil];
}

@end

@implementation BBObjectCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {  
  BOOL isFirstResponder = [[controlView window] firstResponder] == controlView && ![controlView isKindOfClass:[NSTableView class]];
  BOOL dropTarget = ([self isHighlighted] && ([self highlightsBy] & NSChangeBackgroundCellMask) && ![self isBezeled]);

	NSColor *fillColor;
	NSColor *strokeColor = [NSColor clearColor];

  if (isFirstResponder) {
    fillColor = [self highlightColor];
  } else {
    fillColor = [self backgroundColor];
  }

  if (dropTarget) {
    fillColor = [NSColor colorWithRed:0.77 green:0.91 blue:0.96 alpha:1];
  }

  [fillColor setFill];
	[strokeColor setStroke];

  NSBezierPath *roundRect = [NSBezierPath bezierPath];
  [roundRect appendBezierPathWithRoundedRectangle:cellFrame withRadius:NSHeight(cellFrame)/cellRadiusFactor];
  [roundRect fill];

	[self drawInteriorWithFrame:[self drawingRectForBounds:cellFrame] inView:controlView];
}

- (NSRect)titleRectForBounds:(NSRect)theRect
{
  NSRect rect = theRect;
  rect.size.width -= 100;
  rect = NSOffsetRect(rect, 48, 0);
  return rect;
}

- (void)drawTextForObject:(QSObject *)drawObject withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  if ([self imagePosition] == NSImageOnly) return;

  NSString *abbrString = nil;
  if ([controlView respondsToSelector:@selector(matchedString)])
    abbrString = [(QSSearchObjectView *)controlView matchedString];

  NSString *nameString = nil;
  NSIndexSet *hitMask = nil;

  id ranker = [drawObject ranker];
  if (ranker && abbrString)
    nameString = [ranker matchedStringForAbbreviation:abbrString hitmask:&hitMask inContext:nil];

  if (!nameString)
    nameString = [drawObject displayName];

  BOOL rankedStringIsName = [nameString isEqualToString:[drawObject displayName]] || nameString == nil;
  if (!nameString) {
    // fall back to the identifier if no reasonable name can be found
    nameString = [drawObject identifier];
  }
  if (!nameString) {
    // Couldn't find anything sensible to use for the name, fallback to avoid a crash
    nameString = @"Unknown";
  }

  BOOL useAlternateColor = [controlView isKindOfClass:[NSTableView class]] && [(NSTableView *)controlView isRowSelected:[(NSTableView *)controlView rowAtPoint:cellFrame.origin]];
  NSColor *mainColor = (textColor ? textColor : (useAlternateColor ? [NSColor alternateSelectedControlTextColor] : [NSColor controlTextColor]));
  NSColor *fadedColor = [mainColor colorWithAlphaComponent:0.50];
  NSRect textDrawRect = [self titleRectForBounds:cellFrame];

  NSMutableAttributedString *titleString = [[[NSMutableAttributedString alloc] initWithString:nameString] autorelease];
  [titleString setAttributes:rankedStringIsName ? nameAttributes : detailsAttributes range:NSMakeRange(0, [titleString length])];

  // Bring out the matched letters
  if (abbrString && ![abbrString hasPrefix:@"QSActionMnemonic"]) {
    [titleString addAttribute:NSForegroundColorAttributeName value:rankedStringIsName ? fadedColor : [fadedColor colorWithAlphaComponent:0.8] range:NSMakeRange(0, [titleString length])];

    NSUInteger i = 0;
    NSUInteger j = 0;
    NSUInteger hits[[titleString length]];
    NSUInteger count = [hitMask getIndexes:(NSUInteger *)&hits maxCount:[titleString length] inIndexRange:nil];
    NSDictionary *attributes = @{
      NSForegroundColorAttributeName:                                 rankedStringIsName ? mainColor : fadedColor
    };
    for(i = 0; i<count; i += j) {
      for (j = 1; i+j<count && hits[i+j-1] +1 == hits[i+j]; j++);
      [titleString addAttributes:attributes range:NSMakeRange(hits[i], j)];
    }
  } else {
    [titleString addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithDouble:-1.0] range:NSMakeRange(0, [titleString length])];
  }
//
//  // Ranked string and nameString aren't the same. Show 'nameString  ⟷ rankedString' in the UI
//  if (!rankedStringIsName && [drawObject displayName].length) {
//    [titleString addAttribute:NSFontAttributeName value:detailsFont range:NSMakeRange(0,[titleString length])];
//    NSMutableAttributedString *attributedNameString = [[NSMutableAttributedString alloc] initWithString:[drawObject displayName]];
//    [attributedNameString setAttributes:nameAttributes range:NSMakeRange(0, [[drawObject displayName] length])];
//
//    [attributedNameString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" ⟷ " attributes:rankedNameAttributes] autorelease]];
//    // the replaceCharacters... method inserts the new string into the receiver at the start of the work (range.location and range.length are 0)
//    [titleString replaceCharactersInRange:NSMakeRange(0,0) withAttributedString:attributedNameString];
//    [attributedNameString release];
//  }

  if (showDetails) {
    NSString *detailsString = [drawObject details];
    
    NSRange returnRange = [detailsString rangeOfString:@"\n"];
    if (returnRange.location != NSNotFound) {
      detailsString = [detailsString substringToIndex:returnRange.location];
    }

    detailsAttributes = [detailsAttributes mutableCopy];
    [detailsAttributes setValue:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
    
    if (detailsString && detailsString.length && ![detailsString isEqualToString:nameString]) {
      [titleString appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",detailsString] attributes:detailsAttributes] autorelease]];
    }
  }

  NSRect centerRect = rectFromSize([titleString size]);
  centerRect.size.width = NSWidth(textDrawRect);
  centerRect.size.height = MIN(NSHeight(textDrawRect), centerRect.size.height);
  [titleString drawInRect:centerRectInRect(centerRect, textDrawRect)];
}

@end




