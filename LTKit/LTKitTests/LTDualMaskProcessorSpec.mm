// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTDualMaskProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTDualMaskProcessor)

__block LTTexture *output;
__block LTDualMaskProcessor *processor;

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

beforeEach(^{
  output = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
  processor = [[LTDualMaskProcessor alloc] initWithOutput:output];
});

afterEach(^{
  processor =  nil;
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

context(@"processing", ^{
  it(@"should create default radial mask correctly", ^{
    processor.maskType = LTDualMaskTypeRadial;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"RadialMaskCenter.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  it(@"should create corner radial mask correctly", ^{
    processor.maskType = LTDualMaskTypeRadial;
    processor.center = GLKVector2Make(0.0, 0.0);
    processor.spread = 1.0;
    processor.diameter = 1.0;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"RadialMaskOffCenter.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  it(@"should create tilted linear mask correctly", ^{
    processor.maskType = LTDualMaskTypeLinear;
    processor.center = GLKVector2Make(0.5, 0.5);
    processor.spread = -0.2;
    processor.angle = M_PI_4;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"LinearMaskTiltedCenter.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  it(@"should create tilted double mask correctly", ^{
    processor.maskType = LTDualMaskTypeDoubleLinear;
    processor.center = GLKVector2Make(0.5, 0.5);
    processor.spread = 0.0;
    processor.diameter = 0.5;
    processor.angle = -M_PI_4;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"DoubleLinearMaskTiltedCenter.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  it(@"should create tilted double mask correctly", ^{
    processor.maskType = LTDualMaskTypeDoubleLinear;
    processor.center = GLKVector2Make(0.0, 0.5);
    processor.spread = 0.0;
    processor.diameter = 0.5;
    processor.angle = M_PI_4;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"DoubleLinearMaskTiltedOffCenter.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
});

SpecEnd
