// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBicubicResizeProcessor.h"

#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTBicubicResizeProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTBicubicResizeProcessor *processor;

beforeEach(^{
  input = [LTTexture textureWithImage:LTCreateDeltaMat(CGSizeMakeUniform(8))];
  output = [LTTexture byteRGBATextureWithSize:input.size * 2.0];
  
  processor = [[LTBicubicResizeProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  input = nil;
  output = nil;
  processor = nil;
});


context(@"initialization", ^{
  it(@"should initialize with single input and output", ^{
    expect(^{
      processor = [[LTBicubicResizeProcessor alloc] initWithInput:input output:output];
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  it(@"should process input image correctly", ^{
    [processor process];
    
    // Result of filtering 8x8 delta function.
    cv::Mat processedDelta = LTLoadMat([self class], @"DeltaBicubic.png");
    expect(LTFuzzyCompareMat(processedDelta, [output image], 2)).to.beTruthy();
  });
});

SpecEnd
