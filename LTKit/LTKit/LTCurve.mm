// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTCurve.h"

#import "LTOpenCVExtensions.h"
#import "NSBundle+LTKitBundle.h"

#import "LTTexture+Factory.h"

@implementation LTCurve

+ (cv::Mat1b)identity {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"IdentityCurve.png");
  });
  LTAssert(curveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  return curve;
}

+ (cv::Mat1b)fillLight {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"FillLightCurve.png");
  });
  LTAssert(curveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  return curve;
}

+ (cv::Mat1b)highlights {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"HighlightsCurve.png");
  });
  LTAssert(curveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  return curve;
}

+ (cv::Mat1b)shadows {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"ShadowsCurve.png");
  });
  LTAssert(curveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  return curve;
}

+ (cv::Mat1b)positiveBrightness {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"PositiveBrightnessCurve.png");
  });
  LTAssert(curveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  return curve;
}

+ (cv::Mat1b)negativeBrightness {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"NegativeBrightnessCurve.png");
  });
  LTAssert(curveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  return curve;
}

+ (cv::Mat1b)positiveContrast {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"PositiveContrastCurve.png");
  });
  LTAssert(curveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  return curve;
}

+ (cv::Mat1b)negativeContrast {
  static dispatch_once_t onceToken;
  static cv::Mat1b curve;
  dispatch_once(&onceToken, ^{
    curve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"NegativeContrastCurve.png");
  });
  LTAssert(curveIsLoadedCorrectly(curve), @"Could not load curve correctly");
  return curve;
}

BOOL curveIsLoadedCorrectly(const cv::Mat &mat) {
  if (mat.size() == cv::Size(256, 1)) {
    return YES;
  } else {
    return NO;
  }
}

@end
