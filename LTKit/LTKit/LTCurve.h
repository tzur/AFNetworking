// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

/// This class is a containter for various tonal curves.
@interface LTCurve : NSObject

/// Identity curve (0-255).
+ (cv::Mat1b)identity;
/// Curve that expands the highlights of the image.
+ (cv::Mat1b)positiveHighlights;
/// Curve that compresses the highlights of the image.
+ (cv::Mat1b)negativeHighlights;
/// Curve that brightens from darks to midrange.
+ (cv::Mat1b)fillLight;
/// Curve that brightens the shadows.
+ (cv::Mat1b)positiveShadows;
/// Curve that darkens the shadows.
+ (cv::Mat1b)negativeShadows;
/// Curve that brightens the entire range.
+ (cv::Mat1b)positiveBrightness;
/// Curve that darkens the entire range.
+ (cv::Mat1b)negativeBrightness;
/// S-like curve to increase global contrast.
+ (cv::Mat1b)positiveContrast;
/// Curve that decreases global contrast.
+ (cv::Mat1b)negativeContrast;

@end
