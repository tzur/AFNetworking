// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTCurve.h"

#import "LTOpenCVExtensions.h"
#import "NSBundle+LTKitBundle.h"

@implementation LTCurve

+ (cv::Mat1b)identity {
  static const cv::Mat1b curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"IdentityCurve.png");
  return curve;
}

+ (cv::Mat1b)fillLight {
  static const cv::Mat1b curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"FillLightCurve.png");
  return curve;
}

+ (cv::Mat1b)highlights {
  static const cv::Mat1b curve =
      LTLoadMatFromBundle([NSBundle LTKitBundle], @"HighlightsCurve.png");
  return curve;
}

+ (cv::Mat1b)shadows {
  static const cv::Mat1b curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"ShadowsCurve.png");
  return curve;
}

+ (cv::Mat1b)positiveBrightness {
  static const cv::Mat1b curve =
      LTLoadMatFromBundle([NSBundle LTKitBundle], @"PositiveBrightnessCurve.png");
  return curve;
}

+ (cv::Mat1b)negativeBrightness {
  static const cv::Mat1b curve =
      LTLoadMatFromBundle([NSBundle LTKitBundle], @"NegativeBrightnessCurve.png");
  return curve;
}

+ (cv::Mat1b)positiveContrast {
  static const cv::Mat1b curve =
      LTLoadMatFromBundle([NSBundle LTKitBundle], @"PositiveContrastCurve.png");
  return curve;
}

+ (cv::Mat1b)negativeContrast {
  static const cv::Mat1b curve =
      LTLoadMatFromBundle([NSBundle LTKitBundle], @"NegativeContrastCurve.png");
  return curve;
}

@end
