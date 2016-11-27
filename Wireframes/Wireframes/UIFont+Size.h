// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nofar Noy.

NS_ASSUME_NONNULL_BEGIN

/// Dictionary that holds control points of font sizes. Keys define the available height, and values
/// define the desired font size.
typedef NSDictionary<NSNumber *, NSNumber *> WFHeightToFontSizeDictionary;

/// Category for responsive font size calculation.
@interface UIFont (Size)

/// Returns a font size for the given \c height, which is usually the height of a containing view,
/// or component that displays the font. The font size is calculated by linear interpolation of the
/// given \c controlPoints, and is rounded to integral values. In addition, the returned size is
/// clamped to the range defined by the smallest and the highest control point. If only a single
/// control point is given, the returned font size is equals to the size defined by it (up to
/// rounding to integral value).
///
/// Raises \c NSInvalidArgumentException if there are no control points.
+ (CGFloat)wf_fontSizeForAvailableHeight:(CGFloat)height
                       withControlPoints:(WFHeightToFontSizeDictionary *)controlPoints;
@end

NS_ASSUME_NONNULL_END
