// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotProcessingStrategy.h"

#import "LTGLTexture.h"
#import "LTTextureFbo.h"

SpecGLBegin(LTOneShotProcessingStrategy)

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
});

SpecGLEnd
