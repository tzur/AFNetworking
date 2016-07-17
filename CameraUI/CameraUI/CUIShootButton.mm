// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIShootButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIShootButton ()

/// List of \c CUIShootButtonDrawer objects that draw to this view.
@property (readonly, nonatomic) NSArray<id<CUIShootButtonDrawer>> *drawers;

@end

@implementation CUIShootButton

- (instancetype)initWithDrawers:(NSArray<id<CUIShootButtonDrawer>> *)drawers {
  LTParameterAssert(drawers, @"drawers is nil");
  if (self = [super initWithFrame:CGRectZero]) {
    _drawers = [drawers copy];
    self.opaque = NO;
  }
  return self;
}

- (void)drawRect:(CGRect __unused)rect {
  for (id<CUIShootButtonDrawer> drawer in self.drawers) {
    [drawer drawToButton:self];
  }
}

- (void)setEnabled:(BOOL)enabled {
  [super setEnabled:enabled];
  [self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted {
  [super setHighlighted:highlighted];
  [self setNeedsDisplay];
}

- (void)setProgress:(CGFloat)progress {
  LTParameterAssert(progress <= 1 && progress >= 0, @"progress is out of range: %f", progress);
  _progress = progress;
  [self setNeedsDisplay];
}

@end

NS_ASSUME_NONNULL_END
