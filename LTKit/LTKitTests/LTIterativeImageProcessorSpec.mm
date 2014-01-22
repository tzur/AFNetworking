// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIterativeImageProcessor.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTShaderStorage+AdderFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTTestUtils.h"

@interface LTIterativeImageProcessorStub : LTIterativeImageProcessor

typedef void (^LTIterativeImageProcessorStubCallback)(NSUInteger iteration);

/// Block which is called on each iteration.
@property (copy, nonatomic) LTIterativeImageProcessorStubCallback callback;

@end

@implementation LTIterativeImageProcessorStub

- (void)iterationStarted:(NSUInteger)iteration {
  if (self.callback) {
    self.callback(iteration);
  }
}

@end

SpecBegin(LTIterativeImageProcessor)

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

__block LTTexture *input;
__block LTTexture *auxInput;
__block LTTexture *output;
__block LTProgram *program;
__block NSDictionary *auxiliaryTextures;

beforeEach(^{
  input = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                  precision:LTTexturePrecisionByte
                                   channels:LTTextureChannelsRGBA
                             allocateMemory:YES];

  cv::Mat image = cv::Mat4b::zeros(1, 1);
  auxInput = [[LTGLTexture alloc] initWithImage:image];

  output = [[LTGLTexture alloc] initWithSize:input.size
                                   precision:input.precision
                                    channels:input.channels
                              allocateMemory:YES];

  program = [[LTProgram alloc]
             initWithVertexSource:[LTShaderStorage passthroughVsh]
             fragmentSource:[LTShaderStorage adderFsh]];

  auxiliaryTextures = @{@"auxTexture": auxInput};
});

afterEach(^{
  input = nil;
  output = nil;
  program = nil;
});

context(@"initialization", ^{
  it(@"should initialize with single input and output", ^{
    LTIterativeImageProcessor *processor = [[LTIterativeImageProcessor alloc]
                                            initWithProgram:program sourceTexture:input
                                            outputs:@[output]];

    expect(processor.iterationsPerOutput).to.equal(@[@1]);
  });

  it(@"should initialize with single input and multiple outputs", ^{
    LTIterativeImageProcessor *processor = [[LTIterativeImageProcessor alloc]
                                            initWithProgram:program sourceTexture:input
                                            outputs:@[output, output]];

    expect(processor.iterationsPerOutput).to.equal(@[@1, @1]);
  });

  it(@"should initialize with auxiliary textures", ^{
    LTIterativeImageProcessor *processor = [[LTIterativeImageProcessor alloc]
                                            initWithProgram:program sourceTexture:input
                                            auxiliaryTextures:auxiliaryTextures
                                            outputs:@[output]];

    expect(processor.iterationsPerOutput).to.equal(@[@1]);
  });

  it(@"should not initialize with unsimilar outputs", ^{
    LTTexture *different = [[LTGLTexture alloc] initWithSize:input.size + 1
                                                   precision:input.precision
                                                    channels:input.channels
                                              allocateMemory:YES];

    expect((^{
      __unused LTIterativeImageProcessor *processor = [[LTIterativeImageProcessor alloc]
                                                       initWithProgram:program sourceTexture:input
                                                       outputs:@[output, different]];
    })).to.raise(NSInvalidArgumentException);
  });
});

context(@"iterations", ^{
  __block LTIterativeImageProcessor *processor;

  beforeEach(^{
    processor = [[LTIterativeImageProcessor alloc] initWithProgram:program sourceTexture:input
                                                           outputs:@[output, output]];
  });

  it(@"should not allow to set zero iterations", ^{
    expect((^{
      processor.iterationsPerOutput = @[@0, @1];
    })).to.raise(NSInvalidArgumentException);
  });

  it(@"should not allow non monotonic increasing iterations", ^{
    expect((^{
      processor.iterationsPerOutput = @[@2, @1];
    })).to.raise(NSInvalidArgumentException);
  });

  it(@"should not allow wrong number of iterations elements", ^{
    expect((^{
      processor.iterationsPerOutput = @[@1, @2, @3];
    })).to.raise(NSInvalidArgumentException);
  });

  it(@"should allow weakly monotonic increasing iterations", ^{
    expect((^{
      processor.iterationsPerOutput = @[@1, @1];
    })).toNot.raiseAny();
  });

  it(@"should allow strongly monotonic increasing iterations", ^{
    expect((^{
      processor.iterationsPerOutput = @[@1, @2];
    })).toNot.raiseAny();
  });
});

context(@"iteration block", ^{
  __block LTIterativeImageProcessorStub *processor;

  beforeEach(^{
    processor = [[LTIterativeImageProcessorStub alloc] initWithProgram:program sourceTexture:input
                                                               outputs:@[output]];
  });

  it(@"should call iteration block each iteration", ^{
    __block NSUInteger blockCallCount = 0;
    processor.callback = ^(NSUInteger iteration) {
      expect(iteration).to.equal(blockCallCount);
      ++blockCallCount;
    };

    static const NSUInteger kIterations = 3;
    processor.iterationsPerOutput = @[@(kIterations)];

    [processor process];

    expect(blockCallCount).to.equal(kIterations);
  });
});

