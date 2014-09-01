// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMixerProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

/// Write plus sign with the given offset and the specified color.
void LTPlusSignAt(cv::Mat4b image, const cv::Point &offset, const cv::Vec4b &color) {
  for (int y = 0; y <= 4; ++y) {
    for (int x = 4 - y; x < 6 + y; ++x) {
      image(y + offset.y, x + offset.x) = color;
    }
  }
  for (int y = 5; y <= 9; ++y) {
    for (int x = y - 5; x < 15 - y; ++x) {
      image(y + offset.y, x + offset.x) = color;
    }
  }
}

LTSpecBegin(LTMixerProcessor)

const cv::Vec4b backColor(cv::Vec4b(128, 64, 255, 255));
const cv::Vec4b frontColor(cv::Vec4b(64, 128, 32, 255));
const CGFloat maskColor = 0.5;

__block LTTexture *back;
__block LTTexture *front;
__block LTTexture *mask;
__block LTTexture *output;
__block LTMixerProcessor *processor;

beforeEach(^{
  back = [LTTexture textureWithImage:cv::Mat4b(16, 16, backColor)];
  front = [LTTexture textureWithImage:cv::Mat4b(8, 8, frontColor)];
  mask = [LTTexture textureWithSize:CGSizeMake(8, 8)
                          precision:LTTexturePrecisionByte
                             format:LTTextureFormatRed allocateMemory:YES];
  output = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];

  [mask clearWithColor:LTVector4(maskColor, maskColor, maskColor, maskColor)];

  processor = [[LTMixerProcessor alloc] initWithBack:back front:front mask:mask output:output];
});

afterEach(^{
  back = nil;
  front = nil;
  mask = nil;
  output = nil;
  processor = nil;
});

context(@"initialization", ^{
  it(@"should not initialize with front and mask of different sizes", ^{
    LTTexture *mask = [LTTexture textureWithSize:CGSizeMake(16, 16)
                            precision:LTTexturePrecisionHalfFloat
                               format:LTTextureFormatRed allocateMemory:YES];
    expect(^{
      LTMixerProcessor __unused *processor =
          [[LTMixerProcessor alloc] initWithBack:back front:front mask:mask output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize with default values", ^{
    expect(processor.frontOpacity).to.equal(1);
  });
});

context(@"front placement", ^{
  it(@"should blend with correct translation placement", ^{
    processor.frontTranslation = CGPointMake(1.0, 1.0);
    [processor process];

    cv::Vec4b resultColor;
    cv::addWeighted(frontColor, 0.5, backColor, 0.5, 0, resultColor);
    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(1, 1, 8, 8)).setTo(resultColor);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should blend with correct scaling placement", ^{
    // Must configure translation to make sure scaling is done from the rect's center.
    processor.frontTranslation = CGPointMake(1.0, 1.0);
    processor.frontScaling = 0.5;
    [processor process];

    cv::Vec4b resultColor;
    cv::addWeighted(frontColor, 0.5, backColor, 0.5, 0, resultColor);
    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(3, 3, 4, 4)).setTo(resultColor);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should blend with correct rotation placement", ^{
    // Must configure translation to make sure scaling is done from the rect's center.
    processor.frontTranslation = CGPointMake(4.0, 4.0);
    processor.frontRotation = M_PI_4;
    [processor process];

    cv::Vec4b resultColor;
    cv::addWeighted(frontColor, 0.5, backColor, 0.5, 0, resultColor);
    cv::Mat4b expected(16, 16, backColor);
    LTPlusSignAt(expected, cv::Point(3, 3), resultColor);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should blend complex front with correct translation, scaling and rotation", ^{
    cv::Mat4b image(front.size.height, front.size.width, cv::Vec4b(255, 0, 0, 255));
    image(cv::Rect(0, 0, 2, 2)) = cv::Vec4b(0, 255, 0, 255);
    [front load:image];

    processor.frontTranslation = CGPointMake(4, 4);
    processor.frontScaling = 1.5;
    processor.frontRotation = M_PI_4;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"MixerPlacementRect.png");

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should blend complex front to complex back with correct translation", ^{
    cv::Mat4b frontImage(front.size.height, front.size.width, cv::Vec4b(255, 0, 0, 255));
    frontImage(cv::Rect(0, 0, 2, 2)) = cv::Vec4b(255, 255, 0, 255);
    [front load:frontImage];

    cv::Mat4b backImage(back.size.height, back.size.width, cv::Vec4b(0, 255, 0, 255));
    backImage(cv::Rect(0, 8, 8, 8)) = cv::Vec4b(0, 0, 255, 255);
    backImage(cv::Rect(8, 0, 8, 8)) = cv::Vec4b(0, 0, 255, 255);
    [back load:backImage];

    processor.frontTranslation = CGPointMake(4, 4);
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"MixerPlacementComplex.png");

    expect($([output image])).to.beCloseToMat($(expected));
  });
});

