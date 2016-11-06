// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorConversionProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTColorConversionProcessor)

__block LTTexture *inputTexture;
__block LTTexture *outputTexture;
__block LTColorConversionProcessor *processor;

beforeEach(^{
  inputTexture = [LTTexture textureWithImage:cv::Mat4b(1, 1)];
  outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
  processor = [[LTColorConversionProcessor alloc] initWithInput:inputTexture
                                                         output:outputTexture];
});

afterEach(^{
  processor = nil;
});

context(@"RGB to HSV", ^{
  beforeEach(^{
    processor.mode = LTColorConversionRGBToHSV;
  });

  it(@"should convert grey correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(64, 64, 64, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(0, 0, 64, 255));
    expect($([outputTexture image])).to.equalMat($(expected));
  });

  it(@"should convert red correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(255, 0, 0, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(0, 255, 255, 255));
    expect($([outputTexture image])).to.equalMat($(expected));
  });

  it(@"should convert green correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(0, 255, 0, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(85, 255, 255, 255));
    expect($([outputTexture image])).to.equalMat($(expected));
  });

  it(@"should convert blue correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(0, 0, 255, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(170, 255, 255, 255));
    expect($([outputTexture image])).to.equalMat($(expected));
  });
});

context(@"HSV to RGB", ^{
  beforeEach(^{
    processor.mode = LTColorConversionHSVToRGB;
  });

  it(@"should convert to grey correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(0, 0, 64, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(64, 64, 64, 255));
    expect($([outputTexture image])).to.equalMat($(expected));
  });

  it(@"should convert to red correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(0, 255, 255, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(255, 0, 0, 255));
    expect($([outputTexture image])).to.equalMat($(expected));
  });

  it(@"should convert to green correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(85, 255, 255, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(0, 255, 0, 255));
    expect($([outputTexture image])).to.equalMat($(expected));
  });

  it(@"should convert to blue correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(170, 255, 255, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(0, 0, 255, 255));
    expect($([outputTexture image])).to.equalMat($(expected));
  });
});

context(@"RGB to YIQ", ^{
  beforeEach(^{
    processor.mode = LTColorConversionRGBToYIQ;
  });

  it(@"should convert grey", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(64, 64, 64, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(64, 128, 128, 255));
    expect($([outputTexture image])).to.equalMat($(expected));
  });

  it(@"should convert red", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(255, 0, 0, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(76, 255, 179, 255));
    expect($([outputTexture image])).to.equalMat($(expected));
  });
});

context(@"YIQ to RGB", ^{
  beforeEach(^{
    processor.mode = LTColorConversionYIQToRGB;
  });

  it(@"should convert to grey", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(64, 128, 128, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(64, 64, 64, 255));
    expect($([outputTexture image])).to.beCloseToMat($(expected));
  });

  it(@"should convert to red", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(76, 255, 179, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(255, 0, 0, 255));
    expect($([outputTexture image])).to.equalMat($(expected));
  });
});

context(@"RGB to yyyy", ^{
  beforeEach(^{
    processor.mode = LTColorConversionRGBToYYYY;
  });

  it(@"should convert grey", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(64, 64, 64, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(64, 64, 64, 64));
    expect($([outputTexture image])).to.equalMat($(expected));
  });
});

context(@"check color space round trip conversion", ^{
  __block std::vector<cv::Vec4b> testColors;
  
  before(^{
    testColors.push_back(cv::Vec4b(0, 0, 0, 0));
    testColors.push_back(cv::Vec4b(0, 0, 0, 255));
    testColors.push_back(cv::Vec4b(255, 0, 0, 255));
    testColors.push_back(cv::Vec4b(0, 255, 0, 255));
    testColors.push_back(cv::Vec4b(0, 0, 255, 255));
    testColors.push_back(cv::Vec4b(255, 255, 255, 255));
  });
  
  it(@"should convert RGB to YIQ and back correctly", ^{
    for (cv::Vec4b initialColor : testColors) {
      [inputTexture load:cv::Mat4b(1, 1, initialColor)];
      processor.mode = LTColorConversionRGBToYIQ;
      [processor process];

      [outputTexture cloneTo:inputTexture];
      processor.mode = LTColorConversionYIQToRGB;
      [processor process];
      
      cv::Mat4b expected(1, 1, initialColor);
      expect($([outputTexture image])).to.beCloseToMat($(expected));
    }
  });
  
  it(@"should convert RGB to HSV and back correctly", ^{
    for (cv::Vec4b initialColor : testColors) {
      [inputTexture load:cv::Mat4b(1, 1, initialColor)];
      processor.mode = LTColorConversionRGBToHSV;
      [processor process];

      [outputTexture cloneTo:inputTexture];
      processor.mode = LTColorConversionHSVToRGB;
      [processor process];
      
      cv::Mat4b expected(1, 1, initialColor);
      expect($([outputTexture image])).to.equalMat($(expected));
    }
  });
});

SpecEnd
