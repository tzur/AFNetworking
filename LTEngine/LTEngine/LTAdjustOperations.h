// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

NS_ASSUME_NONNULL_BEGIN

/// Returns a <tt>4x4</tt> matrix that encapsulates the following tonal adjustments: Hue, saturation,
/// temperature and tint.
/// Using the formalism of the affine transformations, conversion to and from YIQ color space is
/// a rotation. Saturation is a scaling of y and z axis. Temperature and tint are offsets of these
/// two axes. Hue is a rotation around x axis along the y and z axis.
GLKMatrix4 LTTonalTransformMatrix(CGFloat temperature, CGFloat tint, CGFloat saturation,
                                  CGFloat hue);

/// Returns a <tt>1x256</tt> matrix representing a curve adjusting brightness, contrast, exposure
/// as base and exponent, and offset. Since these manipulations do not differ across RGB channels,
/// they only require luminance update.
cv::Mat1b LTLuminanceCurve(CGFloat brightness, CGFloat contrast, CGFloat exposureBase,
                           CGFloat exposureExponent, CGFloat offset);

NS_ASSUME_NONNULL_END
