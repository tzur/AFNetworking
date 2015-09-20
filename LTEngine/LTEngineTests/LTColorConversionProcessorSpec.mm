// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorConversionProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTColorConversionProcessor)

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

context(@"rgb to hsv", ^{
  beforeEach(^{
    processor.mode = LTColorConversionRGBToHSV;
  });

  it(@"should convert grey correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(64, 64, 64, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(0, 0, 64, 255));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });

  it(@"should convert red correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(255, 0, 0, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(0, 255, 255, 255));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });

  it(@"should convert green correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(0, 255, 0, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(85, 255, 255, 255));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });

  it(@"should convert blue correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(0, 0, 255, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(170, 255, 255, 255));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });
});

context(@"hsv to rgb", ^{
  beforeEach(^{
    processor.mode = LTColorConversionHSVToRGB;
  });

  it(@"should convert to grey correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(0, 0, 64, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(64, 64, 64, 255));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });

  it(@"should convert to red correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(0, 255, 255, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(255, 0, 0, 255));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });

  it(@"should convert to green correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(85, 255, 255, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(0, 255, 0, 255));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });

  it(@"should convert to blue correctly", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(170, 255, 255, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(0, 0, 255, 255));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });
});

context(@"rgb to yiq", ^{
  beforeEach(^{
    processor.mode = LTColorConversionRGBToYIQ;
  });

  it(@"should convert grey", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(64, 64, 64, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(66, 0, 0, 255));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });

  it(@"should convert red", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(255, 0, 0, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(76, 152, 54, 255));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });
});

context(@"yiq to rgb", ^{
  beforeEach(^{
    processor.mode = LTColorConversionYIQToRGB;
  });

  it(@"should convert to grey", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(64, 0, 0, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(64, 64, 64, 255));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });

  it(@"should convert to red", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(76, 152, 54, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(255, 0, 0, 255));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });
});

context(@"rgb to yyyy", ^{
  beforeEach(^{
    processor.mode = LTColorConversionRGBToYYYY;
  });

  it(@"should convert grey", ^{
    [inputTexture load:cv::Mat4b(1, 1, cv::Vec4b(64, 64, 64, 255))];
    [processor process];

    cv::Mat4b expected(1, 1, cv::Vec4b(66, 66, 66, 66));
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });
});

LTSpecEnd