context(@"tiling", ^{
  it(@"should tile back on output", ^{
    // Front is completely disabled by the mask, only verify back tiling.
    [mask clearWithColor:LTVector4(0, 0, 0, 0)];

    // Create square pattern.
    [back mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      (*mapped)(cv::Rect(0, 0, 8, 8)) = cv::Scalar(0, 255, 0, 255);
      (*mapped)(cv::Rect(8, 8, 8, 8)) = cv::Scalar(0, 255, 0, 255);
    }];

    // Enlarge output to enable tiling.
    output = [LTTexture byteRGBATextureWithSize:CGSizeMake(32, 32)];

    processor = [[LTMixerProcessor alloc] initWithBack:back front:front mask:mask output:output];
    processor.outputFillMode = LTMixerOutputFillModeTile;
    [processor process];

    cv::Mat4b expected(32, 32);
    [back mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
      mapped.copyTo(expected(cv::Rect(0, 0, 16, 16)));
      mapped.copyTo(expected(cv::Rect(0, 16, 16, 16)));
      mapped.copyTo(expected(cv::Rect(16, 0, 16, 16)));
      mapped.copyTo(expected(cv::Rect(16, 16, 16, 16)));
    }];

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should blend tiled back image with translation, scaling and rotation", ^{
    cv::Mat4b frontImage(front.size.height, front.size.width, cv::Vec4b(255, 0, 0, 255));
    frontImage(cv::Rect(0, 0, 2, 2)) = cv::Vec4b(255, 255, 0, 255);
    [front load:frontImage];
    front.magFilterInterpolation = LTTextureInterpolationNearest;

    [back mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      (*mapped)(cv::Rect(0, 0, 8, 8)) = cv::Scalar(0, 255, 0, 255);
      (*mapped)(cv::Rect(8, 8, 8, 8)) = cv::Scalar(0, 255, 0, 255);
    }];

    output = [LTTexture byteRGBATextureWithSize:CGSizeMake(32, 32)];

    processor = [[LTMixerProcessor alloc] initWithBack:back front:front mask:mask output:output];
    processor.outputFillMode = LTMixerOutputFillModeTile;
    processor.frontTranslation = CGPointMake(6, 6);
    processor.frontRotation = M_PI_2;
    processor.frontScaling = 2.0;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"MixerTilingComplex.png");

    expect($([output image])).to.beCloseToMat($(expected));
  });
});

context(@"blending", ^{
  it(@"should mix with normal blending mode", ^{
    processor.blendMode = LTBlendModeNormal;
    [processor process];

    cv::Vec4b resultColor;
    cv::addWeighted(frontColor, 0.5, backColor, 0.5, 0, resultColor);
    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(0, 0, 8, 8)).setTo(resultColor);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should mix with darken blending mode", ^{
    processor.blendMode = LTBlendModeDarken;
    [processor process];

    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(96, 64, 143, 255));

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should mix with multiply blending mode", ^{
    processor.blendMode = LTBlendModeMultiply;
    [processor process];

    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(80, 48, 143, 255));

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should mix with hard-light blending mode", ^{
    processor.blendMode = LTBlendModeHardLight;
    [processor process];

    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(96, 64, 159, 255));
    
    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should mix with soft-light blending mode", ^{
    processor.blendMode = LTBlendModeSoftLight;
    [processor process];

    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(112, 64, 255, 255));

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should mix with lighten blending mode", ^{
    processor.blendMode = LTBlendModeLighten;
    [processor process];

    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(128, 96, 255, 255));

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should mix with screen blending mode", ^{
    processor.blendMode = LTBlendModeScreen;
    [processor process];

    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(144, 112, 255, 255));

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should mix with color burn mode", ^{
    processor.blendMode = LTBlendModeColorBurn;
    [processor process];

    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(64, 32, 255, 255));

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should mix with overlay mode", ^{
    processor.blendMode = LTBlendModeOverlay;
    [processor process];

    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(96, 64, 255, 255));

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should mix with plus lighter mode", ^{
    processor.blendMode = LTBlendModePlusLighter;
    [processor process];

    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(160, 128, 255, 255));

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should mix with plus darker mode", ^{
    processor.blendMode = LTBlendModePlusDarker;
    [processor process];

    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(0, 0, 16, 255));

    expect($([output image])).to.beCloseToMat($(expected));
  });
});

context(@"opacity", ^{
  it(@"should change opacity of front texture", ^{
    processor.frontOpacity = 0.5;
    [processor process];

    cv::Vec4b resultColor;
    cv::addWeighted(frontColor, 0.25, backColor, 0.75, 0, resultColor);
    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(0, 0, 8, 8)).setTo(resultColor);

    expect($([output image])).to.beCloseToMat($(expected));
  });
});

LTSpecEnd
