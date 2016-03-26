// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIterativeProcessingStrategy.h"

#import "LTTexture+Factory.h"

SpecBegin(LTIterativeProcessingStrategy)

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

context(@"state resetting", ^{
  __block LTIterativeProcessingStrategy *strategy;

  beforeEach(^{
    strategy = [[LTIterativeProcessingStrategy alloc] initWithInput:input andOutputs:@[outputA]];
    strategy.iterationsPerOutput = @[@(1)];
  });

  afterEach(^{
    strategy = nil;
  });

  it(@"should reset current iteration value after calling processingWillBegin", ^{
    [strategy processingWillBegin];
    [strategy iterationStarted];
    [strategy iterationEnded];

    [strategy processingWillBegin];

    __block NSUInteger executedIterations = 0;
    strategy.iterationStartedBlock = ^(NSUInteger) {
      ++executedIterations;
    };
    [strategy iterationStarted];

    expect(executedIterations).to.equal(1);
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
