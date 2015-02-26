// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadMixerProcessor.h"

#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTQuad.h"
#import "LTTexture+Factory.h"

/// Write plus sign with the given offset and the specified color.
static void LTPlusSignAt(cv::Mat4b image, const cv::Point &offset, const cv::Vec4b &color) {
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

LTSpecBegin(LTQuadMixerProcessor)

const cv::Vec4b backColor(cv::Vec4b(128, 64, 255, 255));
const cv::Vec4b frontColor(cv::Vec4b(64, 128, 32, 255));
const CGFloat maskColor = 0.5;

__block LTTexture *back;
__block LTTexture *front;
__block LTTexture *mask;
__block LTTexture *output;
__block LTQuadMixerProcessor *processor;

beforeEach(^{
  back = [LTTexture textureWithImage:cv::Mat4b(16, 16, backColor)];
  front = [LTTexture textureWithImage:cv::Mat4b(8, 8, frontColor)];
  mask = [LTTexture byteRedTextureWithSize:CGSizeMake(8, 8)];
  output = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];

  [mask clearWithColor:LTVector4(maskColor, maskColor, maskColor, maskColor)];

  processor = [[LTQuadMixerProcessor alloc] initWithBack:back front:front mask:mask output:output
                                                maskMode:LTMixerMaskModeFront];
  processor.frontQuad = [LTQuad quadFromRect:CGRectMake(0, 0, 8, 8)];
});

afterEach(^{
  back = nil;
  front = nil;
  mask = nil;
  output = nil;
  processor = nil;
});

context(@"initialization", ^{
  it(@"should not initialize with front and mask of different sizes if mask is applied to front", ^{
    LTTexture *mask = [LTTexture textureWithSize:CGSizeMake(16, 16)
                                       precision:LTTexturePrecisionHalfFloat
                                          format:LTTextureFormatRed allocateMemory:YES];
    expect(^{
      LTQuadMixerProcessor __unused *processor =
      [[LTQuadMixerProcessor alloc] initWithBack:back front:front mask:mask output:output
                                        maskMode:LTMixerMaskModeFront];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      LTQuadMixerProcessor __unused *processor =
      [[LTQuadMixerProcessor alloc] initWithBack:back front:front mask:mask output:output
                                    maskMode:LTMixerMaskModeFront];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with back and mask of different sizes if mask is applied to back", ^{
    LTTexture *mask = [LTTexture textureWithSize:CGSizeMake(8, 8)
                                       precision:LTTexturePrecisionHalfFloat
                                          format:LTTextureFormatRed allocateMemory:YES];
    expect(^{
      LTQuadMixerProcessor __unused *processor =
      [[LTQuadMixerProcessor alloc] initWithBack:back front:front mask:mask output:output
                                    maskMode:LTMixerMaskModeBack];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize with default values", ^{
    expect(processor.frontOpacity).to.equal(1);
  });
});

context(@"front placement", ^{
  __block LTQuad *frontQuad;

  beforeEach(^{
    frontQuad = [LTQuad quadFromRect:CGRectMake(0, 0, 8, 8)];
  });

  it(@"should blend with correct translation placement", ^{
    [frontQuad translateCorners:LTQuadCornerRegionAll byTranslation:CGPointMake(1.0, 1.0)];
    processor.frontQuad = frontQuad;
    [processor process];

    cv::Vec4b resultColor;
    cv::addWeighted(frontColor, 0.5, backColor, 0.5, 0, resultColor);
    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(1, 1, 8, 8)).setTo(resultColor);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should blend with correct scaling placement", ^{
    // Must configure translation to make sure scaling is done from the rect's center.
    [frontQuad translateCorners:LTQuadCornerRegionAll byTranslation:CGPointMake(1.0, 1.0)];
    [frontQuad scale:0.5];
    processor.frontQuad = frontQuad;
    [processor process];

    cv::Vec4b resultColor;
    cv::addWeighted(frontColor, 0.5, backColor, 0.5, 0, resultColor);
    cv::Mat4b expected(16, 16, backColor);
    expected(cv::Rect(3, 3, 4, 4)).setTo(resultColor);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should blend with correct rotation placement", ^{
    // Must configure translation to make sure scaling is done from the rect's center.
    [frontQuad translateCorners:LTQuadCornerRegionAll byTranslation:CGPointMake(4.0, 4.0)];
    [frontQuad rotateByAngle:M_PI_4 aroundPoint:frontQuad.center];
    processor.frontQuad = frontQuad;
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

    [frontQuad translateCorners:LTQuadCornerRegionAll byTranslation:CGPointMake(4.0, 4.0)];
    [frontQuad scale:1.5];
    [frontQuad rotateByAngle:M_PI_4 aroundPoint:frontQuad.center];
    processor.frontQuad = frontQuad;
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

    [frontQuad translateCorners:LTQuadCornerRegionAll byTranslation:CGPointMake(4.0, 4.0)];
    processor.frontQuad = frontQuad;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"MixerPlacementComplex.png");

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

context(@"masking", ^{
  it(@"should correctly apply the mask to the front", ^{
    [mask clearWithColor:LTVector4(1, 1, 1, 1)];
    [mask mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->at<cv::Vec4b>(0, 0) = cv::Vec4b(0, 0, 0, 0);
    }];
    [processor process];

    cv::Mat expected = cv::Mat4b(16, 16, backColor);
    for (NSInteger i = 0; i < 8; i++) {
      for (NSInteger j = 0; j < 8; j++) {
        if (i == 0 && j < 4) {
          continue;
        }
        expected.at<cv::Vec4b>((int)i, (int)j) = frontColor;
      }
    }

    expect($([output image])).to.beCloseToMat($(expected));

    processor.frontQuad = [LTQuad quadFromRect:CGRectMake(1, 1, 8, 8)];
    [processor process];

    expected = cv::Mat4b(16, 16, backColor);
    for (NSInteger i = 0; i < 8; i++) {
      for (NSInteger j = 0; j < 8; j++) {
        if (i == 0 && j < 4) {
          continue;
        }
        expected.at<cv::Vec4b>((int)i + 1, (int)j + 1) = frontColor;
      }
    }

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should correctly apply the mask to the back", ^{
    mask = [LTTexture byteRedTextureWithSize:CGSizeMake(16, 16)];
    processor = [[LTQuadMixerProcessor alloc] initWithBack:back front:front mask:mask output:output
                                                  maskMode:LTMixerMaskModeBack];
    processor.frontQuad = [LTQuad quadFromRect:CGRectMake(0, 0, 8, 8)];

    [mask clearWithColor:LTVector4(1, 1, 1, 1)];
    [mask mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->at<cv::Vec4b>(0, 0) = cv::Vec4b(0, 0, 0, 0);
    }];
    [processor process];

    cv::Mat expected = cv::Mat4b(16, 16, backColor);
    for (NSInteger i = 0; i < 8; i++) {
      for (NSInteger j = 0; j < 8; j++) {
        if (i == 0 && j < 4) {
          continue;
        }
        expected.at<cv::Vec4b>((int)i, (int)j) = frontColor;
      }
    }

    expect($([output image])).to.beCloseToMat($(expected));

    processor.frontQuad = [LTQuad quadFromRect:CGRectMake(1, 1, 8, 8)];
    [processor process];

    expected = cv::Mat4b(16, 16, backColor);
    for (NSInteger i = 0; i < 8; i++) {
      for (NSInteger j = 0; j < 8; j++) {
        expected.at<cv::Vec4b>((int)i + 1, (int)j + 1) = frontColor;
      }
    }

    expect($([output image])).to.beCloseToMat($(expected));
  });
});

LTSpecEnd
