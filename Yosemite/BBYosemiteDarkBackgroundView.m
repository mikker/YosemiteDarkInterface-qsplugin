#import "BBYosemiteDarkBackgroundView.h"

@implementation BBYosemiteDarkBackgroundView

- (void)drawRect:(NSRect)rect {
  rect = [self bounds];
  
  NSBezierPath *roundRect = [NSBezierPath bezierPath];
  CGFloat minRadius = MIN(NSWidth(rect), NSHeight(rect) )/2;
  
  [roundRect appendBezierPathWithRoundedRectangle:rect withRadius:MIN(minRadius, 5)];
  [roundRect addClip];
  
  [[NSColor colorWithRed:.1 green:.1 blue:.1 alpha:.99] set];
  NSRectFill(rect);

  [super drawRect:rect];
}

@end
