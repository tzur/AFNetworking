// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTCurve.h"

#import "LTOpenCVExtensions.h"
#import "NSBundle+LTKitBundle.h"

@implementation LTCurve

+ (cv::Mat1b)identity {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"IdentityCurve.png");
    LTAssert(LTCurveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  });
  return curve;
}

+ (cv::Mat1b)fillLight {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"FillLightCurve.png");
    LTAssert(LTCurveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  });
  return curve;
}

+ (cv::Mat1b)positiveHighlights {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"PositiveHighlightsCurve.png");
    LTAssert(LTCurveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  });
  return curve;
}

+ (cv::Mat1b)negativeHighlights {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"NegativeHighlightsCurve.png");
    LTAssert(LTCurveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  });
  return curve;
}

+ (cv::Mat1b)positiveShadows {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"PositiveShadowsCurve.png");
    LTAssert(LTCurveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  });
  return curve;
}

+ (cv::Mat1b)negativeShadows {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"NegativeShadowsCurve.png");
    LTAssert(LTCurveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  });
  return curve;
}

+ (cv::Mat1b)positiveBrightness {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"PositiveBrightnessCurve.png");
    LTAssert(LTCurveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  });
  return curve;
}

+ (cv::Mat1b)negativeBrightness {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"NegativeBrightnessCurve.png");
    LTAssert(LTCurveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  });
  return curve;
}

+ (cv::Mat1b)positiveContrast {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"PositiveContrastCurve.png");
    LTAssert(LTCurveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  });
  return curve;
}

+ (cv::Mat1b)negativeContrast {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"NegativeContrastCurve.png");
    LTAssert(LTCurveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  });
  return curve;
}

static BOOL LTCurveIsLoadedCorrectly(const cv::Mat &mat) {
  if (mat.size() == cv::Size(256, 1)) {
    return YES;
  } else {
    return NO;
  }
}

@end
