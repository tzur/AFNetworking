// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTGridDrawingManager.h"

#import "LTGLContext.h"
#import "LTGridDrawer.h"
#import "UIColor+Vector.h"

@interface LTGridDrawingManager ()

/// Drawer used for drawing the pixel grid.
@property (strong, nonatomic) LTGridDrawer *gridDrawer;

@end

@implementation LTGridDrawingManager

/// Default Values.
static UIColor * const kDefaultColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
static const CGFloat kDefaultMaxOpacity = 0.5;
static const CGFloat kDefaultMinZoomScale = 5.0;
static const CGFloat kDefaultMaxZoomScale = 5.0;

/// Blend function used for drawing the pixel grid, keeping the target's alpha value. The
/// \c sourceRGB factor is not \c FuncOne since a premultiplied result is expected.
static const LTGLContextBlendFuncArgs kLTGLContextBlendFuncGrid = {
  .sourceRGB = LTGLContextBlendFuncDstAlpha,
  .destinationRGB = LTGLContextBlendFuncOneMinusSrcAlpha,
  .sourceAlpha = LTGLContextBlendFuncZero,
  .destinationAlpha = LTGLContextBlendFuncOne
};

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithContentSize:(CGSize)size {
  if (self = [super init]) {
    [self setDefaults];
    self.gridDrawer = [self createGridDrawerWithContentSize:size];
  }
  return self;
}

- (void)setDefaults {
  self.color = kDefaultColor;
  self.maxOpacity = kDefaultMaxOpacity;
  self.minZoomScale = kDefaultMinZoomScale;
  self.maxZoomScale = kDefaultMaxZoomScale;
}

- (LTGridDrawer *)createGridDrawerWithContentSize:(CGSize)size {
  LTGridDrawer *gridDrawer = [[LTGridDrawer alloc] initWithSize:size];
  gridDrawer.color = self.color.lt_ltVector;
  return gridDrawer;
}

#pragma mark -
#pragma mark Draw
#pragma mark -

- (void)drawContentRegion:(CGRect)region toFramebufferWithSize:(CGSize)size {
  self.gridDrawer.opacity = [self gridOpacityForZoomScale:std::min(size / region.size)];
  if (self.gridDrawer.opacity > 0) {
    [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
      context.blendEnabled = YES;
      context.blendEquation = kLTGLContextBlendEquationDefault;
      context.blendFunc = kLTGLContextBlendFuncGrid;
      [self.gridDrawer drawSubGridInRegion:region inFramebufferWithSize:size];
    }];
  }
}

- (CGFloat)gridOpacityForZoomScale:(CGFloat)zoomScale {
  if (zoomScale < self.minZoomScale || self.maxZoomScale <= self.minZoomScale) {
    return 0;
  }

  CGFloat t = (zoomScale - self.minZoomScale);
  t /= (self.maxZoomScale - self.minZoomScale);
  return MIN(1, t) * self.maxOpacity;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setColor:(UIColor *)color {
  _color = color ?: kDefaultColor;
  self.gridDrawer.color = _color.lt_ltVector;
}

- (void)setMaxOpacity:(CGFloat)maxOpacity {
  _maxOpacity = MIN(MAX(maxOpacity, 0), 1);
}

- (void)setMinZoomScale:(CGFloat)minZoomScale {
  _minZoomScale = MAX(0, minZoomScale);
}

- (void)setMaxZoomScale:(CGFloat)maxZoomScale {
  _maxZoomScale = MAX(0, maxZoomScale);
}

@end
