// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchCompositorProcessor.h"

#import "LTRotatedRect.h"
#import "LTTexture+Factory.h"

SpecGLBegin(LTPatchCompositorProcessor)

context(@"initialization", ^{
  __block LTTexture *source;
  __block LTTexture *target;
  __block LTTexture *membrane;
  __block LTTexture *mask;
  __block LTTexture *output;

  beforeEach(^{
    source = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 4)];
    target = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 4)];
    membrane = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 4)];
    mask = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 4)];
    output = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 4)];
  });

  it(@"should initialize with correcly sized textures", ^{
    expect(^{
      __unused LTPatchCompositorProcessor *processor = [[LTPatchCompositorProcessor alloc]
                                                        initWithSource:source target:target
                                                        membrane:membrane mask:mask output:output];
    }).toNot.raiseAny();
  });

  it(@"should raise if output has different size than target", ^{
    LTTexture *output = [LTTexture byteRGBATextureWithSize:CGSizeMake(8, 8)];

    expect(^{
      __unused LTPatchCompositorProcessor *processor = [[LTPatchCompositorProcessor alloc]
                                                        initWithSource:source target:target
                                                        membrane:membrane mask:mask output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should have default values after initialization", ^{
    LTPatchCompositorProcessor *processor = [[LTPatchCompositorProcessor alloc]
                                             initWithSource:source target:target
                                             membrane:membrane mask:mask output:output];

    LTRotatedRect *expectedSourceRect = [LTRotatedRect rect:CGRectMake(0, 0, source.size.width,
                                                                       source.size.height)];
    LTRotatedRect *expectedTargetRect = [LTRotatedRect rect:CGRectMake(0, 0, target.size.width,
                                                                       target.size.height)];

    expect(processor.sourceRect).to.equal(expectedSourceRect);
    expect(processor.targetRect).to.equal(expectedTargetRect);
  });
});

it(@"should composite correctly", ^{
  // Since this is a bit complex, here's a scenario description:
  // - Source is a 32x32 texture, with four quads with different colors at (0, 0, 16, 16).
  // - Target is a 32x32 constant blue image.
  // - Membrane is an 8x8 image with 0.5 green value.
  // - Mask is 16x16 texture, which is 1 only in the 8x8 top upper left rect.
  // - Opacity is set to 0.5, which is later multiplied with the mask.
  //
  // When compositing, only the 16x16 top left corner of source is used, and it is copied to the
  // entire target rect. The mask (after resizing to target rect coordinates) specifies only the top
  // left 16x16 rect as one that should be written as source + membrane, while the rest is written
  // as target.

  cv::Mat4b sourceImage(cv::Mat4b::zeros(32, 32));
  sourceImage(cv::Rect(0, 0, 8, 8)) = cv::Vec4b(255, 0, 0, 255);
  sourceImage(cv::Rect(8, 0, 8, 8)) = cv::Vec4b(0, 255, 0, 255);
  sourceImage(cv::Rect(0, 8, 8, 8)) = cv::Vec4b(0, 0, 255, 255);
  sourceImage(cv::Rect(8, 8, 8, 8)) = cv::Vec4b(255, 255, 0, 255);
  LTTexture *source = [LTTexture textureWithImage:sourceImage];
  source.magFilterInterpolation = LTTextureInterpolationNearest;

  cv::Mat4b targetImage(32, 32, cv::Vec4b(0, 0, 255, 255));
  LTTexture *target = [LTTexture textureWithImage:targetImage];

  cv::Mat4f membraneImage(8, 8, cv::Vec4f(0, 0.5, 0, 0));
  LTTexture *membrane = [LTTexture textureWithImage:membraneImage];

  cv::Mat1b maskImage(cv::Mat1b::zeros(16, 16));
  maskImage(cv::Rect(0, 0, 8, 8)) = 255;
  LTTexture *mask = [LTTexture textureWithImage:maskImage];
  mask.magFilterInterpolation = LTTextureInterpolationNearest;

  LTTexture *output = [LTTexture textureWithPropertiesOf:target];

  LTPatchCompositorProcessor *processor = [[LTPatchCompositorProcessor alloc]
                                           initWithSource:source target:target
                                           membrane:membrane mask:mask output:output];
  processor.sourceRect = [LTRotatedRect rect:CGRectMake(0, 0, 16, 16)];
  processor.targetRect = [LTRotatedRect rect:CGRectMake(0, 0, 32, 32)];
  processor.sourceOpacity = 0.5;
  [processor process];

  // Set initially to target.
  cv::Mat4b expected(targetImage);
  // Source + membrane.
  expected(cv::Rect(0, 0, 16, 16)) = cv::Vec4b(128, 64, 128, 255);

  expect($([output image])).to.beCloseToMat($(expected));
});

SpecGLEnd
