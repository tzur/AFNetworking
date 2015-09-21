// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@interface UIScreen (Physical)

/// Returns the number of points per inch of this (logical) screen, given its pixels per inch value
/// (which is a physical property of the physical screen that backs this instance). A line that has
/// the returned length measures exactly 1 inch on the physical screen.
///
/// @note Unlike physical pixels, points are defined in the logical coordinate system of this
/// instance and thus the returned value loses its meaning when the logical coordinate system
/// changes.
- (CGFloat)lt_pointsPerInchForPixelsPerInch:(CGFloat)pixelsPerInch;

@end

NS_ASSUME_NONNULL_END