context(@"processing", ^{
  __block LTIterativeImageProcessor *processor;

  beforeEach(^{
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:input];
    [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
  });

  afterEach(^{
    processor = nil;
  });

  context(@"single output", ^{
    beforeEach(^{
      processor = [[LTIterativeImageProcessor alloc] initWithProgram:program sourceTexture:input
                                                   auxiliaryTextures:auxiliaryTextures
                                                             outputs:@[output]];
    });

    afterEach(^{
      processor = nil;
    });

    sharedExamplesFor(@"processing output correctly", ^(NSDictionary *data) {
      __block LTIterativeImageProcessor *processor;
      __block unsigned char value;
      __block NSArray *iterations;

      beforeEach(^{
        processor = data[@"processor"];
        value = [data[@"expected"] unsignedCharValue];
        iterations = data[@"iterations"];
      });

      afterEach(^{
        processor = nil;
      });

      it(@"should process correctly", ^{
        processor.iterationsPerOutput = iterations;
        processor[@"value"] = @(0.25);

        LTMultipleTextureOutput *output = [processor process];
        LTTexture *result = [output.textures firstObject];
        cv::Scalar scalar(value, value, value, 255);

        expect(LTCompareMatWithValue(scalar, [result image])).to.beTruthy();
      });
    });

    // Single iteration.
    itShouldBehaveLike(@"processing output correctly", ^{
      return @{@"processor": processor,
               @"expected": @64,
               @"iterations": @[@1]};
    });

    // Odd number of iterations.
    itShouldBehaveLike(@"processing output correctly", ^{
      return @{@"processor": processor,
               @"expected": @192,
               @"iterations": @[@3]};
    });

    // Even number of iterations.
    itShouldBehaveLike(@"processing output correctly", ^{
      return @{@"processor": processor,
               @"expected": @128,
               @"iterations": @[@2]};
    });
  });

  context(@"multiple outputs", ^{
    beforeEach(^{
      LTTexture *anotherOutput = [[LTGLTexture alloc] initWithSize:input.size
                                                         precision:input.precision
                                                          channels:input.channels
                                                    allocateMemory:YES];

      processor = [[LTIterativeImageProcessor alloc] initWithProgram:program sourceTexture:input
                                                   auxiliaryTextures:@{@"auxTexture": auxInput}
                                                             outputs:@[output, anotherOutput]];
    });

    sharedExamplesFor(@"processing output correctly", ^(NSDictionary *data) {
      __block LTIterativeImageProcessor *processor;
      __block unsigned char firstValue;
      __block unsigned char secondValue;
      __block NSArray *iterations;

      beforeEach(^{
        processor = data[@"processor"];
        firstValue = [data[@"firstExpected"] unsignedCharValue];
        secondValue = [data[@"secondExpected"] unsignedCharValue];
        iterations = data[@"iterations"];
      });

      afterEach(^{
        processor = nil;
      });

      it(@"should process correctly", ^{
        processor.iterationsPerOutput = iterations;
        processor[@"value"] = @(0.25);

        LTMultipleTextureOutput *output = [processor process];

        LTTexture *firstResult = [output.textures firstObject];
        cv::Scalar firstScalar(firstValue, firstValue, firstValue, 255);
        expect(LTCompareMatWithValue(firstScalar, [firstResult image])).to.beTruthy();

        LTTexture *secondResult = [output.textures lastObject];
        cv::Scalar secondScalar(secondValue, secondValue, secondValue, 255);
        expect(LTCompareMatWithValue(secondScalar, [secondResult image])).to.beTruthy();
      });
    });

    // Similar number of iterations.
    itShouldBehaveLike(@"processing output correctly", ^{
      return @{@"processor": processor,
               @"firstExpected": @64,
               @"secondExpected": @64,
               @"iterations": @[@1, @1]};
    });

    // Odd number of iterations.
    itShouldBehaveLike(@"processing output correctly", ^{
      return @{@"processor": processor,
               @"firstExpected": @64,
               @"secondExpected": @192,
               @"iterations": @[@1, @3]};
    });

    // Even number of iterations.
    itShouldBehaveLike(@"processing output correctly", ^{
      return @{@"processor": processor,
               @"firstExpected": @128,
               @"secondExpected": @255,
               @"iterations": @[@2, @4]};
    });

    // Even and odd number of iterations.
    itShouldBehaveLike(@"processing output correctly", ^{
      return @{@"processor": processor,
               @"firstExpected": @128,
               @"secondExpected": @192,
               @"iterations": @[@2, @3]};
    });
  });
});

SpecEnd
