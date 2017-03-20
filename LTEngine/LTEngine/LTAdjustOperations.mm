/// Copyright (c) 2016 Lightricks. All rights reserved.
/// Created by Shachar Langbeheim.

#import "LTAdjustOperations.h"

#import "LTCurve.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"

NS_ASSUME_NONNULL_BEGIN

/// Size of the luminance LUT.
static const ushort kLutSize = 256;

/// Ratio by which saturation is scaled. See the documentation of \c remappedSaturation.
static const CGFloat kSaturationScaling = 1.5;

/// Ratio by which temperature is scaled. See the documentation of \c remappedTemperature.
static const CGFloat kTemperatureScaling = 0.3;

/// Ratio by which tint is scaled. See the documentation of \c remappedTint.
static const CGFloat kTintScaling = 0.3;

/// Conversion matrix from RGB to YIQ.
static const GLKMatrix4 kRGBtoYIQ = GLKMatrix4Make(0.299, 0.596, 0.212, 0,
                                                   0.587, -0.274, -0.523, 0,
                                                   0.114, -0.322, 0.311, 0,
                                                   0, 0, 0, 1);
/// Conversion matrix from YIQ to RGB.
static const GLKMatrix4 kYIQtoRGB = GLKMatrix4Make(1, 1, 1, 0,
                                                   0.9563, -0.2721, -1.107, 0,
                                                   0.621, -0.6474, 1.7046, 0,
                                                   0, 0, 0, 1);

/// Linearly maps <tt>[-1, 0]</tt> to <tt>[0, 1]</tt> and <tt>(0, 1]</tt> to
/// <tt>(1, 1 + kSaturationScaling]</tt>.
static inline CGFloat LTRemappedSaturation(CGFloat saturation) {
  return saturation < 0 ? saturation + 1 : 1 + saturation * kSaturationScaling;
}

/// Linearly maps <tt>[-1, 1]</tt> to <tt>[-kTintScaling, kTintScaling]</tt>.
/// Tint is an additive scale of the Q channel in YIQ, so theoretically  max value is \c 0.523
/// (red-blue) and min value is \c -0.523 (pure green).
/// Min/max can be easily deduced from the RGB -> YIQ conversion matrix, while taking into account
/// that RGB values are always positive.
static inline CGFloat LTRemappedTint(CGFloat tint) {
  return tint * kTintScaling;
}

/// Linearly maps <tt>[-1, 1]</tt>  to <tt>[-kTemperatureScaling, kTemperatureScaling]</tt>.
/// Temperature is an additive scale of the I channel in YIQ, so theoretically max value is \c 0.596
/// (pure red) and min value is \c -0.596 (green-blue color).
/// Min/max can be easily deduced from the RGB -> YIQ conversion matrix, while taking into account
/// that RGB values are always positive.
static inline CGFloat LTRemappedTemperature(CGFloat temperature) {
  return temperature * kTemperatureScaling;
}

GLKMatrix4 LTTonalTransformMatrix(CGFloat temperature, CGFloat tint, CGFloat saturation,
                                  CGFloat hue) {
  GLKMatrix4 temperatureAndTint = GLKMatrix4Identity;
  temperatureAndTint.m31 = LTRemappedTemperature(temperature);
  temperatureAndTint.m32 = LTRemappedTint(tint);

  GLKMatrix4 saturationMatrix = GLKMatrix4Identity;
  saturation = LTRemappedSaturation(saturation);
  saturationMatrix.m11 = saturation;
  saturationMatrix.m22 = saturation;

  GLKMatrix4 hueMatrix = GLKMatrix4MakeXRotation(hue * M_PI);

  GLKMatrix4 tonalTranform = GLKMatrix4Multiply(hueMatrix, kRGBtoYIQ);
  tonalTranform = GLKMatrix4Multiply(temperatureAndTint, tonalTranform);
  tonalTranform = GLKMatrix4Multiply(saturationMatrix, tonalTranform);
  tonalTranform = GLKMatrix4Multiply(kYIQtoRGB, tonalTranform);

  return tonalTranform;
}

cv::Mat1b LTLuminanceCurve(CGFloat brightness, CGFloat contrast, CGFloat exposureBase,
                           CGFloat exposureExponent, CGFloat offset) {
  cv::Mat1b brightnessCurve(1, kLutSize);
  brightnessCurve = brightness >= 0 ? [LTCurve positiveBrightness] : [LTCurve negativeBrightness];

  cv::Mat1b contrastCurve(1, kLutSize);
  contrastCurve = contrast >= 0 ? [LTCurve positiveContrast] : [LTCurve negativeContrast];

  CGFloat absBrightness = std::abs(brightness);
  CGFloat absContrast = std::abs(contrast);

  cv::Mat1b toneCurve(1, kLutSize);
  cv::LUT((1.0 - absContrast) * [LTCurve identity] + absContrast * contrastCurve,
          (1.0 - absBrightness) * [LTCurve identity] + absBrightness * brightnessCurve,
          toneCurve);

  return toneCurve * std::pow(exposureBase, exposureExponent) + offset * 255;
}

NS_ASSUME_NONNULL_END
