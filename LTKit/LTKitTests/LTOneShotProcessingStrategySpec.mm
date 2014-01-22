// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotProcessingStrategy.h"

#import "LTFbo.h"
#import "LTGLTexture.h"

SpecBegin(LTOneShotProcessingStrategy)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

__block LTTexture *input;
__block LTTexture *output;

beforeEach(^{
  cv::Mat image = cv::Mat4b::zeros(16, 16);

  input = [[LTGLTexture alloc] initWithImage:image];
  output = [[LTGLTexture alloc] initWithImage:image];
});

afterEach(^{
  input = nil;
  output = nil;
});

context(@"initialization", ^{
  it(@"should initialize with input and output", ^{
    expect(^{
      __unused LTOneShotProcessingStrategy *strategy = [[LTOneShotProcessingStrategy alloc]
                                                        initWithInput:input andOutput:output];
    }).toNot.raiseAny();
  });
});

context(@"LTProcessingStrategy", ^{
  __block LTOneShotProcessingStrategy *strategy;

  beforeEach(^{
    strategy = [[LTOneShotProcessingStrategy alloc] initWithInput:input andOutput:output];
  });

  afterEach(^{
    strategy = nil;
  });

  it(@"should initially have more iterations", ^{
    expect([strategy hasMoreIterations]).to.beTruthy();
  });

  it(@"should return correct placement", ^{
    LTNextIterationPlacement *placement = [strategy iterationStarted];

    expect(placement.sourceTexture).to.equal(input);
    expect(placement.targetFbo.texture).to.equal(output);
  });

  it(@"should mark end of processing", ^{
    [strategy processingWillBegin];
    [strategy iterationStarted];
    [strategy iterationEnded];

    expect([strategy hasMoreIterations]).to.beFalsy();
  });

  it(@"should create processed outputs after processing", ^{
    [strategy processingWillBegin];
    [strategy iterationStarted];
    [strategy iterationEnded];
    id<LTImageProcessorOutput> processorOutput = [strategy processedOutputs];

    expect(processorOutput).to.beKindOf([LTSingleTextureOutput class]);
    expect(((LTSingleTextureOutput *)processorOutput).texture).to.equal(output);
  });

  it(@"should create nil processed outputs before processing", ^{
    expect([strategy processedOutputs]).to.beNil();
  });
});

SpecEnd
