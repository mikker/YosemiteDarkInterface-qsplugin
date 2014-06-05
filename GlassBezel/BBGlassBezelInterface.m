#import "BBGlassBezelInterface.h"

@interface BBGlassBezelInterface () {
  CGRect initialRect;
}
@end

@implementation BBGlassBezelInterface

- (id)init {
	return [self initWithWindowNibName:@"BBGlassBezelInterface"];
}

- (void)windowDidLoad {
  initialRect = centerRectInRect([[self window] frame], [[NSScreen mainScreen] frame]);

  [super windowDidLoad];
  
  QSWindow *window = (QSWindow *)[self window];
  [window setLevel:NSPopUpMenuWindowLevel];
  [window setBackgroundColor:[NSColor clearColor]];
  [window setOpaque:NO];

  [window setHideOffset:NSMakePoint(0, 0)];
  [window setShowOffset:NSMakePoint(0, 0)];
  
  [window setMovableByWindowBackground:NO];
  [window setFastShow:YES];
  [window setHasShadow:YES];

  [window setFrame:standardRect display:YES];

  NSArray *theControls = [NSArray arrayWithObjects:dSelector, aSelector, iSelector, nil];
  for(QSSearchObjectView *theControl in theControls) {
    QSObjectCell *theCell = [theControl cell];

    [theControl setResultsPadding:NSMinY([dSelector frame])];
    [theControl setPreferredEdge:NSMaxXEdge];
    [theControl setTextCellFont:[NSFont systemFontOfSize:16]];

    [(QSWindow *)[(theControl)->resultController window] setHideOffset:NSMakePoint(0, NSMinX([iSelector frame]))];
    [(QSWindow *)[(theControl)->resultController window] setShowOffset:NSMakePoint(0, NSMinX([dSelector frame]))];
    
    [theCell setBackgroundColor:[NSColor clearColor]];
    [theCell setHighlightColor:[NSColor colorWithRed:0 green:0 blue:0 alpha:.1]];
    
    [theCell setFont:[NSFont fontWithName:@"HelveticaNeue-Thin" size:26]];

    [theCell setShowDetails:NO];
    [theCell setTextColor:[NSColor darkGrayColor]];
    [theCell setState:NSOnState];
    [theCell setCellRadiusFactor:20];
    [theCell setIconSize:QSSize48];
    [theCell setImagePosition:NSImageRight];
  }
  
  float imageAlpha = .2;
  [self.image1 setAlphaValue:imageAlpha];
  [self.image2 setAlphaValue:imageAlpha];
  [self.image3 setAlphaValue:imageAlpha];

  [self contractWindow:nil];
}

- (void)showIndirectSelector:(id)sender {
  if (![iSelector superview] && !expanded)
    [iSelector setFrame:NSOffsetRect([aSelector frame],0,-64)];
  [super showIndirectSelector:sender];
}

- (NSSize) maxIconSize {
  return QSSize128;
}

- (void)showMainWindow:(id)sender {
  [[self window] setFrame:[self rectForState:[self expanded]]  display:YES];
  if ([[self window] isVisible]) [[self window] pulse:self];
  [super showMainWindow:sender];
  //    Does this need to be here?
  [[[self window] contentView] setNeedsDisplay:YES];
}

- (void)expandWindow:(id)sender {
  if (![self expanded])
    [[self window] setFrame:[self rectForState:YES] display:YES animate:YES];
  [super expandWindow:sender];
}

- (void)contractWindow:(id)sender {
  if ([self expanded])
    [[self window] setFrame:[self rectForState:NO] display:YES animate:YES];
  [super contractWindow:sender];
}

- (NSRect)rectForState:(BOOL)shouldExpand {
  NSRect newRect = initialRect;
  NSRect screenRect = [[NSScreen mainScreen] frame];
  
  if (!shouldExpand) {
    newRect.size.height -= 64;
  }
  
  NSLog(@"pos:%f", NSHeight(screenRect) / 4.0);
  return NSOffsetRect(centerRectInRect(newRect, screenRect), 0, NSHeight(screenRect) / 4);
}

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect {
  return NSOffsetRect(NSInsetRect(rect, 8, 0), 0, 0);
}

- (NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame {
  return 0.01;
}

- (void)searchObjectChanged:(NSNotification*)notif {
  [super searchObjectChanged:notif];
  if ([[notif object] isKindOfClass:[QSCollectingSearchObjectView class]]) {
    [[(QSCollectingSearchObjectView *)[notif object] cell] setImagePosition:NSImageRight];
  }
}

@end
