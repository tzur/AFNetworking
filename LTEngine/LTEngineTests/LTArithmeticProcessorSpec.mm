// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTArithmeticProcessor.h"

#import "LTTexture+Factory.h"

SpecBegin(LTArithmeticProcessor)

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

  it(@"should initialize with the first operand as the output operand (in-place)", ^{
    expect(^{
      __unused LTArithmeticProcessor *processor =
          [[LTArithmeticProcessor alloc] initWithFirstOperand:first
                                                secondOperand:second
                                                       output:first];
    }).toNot.raiseAny();
  });

  it(@"should initialize with the second operand as the output operand (in-place)", ^{
    expect(^{
      __unused LTArithmeticProcessor *processor =
          [[LTArithmeticProcessor alloc] initWithFirstOperand:first
                                                secondOperand:second
                                                       output:second];
    }).toNot.raiseAny();
  });

  it(@"should initialize with same texture as first, second and output operands (in-place)", ^{
    expect(^{
      __unused LTArithmeticProcessor *processor =
          [[LTArithmeticProcessor alloc] initWithFirstOperand:first
                                                secondOperand:first
                                                       output:first];
    }).toNot.raiseAny();
  });
});

static NSString * const kArithmeticProcessorSharedExamples = @"ArithmeticProcessor Shared Examples";
static NSString * const kArithmeticProcessorFirstInputKey = @"first";
static NSString * const kArithmeticProcessorSecondInputKey = @"second";
static NSString * const kArithmeticProcessorOutputKey = @"output";
static NSString * const kArithmeticProcessorAddResultValueKey = @"addResultValue";
static NSString * const kArithmeticProcessorSubResultValueKey = @"subResultValue";
static NSString * const kArithmeticProcessorMulResultValueKey = @"mulResultValue";
static NSString * const kArithmeticProcessorDivResultValueKey = @"divResultValue";

sharedExamplesFor(kArithmeticProcessorSharedExamples, ^(NSDictionary *data) {
  __block LTTexture *firstIn;
  __block LTTexture *secondIn;
  __block LTTexture *outputTex;

  beforeEach(^{
    cv::Mat4b firstImage(16, 16, cv::Vec4b(128, 128, 128, 255));
    cv::Mat4b secondImage(16, 16, cv::Vec4b(64, 64, 64, 255));
    NSMutableArray<LTTexture *> *textureArray = [[NSMutableArray alloc] initWithCapacity:3];
    [textureArray addObject:[LTTexture textureWithImage:firstImage]];
    [textureArray addObject:[LTTexture textureWithImage:secondImage]];
    [textureArray addObject:[LTTexture textureWithPropertiesOf:first]];
    firstIn = textureArray[[data[kArithmeticProcessorFirstInputKey] unsignedIntegerValue]];
    secondIn = textureArray[[data[kArithmeticProcessorSecondInputKey] unsignedIntegerValue]];
    outputTex = textureArray[[data[kArithmeticProcessorOutputKey] unsignedIntegerValue]];
  });

  afterEach(^{
    firstIn = nil;
    secondIn = nil;
    outputTex = nil;
  });

  it(@"should add two textures", ^{
    LTArithmeticProcessor *processor =
    [[LTArithmeticProcessor alloc] initWithFirstOperand:firstIn
                                          secondOperand:secondIn
                                                 output:outputTex];
    processor.operation = LTArithmeticOperationAdd;
    [processor process];

    cv::Scalar resultValue = [data[kArithmeticProcessorAddResultValueKey] scalarValue];
    expect($([outputTex image])).to.beCloseToScalar($(resultValue));
  });

  it(@"should subtract two textures", ^{
    LTArithmeticProcessor *processor =
    [[LTArithmeticProcessor alloc] initWithFirstOperand:firstIn
                                          secondOperand:secondIn
                                                 output:outputTex];
    processor.operation = LTArithmeticOperationSubtract;
    [processor process];

    cv::Scalar resultValue = [data[kArithmeticProcessorSubResultValueKey] scalarValue];
    expect($([outputTex image])).to.beCloseToScalar($(resultValue));
  });

  it(@"should multiply two textures", ^{
    LTArithmeticProcessor *processor =
    [[LTArithmeticProcessor alloc] initWithFirstOperand:firstIn
                                          secondOperand:secondIn
                                                 output:outputTex];
    processor.operation = LTArithmeticOperationMultiply;
    [processor process];

    cv::Scalar resultValue = [data[kArithmeticProcessorMulResultValueKey] scalarValue];
    expect($([outputTex image])).to.beCloseToScalar($(resultValue));
  });

  it(@"should divide two textures in-place", ^{
    LTArithmeticProcessor *processor =
    [[LTArithmeticProcessor alloc] initWithFirstOperand:secondIn
                                          secondOperand:firstIn
                                                 output:outputTex];
    processor.operation = LTArithmeticOperationDivide;
    [processor process];

    cv::Scalar resultValue = [data[kArithmeticProcessorDivResultValueKey] scalarValue];
    expect($([outputTex image])).to.beCloseToScalar($(resultValue));
  });
});

