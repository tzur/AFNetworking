// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEAWProcessor.h"

#import "LTColorConversionProcessor.h"
#import "LTOpenCVExtensions.h"
#import "LTPassthroughProcessor.h"
#import "LTTexture+Factory.h"
#import "LTImage.h"

LTTexture *LTConvertToY(LTTexture *input) {
  LTTexture *luminance = [LTTexture textureWithSize:input.size precision:LTTexturePrecisionByte
                                             format:LTTextureFormatRed allocateMemory:YES];

  LTColorConversionProcessor *conversion = [[LTColorConversionProcessor alloc]
                                            initWithInput:input output:luminance];
  conversion.mode = LTColorConversionRGBToYIQ;
  [conversion process];

  return luminance;
}

SpecBegin(LTEAWProcessor)

context(@"single channel", ^{
  __block LTEAWProcessor *processor;
  __block LTTexture *input;
  __block LTTexture *output;

  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"Flower.png")];
    output = [LTTexture textureWithSize:input.size precision:LTTexturePrecisionByte
                                 format:LTTextureFormatRed allocateMemory:YES];

    processor = [[LTEAWProcessor alloc] initWithInput:input output:output];
  });

  afterEach(^{
    input = nil;
    output = nil;
    processor = nil;
  });

  it(@"should produce output equal to input for compression factor of 1.0", ^{
    processor.compressionFactor = LTVector4(1.0);
    [processor process];

    LTTexture *luminance = LTConvertToY(input);

    expect($([output image])).to.equalMat($([luminance image]));
  });

  it(@"should produce correct output while compressing details with 0.7", ^{
    processor.compressionFactor = LTVector4(0.7);
    [processor process];

    // Image taken from Matlab reference at lightricks-research/Enlight/EAW.
    cv::Mat image = LTLoadMat([self class], @"FlowerOutput0.7.png");
    LTTexture *luminance = [LTTexture textureWithImage:image];

    expect($([output image])).to.beCloseToMatWithin($([luminance image]), 8);
  });

  it(@"should produce correct output while compressing details with 0.5", ^{
    processor.compressionFactor = LTVector4(0.5);
    [processor process];

    // Image taken from Matlab reference at lightricks-research/Enlight/EAW.
    cv::Mat image = LTLoadMat([self class], @"FlowerOutput0.5.png");
    LTTexture *luminance = [LTTexture textureWithImage:image];

    expect($([output image])).to.beCloseToMatWithin($([luminance image]), 8);
  });
});

context(@"multiple channels", ^{
  __block LTEAWProcessor *processor;
  __block LTTexture *input;
  __block LTTexture *output;

  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"Flower.png")];
    output = [LTTexture byteRGBATextureWithSize:input.size];

    processor = [[LTEAWProcessor alloc] initWithInput:input output:output];
  });

  afterEach(^{
    input = nil;
    output = nil;
    processor = nil;
  });

  it(@"should produce correct output for 4 channels", ^{
    processor.compressionFactor = LTVector4(0.5, 0.7, 1.0, 0.7);
    [processor process];

    std::vector<cv::Mat> channels;
    cv::split(output.image, channels);

    expect(channels.size()).to.equal(4);

    LTTexture *original = [LTTexture textureWithImage:LTLoadMat([self class], @"Flower.png")];
    LTTexture *luminance1 = LTConvertToY(original);

    cv::Mat image05 = LTLoadMat([self class], @"FlowerOutput0.5.png");
    cv::Mat image07 = LTLoadMat([self class], @"FlowerOutput0.7.png");

    expect($(channels[0])).to.beCloseToMatWithin($(image05), 8);
    expect($(channels[1])).to.beCloseToMatWithin($(image07), 8);
    expect($(channels[2])).to.equalMat($(luminance1.image));
    expect($(channels[3])).to.beCloseToMatWithin($(image07), 8);
  });
});

SpecEnd
