// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

NS_ASSUME_NONNULL_BEGIN

@class LTFbo, LTRotatedRect;

/// A class for drawing rects with solid color on an input texture. Note the drawing is aliased.
/// This means that drawn rotated rects will have jagged edges and regular rects will be rounded
/// into a rect that lies inside the input rect.
@interface LTSolidRectsDrawer : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c fillColor to use for filling the rectangles. \c fillColor cannot be \c
/// LTVector4::null().
- (instancetype)initWithFillColor:(LTVector4)fillColor NS_DESIGNATED_INITIALIZER;

/// Fills the given rotated \c rects (in pixels) in a given frame buffer, using the \c fillColor.
- (void)drawRotatedRects:(NSArray<LTRotatedRect *> *)rects inFramebuffer:(LTFbo *)fbo;

/// Filling color to use when drawing the rectangles.
@property (readonly, nonatomic) LTVector4 fillColor;

@end

NS_ASSUME_NONNULL_END
