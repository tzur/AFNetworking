// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTTiltShiftProcessor.h"

#import "LTCGExtensions.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTTiltShiftProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTTiltShiftProcessor *processor;

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

beforeEach(^{
  input = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
  output = [LTTexture textureWithPropertiesOf:input];
  processor = [[LTTiltShiftProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  processor =  nil;
  input =  nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return default mask properties correctly", ^{
    expect(processor.maskType).to.equal(LTDualMaskTypeRadial);
    expect(GLKVector2AllEqualToVector2(processor.center, GLKVector2Make(0.5, 0.5))).to.beTruthy();
    expect(processor.diameter).to.equal(0.5);
    expect(processor.spread).to.equal(0);
    expect(processor.angle).to.equal(0);
  });
});

context(@"properties", ^{
  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"Island.jpg")];
    output = [LTTexture byteRGBATextureWithSize:std::round(input.size * 1.0)];
    processor = [[LTTiltShiftProcessor alloc] initWithInput:input output:output];
  });
  
  it(@"should apply blue and red colors", ^{
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"Island.jpg");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
});

SpecEnd
