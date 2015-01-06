// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTTiltShiftProcessor.h"

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTTiltShiftProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTTiltShiftProcessor *processor;

beforeEach(^{
  input = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
  output = [LTTexture textureWithPropertiesOf:input];
  processor = [[LTTiltShiftProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return default mask properties correctly", ^{
    expect(processor.maskType).to.equal(LTDualMaskTypeRadial);
    expect(processor.center).to.equal(LTVector2(8, 8));
    expect(processor.diameter).to.equal(8);
    expect(processor.spread).to.equal(0);
    expect(processor.angle).to.equal(0);
    expect(processor.invertMask).to.beFalsy();
  });
});

context(@"properties", ^{
  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"Island.jpg")];
    output = [LTTexture byteRGBATextureWithSize:std::round(input.size * 0.1)];
    processor = [[LTTiltShiftProcessor alloc] initWithInput:input output:output];
  });
  
  sit(@"should apply radial tilt-shift pattern", ^{
    processor.center = LTVector2(output.size.width / 2, output.size.height / 2);
    processor.diameter = output.size.width / 2;
    processor.spread = -1.0;
    processor.intensity = 0.8;
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"TiltShiftRadial.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });

  sit(@"should apply inverse radial tilt-shift pattern", ^{
    processor.center = LTVector2(output.size.width / 2, output.size.height / 2);
    processor.diameter = output.size.width / 2;
    processor.spread = -1.0;
    processor.intensity = 0.8;
    processor.invertMask = YES;
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"TiltShiftRadialInverse.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  sit(@"should apply linear tilt-shift pattern", ^{
    processor.maskType = LTDualMaskTypeDoubleLinear;
    processor.center = LTVector2(output.size.width / 2, output.size.height / 2);
    processor.diameter = output.size.width / 4;
    processor.spread = -1;
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"TiltShiftDoubleLinear.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
});

LTSpecEnd
