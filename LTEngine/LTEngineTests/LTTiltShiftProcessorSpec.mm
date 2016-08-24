// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTTiltShiftProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTTiltShiftProcessor)

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
    expect(processor.center).to.equal(LTVector2::zeros());
    expect(processor.diameter).to.equal(0);
    expect(processor.spread).to.equal(0);
    expect(processor.angle).to.equal(0);
    expect(processor.invertMask).to.beFalsy();
    expect(processor.inputTexture).to.equal(input);
    expect(processor.outputTexture).to.equal(output);
    expect(processor.inputSize).to.equal(input.size);
    expect(processor.outputSize).to.equal(output.size);
  });
});

context(@"small inputs", ^{
  it(@"should initialize and process 1x1 image", ^{
    expect(^{
      input = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];
      output = [LTTexture textureWithPropertiesOf:input];
      processor = [[LTTiltShiftProcessor alloc] initWithInput:input output:output];
      [processor process];
    }).toNot.raiseAny();
  });

  it(@"should initialize and process 4x3 image", ^{
    expect(^{
      input = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 3)];
      output = [LTTexture textureWithPropertiesOf:input];
      processor = [[LTTiltShiftProcessor alloc] initWithInput:input output:output];
      [processor process];
    }).toNot.raiseAny();
  });
});

context(@"rendering", ^{
  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"Island.png")];
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
    processor.center = LTVector2(8, 8);
    processor.diameter = 8;
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

SpecEnd
