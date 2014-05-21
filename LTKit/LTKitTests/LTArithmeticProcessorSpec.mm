// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTArithmeticProcessor.h"

#import "LTTexture+Factory.h"

SpecGLBegin(LTArithmeticProcessor)

__block LTTexture *first;
__block LTTexture *second;
__block LTTexture *output;

beforeEach(^{
  cv::Mat4b firstImage(16, 16, cv::Vec4b(128, 128, 128, 255));
  cv::Mat4b secondImage(16, 16, cv::Vec4b(64, 64, 64, 255));

  first = [LTTexture textureWithImage:firstImage];
  second = [LTTexture textureWithImage:secondImage];
  output = [LTTexture textureWithPropertiesOf:first];
});

afterEach(^{
  first = nil;
  second = nil;
  output = nil;
});

context(@"initialization", ^{
  it(@"should not initialize with differently sized operators", ^{
    cv::Mat4b firstImage(16, 16);
    cv::Mat4b secondImage(15, 15);

    LTTexture *first = [LTTexture textureWithImage:firstImage];
    LTTexture *second = [LTTexture textureWithImage:secondImage];

    expect(^{
      __unused LTArithmeticProcessor *processor =
          [[LTArithmeticProcessor alloc] initWithFirstOperand:first
                                                secondOperand:second
                                                       output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize with correctly sized operators", ^{
    expect(^{
      __unused LTArithmeticProcessor *processor =
      [[LTArithmeticProcessor alloc] initWithFirstOperand:first
                                            secondOperand:second
                                                   output:output];
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  it(@"should add two textures", ^{
    LTArithmeticProcessor *processor = [[LTArithmeticProcessor alloc] initWithFirstOperand:first
                                                                             secondOperand:second
                                                                                    output:output];
    processor.operation = LTArithmeticOperationAdd;
    [processor process];

    expect($([output image])).to.beCloseToScalar($(cv::Scalar(192, 192, 192, 255)));
  });

  it(@"should subtract two textures", ^{
    LTArithmeticProcessor *processor = [[LTArithmeticProcessor alloc] initWithFirstOperand:first
                                                                             secondOperand:second
                                                                                    output:output];
    processor.operation = LTArithmeticOperationSubtract;
    [processor process];

    expect($([output image])).to.beCloseToScalar($(cv::Scalar(64, 64, 64, 255)));
  });

  it(@"should multiply two textures", ^{
    LTArithmeticProcessor *processor = [[LTArithmeticProcessor alloc] initWithFirstOperand:first
                                                                             secondOperand:second
                                                                                    output:output];
    processor.operation = LTArithmeticOperationMultiply;
    [processor process];

    // Value should be (128 * 64) / 255, since multiplication is done in [0, 1].
    expect($([output image])).to.beCloseToScalar($(cv::Scalar(32, 32, 32, 255)));
  });

  it(@"should divide two textures", ^{
    LTArithmeticProcessor *processor = [[LTArithmeticProcessor alloc] initWithFirstOperand:second
                                                                             secondOperand:first
                                                                                    output:output];
    processor.operation = LTArithmeticOperationDivide;
    [processor process];
    
    expect($([output image])).to.beCloseToScalar($(cv::Scalar(128, 128, 128, 255)));
  });
});

SpecGLEnd
