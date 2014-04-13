// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

/// This class is a containter for various tonal curves.
@interface LTCurve : NSObject

+ (cv::Mat1b)identity;
+ (cv::Mat1b)highlights;
+ (cv::Mat1b)fillLight;
+ (cv::Mat1b)shadows;
+ (cv::Mat1b)positiveBrightness;
+ (cv::Mat1b)negativeBrightness;
+ (cv::Mat1b)positiveContrast;
+ (cv::Mat1b)negativeContrast;

@end
