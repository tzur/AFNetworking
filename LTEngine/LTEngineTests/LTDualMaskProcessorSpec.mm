// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTDualMaskProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTDualMaskProcessor)

__block LTTexture *output;
__block LTDualMaskProcessor *processor;

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
    expect(processor.center).to.equal(LTVector2::zeros());
    expect(processor.diameter).to.equal(0);
    expect(processor.spread).to.equal(0);
    expect(processor.angle).to.equal(0);
    expect(processor.invert).to.beFalsy();
  });
});

context(@"processing", ^{
  it(@"should create radial mask correctly", ^{
    processor.maskType = LTDualMaskTypeRadial;
    processor.center = LTVector2(8, 8);
    processor.diameter = 8;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"RadialMaskCenter.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });

  it(@"should invert mask correctly", ^{
    processor.maskType = LTDualMaskTypeRadial;
    processor.center = LTVector2(8, 8);
    processor.diameter = 8;
    processor.invert = YES;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"RadialMaskCenterInverted.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  it(@"should create corner radial mask correctly", ^{
    processor.maskType = LTDualMaskTypeRadial;
    processor.center = LTVector2(0.0, 0.0);
    processor.spread = -1.0;
    processor.diameter = 16;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"RadialMaskOffCenter.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  it(@"should create tilted linear mask correctly", ^{
    processor.maskType = LTDualMaskTypeLinear;
    processor.center = LTVector2(8, 8);
    processor.spread = 0.2;
    processor.angle = M_PI_4;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"LinearMaskTiltedCenter.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  it(@"should create tilted double mask correctly", ^{
    processor.maskType = LTDualMaskTypeDoubleLinear;
    processor.center = LTVector2(8, 8);
    processor.spread = 0.0;
    processor.diameter = 8;
    processor.angle = -M_PI_4;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"DoubleLinearMaskTiltedCenter.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  it(@"should create tilted double mask correctly", ^{
    processor.maskType = LTDualMaskTypeDoubleLinear;
    processor.center = LTVector2(0.0, 8);
    processor.spread = 0.0;
    processor.diameter = 8;
    processor.angle = M_PI_4;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"DoubleLinearMaskTiltedOffCenter.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });

  it(@"should create constant mask correctly", ^{
    processor.maskType = LTDualMaskTypeConstant;
    [processor process];
    cv::Mat4b image(16, 16, cv::Vec4b(255, 255, 255, 255));
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  it(@"should create default radial mask correctly on non-square image", ^{
    output = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 32)];
    processor = [[LTDualMaskProcessor alloc] initWithOutput:output];
    processor.center = LTVector2(8, 16);
    processor.diameter = 8;
    processor.maskType = LTDualMaskTypeRadial;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"RadialMaskCenterNonSquare.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
});

SpecEnd
