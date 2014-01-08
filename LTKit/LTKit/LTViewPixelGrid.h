// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// The \c LTViewPixelGrid class is used for drawing the pixel grid on an LTView.
@interface LTViewPixelGrid : NSObject

/// Creates an \c LTViewPixelGrid for the given content size (in pixels).
- (instancetype)initWithContentSize:(CGSize)size;

/// Draws the grid for the given content region to the currently bound screen framebuffer, whose
/// size is given in pixels.
- (void)drawContentRegion:(CGRect)region toFramebufferWithSize:(CGSize)size;

/// Color of the pixel grid (alpha is set according to the zoom scale level).
/// Default is 0.2 gray, and setting this value to nil will restore the default color.
@property (strong, nonatomic) UIColor *color;

/// Alpha level of the pixel grid at the maximal zoom scale level, clamped to [0,1].
@property (nonatomic) CGFloat maxOpacity;

/// The minimal zoom scale that will start showing the pixel grid. On this level the grid
/// will be quite transpernt, with the transparency decreasing as the zoom increases.
@property (nonatomic) CGFloat minZoomScale;

/// The maximal zoom scale. On this level and above, the grid will be fully opaque.
@property (nonatomic) CGFloat maxZoomScale;

@end
