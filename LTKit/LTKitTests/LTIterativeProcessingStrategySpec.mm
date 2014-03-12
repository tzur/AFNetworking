// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIterativeProcessingStrategy.h"

#import "LTTexture+Factory.h"

SpecBegin(LTIterativeProcessingStrategy)

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

__block LTTexture *input;
__block LTTexture *outputA;
__block LTTexture *outputB;

beforeEach(^{
  cv::Mat image = cv::Mat4b::zeros(16, 16);

  input = [LTTexture textureWithImage:image];
  outputA = [LTTexture textureWithImage:image];
  outputB = [LTTexture textureWithImage:image];
});

afterEach(^{
  input = nil;
  outputA = nil;
  outputB = nil;
});

context(@"initialization", ^{
  it(@"should initialize with input and output", ^{
    expect(^{
      __unused LTIterativeProcessingStrategy *strategy =
          [[LTIterativeProcessingStrategy alloc] initWithInput:input andOutputs:@[outputA]];
    }).toNot.raiseAny();
  });

  it(@"should initialize with more than one output", ^{
    expect((^{
      __unused LTIterativeProcessingStrategy *strategy =
      [[LTIterativeProcessingStrategy alloc] initWithInput:input andOutputs:@[outputA, outputB]];
    })).toNot.raiseAny();
  });

  it(@"should not initialize with nil input", ^{
    expect(^{
      __unused LTIterativeProcessingStrategy *strategy = [[LTIterativeProcessingStrategy alloc]
                                                          initWithInput:nil andOutputs:@[outputA]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with nil outputs", ^{
    expect(^{
      __unused LTIterativeProcessingStrategy *strategy = [[LTIterativeProcessingStrategy alloc]
                                                          initWithInput:input andOutputs:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"LTProcessingStrategy", ^{
  __block LTIterativeProcessingStrategy *strategy;

  const NSUInteger iterationsForOutputA = 1;
  const NSUInteger iterationsForOutputB = 4;

  beforeEach(^{
    strategy = [[LTIterativeProcessingStrategy alloc] initWithInput:input
                                                         andOutputs:@[outputA, outputB]];
    strategy.iterationsPerOutput = @[@(iterationsForOutputA), @(iterationsForOutputB)];
  });

  afterEach(^{
    strategy = nil;
  });

  it(@"should initially have iterations", ^{
    expect([strategy hasMoreIterations]).to.beTruthy();
  });

  it(@"should mark end of processing", ^{
    [strategy processingWillBegin];

    for (NSUInteger i = 0; i < iterationsForOutputB; ++i) {
      [strategy iterationStarted];
      [strategy iterationEnded];
    }

    expect([strategy hasMoreIterations]).to.beFalsy();
  });

  it(@"should raise when trying to start iteration above iteration count", ^{
    [strategy processingWillBegin];

    for (NSUInteger i = 0; i < iterationsForOutputB; ++i) {
      [strategy iterationStarted];
      [strategy iterationEnded];
    }

    expect(^{
      [strategy iterationStarted];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should initially generate no processed outputs", ^{
    expect([strategy processedOutputs]).to.beNil();
  });

  it(@"should generate processed output once ready", ^{
    [strategy processingWillBegin];

    for (NSUInteger i = 0; i < iterationsForOutputA; ++i) {
      [strategy iterationStarted];
      [strategy iterationEnded];
    }

    id<LTImageProcessorOutput> processedA = [strategy processedOutputs];
    expect(processedA).to.beKindOf([LTMultipleTextureOutput class]);
    expect(((LTMultipleTextureOutput *)processedA).textures.count).to.equal(1);

    for (NSUInteger i = 0; i < iterationsForOutputB - iterationsForOutputA; ++i) {
      [strategy iterationStarted];
      [strategy iterationEnded];
    }

    id<LTImageProcessorOutput> processedB = [strategy processedOutputs];
    expect(((LTMultipleTextureOutput *)processedB).textures.count).to.equal(2);
  });
});

context(@"iterations", ^{
  __block LTIterativeProcessingStrategy *strategy;

  beforeEach(^{
    strategy = [[LTIterativeProcessingStrategy alloc] initWithInput:input
                                                         andOutputs:@[outputA, outputB]];
  });

  it(@"should not allow to set zero iterations", ^{
    expect((^{
      strategy.iterationsPerOutput = @[@0, @1];
    })).to.raise(NSInvalidArgumentException);
  });

  it(@"should not allow non monotonic increasing iterations", ^{
    expect((^{
      strategy.iterationsPerOutput = @[@2, @1];
    })).to.raise(NSInvalidArgumentException);
  });

  it(@"should not allow wrong number of iterations elements", ^{
    expect((^{
      strategy.iterationsPerOutput = @[@1, @2, @3];
    })).to.raise(NSInvalidArgumentException);
  });

  it(@"should allow weakly monotonic increasing iterations", ^{
    expect((^{
      strategy.iterationsPerOutput = @[@1, @1];
    })).toNot.raiseAny();
  });

  it(@"should allow strongly monotonic increasing iterations", ^{
    expect((^{
      strategy.iterationsPerOutput = @[@1, @2];
    })).toNot.raiseAny();
  });
});

SpecEnd