context(@"Processing", ^{
  itShouldBehaveLike(kArithmeticProcessorSharedExamples, ^{
    return @{kArithmeticProcessorFirstInputKey: @0,
             kArithmeticProcessorSecondInputKey: @1,
             kArithmeticProcessorOutputKey: @2,
             kArithmeticProcessorAddResultValueKey: $(cv::Scalar(192, 192, 192, 255)),
             kArithmeticProcessorSubResultValueKey: $(cv::Scalar(64, 64, 64, 255)),
             // Value should be (128 * 64) / 255, since multiplication is done in [0, 1].
             kArithmeticProcessorMulResultValueKey: $(cv::Scalar(32, 32, 32, 255)),
             // Value should be (64 / 255) / (128 / 255), since division is done in [0, 1].
             kArithmeticProcessorDivResultValueKey: $(cv::Scalar(128, 128, 128, 255))
             };
  });

  itShouldBehaveLike(kArithmeticProcessorSharedExamples, ^{
    return @{kArithmeticProcessorFirstInputKey: @0,
             kArithmeticProcessorSecondInputKey: @1,
             kArithmeticProcessorOutputKey: @0,
             kArithmeticProcessorAddResultValueKey: $(cv::Scalar(192, 192, 192, 255)),
             kArithmeticProcessorSubResultValueKey: $(cv::Scalar(64, 64, 64, 255)),
             kArithmeticProcessorMulResultValueKey: $(cv::Scalar(32, 32, 32, 255)),
             kArithmeticProcessorDivResultValueKey: $(cv::Scalar(128, 128, 128, 255))
             };
  });

  itShouldBehaveLike(kArithmeticProcessorSharedExamples, ^{
    return @{kArithmeticProcessorFirstInputKey: @0,
             kArithmeticProcessorSecondInputKey: @1,
             kArithmeticProcessorOutputKey: @1,
             kArithmeticProcessorAddResultValueKey: $(cv::Scalar(192, 192, 192, 255)),
             kArithmeticProcessorSubResultValueKey: $(cv::Scalar(64, 64, 64, 255)),
             kArithmeticProcessorMulResultValueKey: $(cv::Scalar(32, 32, 32, 255)),
             kArithmeticProcessorDivResultValueKey: $(cv::Scalar(128, 128, 128, 255))
             };
  });

  itShouldBehaveLike(kArithmeticProcessorSharedExamples, ^{
    return @{kArithmeticProcessorFirstInputKey: @0,
             kArithmeticProcessorSecondInputKey: @0,
             kArithmeticProcessorOutputKey: @0,
             kArithmeticProcessorAddResultValueKey: $(cv::Scalar(255, 255, 255, 255)),
             kArithmeticProcessorSubResultValueKey: $(cv::Scalar(0, 0, 0, 255)),
             kArithmeticProcessorMulResultValueKey: $(cv::Scalar(64, 64, 64, 255)),
             kArithmeticProcessorDivResultValueKey: $(cv::Scalar(255, 255, 255, 255))
             };
  });

  itShouldBehaveLike(kArithmeticProcessorSharedExamples, ^{
    return @{kArithmeticProcessorFirstInputKey: @1,
             kArithmeticProcessorSecondInputKey: @1,
             kArithmeticProcessorOutputKey: @1,
             kArithmeticProcessorAddResultValueKey: $(cv::Scalar(128, 128, 128, 255)),
             kArithmeticProcessorSubResultValueKey: $(cv::Scalar(0, 0, 0, 255)),
             kArithmeticProcessorMulResultValueKey: $(cv::Scalar(16, 16, 16, 255)),
             kArithmeticProcessorDivResultValueKey: $(cv::Scalar(255, 255, 255, 255))
             };
  });

  itShouldBehaveLike(kArithmeticProcessorSharedExamples, ^{
    return @{kArithmeticProcessorFirstInputKey: @0,
             kArithmeticProcessorSecondInputKey: @0,
             kArithmeticProcessorOutputKey: @2,
             kArithmeticProcessorAddResultValueKey: $(cv::Scalar(255, 255, 255, 255)),
             kArithmeticProcessorSubResultValueKey: $(cv::Scalar(0, 0, 0, 255)),
             kArithmeticProcessorMulResultValueKey: $(cv::Scalar(64, 64, 64, 255)),
             kArithmeticProcessorDivResultValueKey: $(cv::Scalar(255, 255, 255, 255))
             };
  });

  itShouldBehaveLike(kArithmeticProcessorSharedExamples, ^{
    return @{kArithmeticProcessorFirstInputKey: @1,
             kArithmeticProcessorSecondInputKey: @1,
             kArithmeticProcessorOutputKey: @2,
             kArithmeticProcessorAddResultValueKey: $(cv::Scalar(128, 128, 128, 255)),
             kArithmeticProcessorSubResultValueKey: $(cv::Scalar(0, 0, 0, 255)),
             kArithmeticProcessorMulResultValueKey: $(cv::Scalar(16, 16, 16, 255)),
             kArithmeticProcessorDivResultValueKey: $(cv::Scalar(255, 255, 255, 255))
             };
  });
});

SpecEnd
