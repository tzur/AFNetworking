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
    expect(GLKVector2AllEqualToVector2(processor.center, GLKVector2Make(8, 8))).to.beTruthy();
    expect(processor.diameter).to.equal(8);
    expect(processor.spread).to.equal(0);
    expect(processor.angle).to.equal(0);
  });
});

context(@"properties", ^{
  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"Island.jpg")];
    output = [LTTexture byteRGBATextureWithSize:std::round(input.size * 0.1)];
    processor = [[LTTiltShiftProcessor alloc] initWithInput:input output:output];
  });
  
  sit(@"should apply radial tilt-shift pattern", ^{
    processor.center = GLKVector2Make(output.size.width / 2, output.size.height / 2);
    processor.diameter = output.size.width / 2;
    processor.spread = 1.0;
    processor.intensity = 0.8;
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"TiltShiftRadial.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  sit(@"should apply linear tilt-shift pattern", ^{
    processor.maskType = LTDualMaskTypeDoubleLinear;
    processor.center = GLKVector2Make(output.size.width / 2, output.size.height / 2);
    processor.diameter = output.size.width / 4;
    processor.spread = 1;
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"TiltShiftDoubleLinear.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
});

SpecEnd
