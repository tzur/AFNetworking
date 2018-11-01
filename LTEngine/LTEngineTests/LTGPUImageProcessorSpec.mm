// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUImageProcessor.h"

#import "LTFbo.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTNextIterationPlacement.h"
#import "LTTexture.h"

SpecBegin(LTGPUImageProcessor)

__block id drawer;
__block id strategy;
__block id texture;

beforeEach(^{
  drawer = [OCMockObject niceMockForProtocol:@protocol(LTTextureDrawer)];
  strategy = [OCMockObject niceMockForProtocol:@protocol(LTProcessingStrategy)];
  texture = [OCMockObject niceMockForClass:[LTTexture class]];
});

context(@"initialization", ^{
  it(@"should initialize with nil auxiliary textures", ^{
    expect(^{
      __unused LTGPUImageProcessor *processor =
      [[LTGPUImageProcessor alloc] initWithDrawer:drawer strategy:strategy
                             andAuxiliaryTextures:nil];
    }).toNot.raiseAny();
  });
});

context(@"drawer", ^{
  it(@"should set source texture", ^{
    [[[strategy expect] andReturnValue:@(YES)] hasMoreIterations];
    [[[strategy expect] andReturnValue:@(NO)] hasMoreIterations];

    LTFbo *targetFBO = OCMClassMock([LTFbo class]);
    LTNextIterationPlacement *placement = [[LTNextIterationPlacement alloc]
                                           initWithSourceTexture:texture andTargetFbo:targetFBO];
    [[[strategy stub] andReturn:placement] iterationStarted];

    [[drawer expect] setSourceTexture:texture];

    LTGPUImageProcessor *processor =
        [[LTGPUImageProcessor alloc] initWithDrawer:drawer strategy:strategy
                               andAuxiliaryTextures:nil];
    [processor process];

    OCMVerifyAll(drawer);
    OCMVerifyAll(strategy);
  });

  it(@"should set auxiliary textures", ^{
    static NSString * const kTextureName = @"MyTexture";

    [[drawer expect] setAuxiliaryTexture:texture withName:kTextureName];

    LTGPUImageProcessor *processor =
        [[LTGPUImageProcessor alloc] initWithDrawer:drawer strategy:strategy
                               andAuxiliaryTextures:@{kTextureName: texture}];
    [processor process];

    OCMVerifyAll(drawer);
  });

  it(@"should set auxiliary texture after given nil to auxiliary textures in the initializer", ^{
    static NSString * const kTextureName = @"MyTexture";

    LTGPUImageProcessor *processor =
        [[LTGPUImageProcessor alloc] initWithDrawer:drawer strategy:strategy
                               andAuxiliaryTextures:nil];
    [processor setAuxiliaryTexture:texture withName:kTextureName];
    [processor process];

    expect(processor.auxiliaryTextures[kTextureName]).to.equal(texture);
  });

  it(@"should set auxiliary texture via protected interface", ^{
    static NSString * const kTextureName = @"MyTexture";

    [[drawer expect] setAuxiliaryTexture:texture withName:kTextureName];

    LTGPUImageProcessor *processor =
        [[LTGPUImageProcessor alloc] initWithDrawer:drawer strategy:strategy
                               andAuxiliaryTextures:nil];
    [processor setAuxiliaryTexture:texture withName:kTextureName];
    [processor process];

    OCMVerifyAll(drawer);
  });

  static NSString * const kUniformName = @"MyUniform";
  static NSNumber * const kUniformValue = @(5);

  it(@"should set uniforms", ^{
    [[drawer expect] setUniform:kUniformName withValue:kUniformValue];

    LTGPUImageProcessor *processor =
        [[LTGPUImageProcessor alloc] initWithDrawer:drawer strategy:strategy
                               andAuxiliaryTextures:nil];
    processor[kUniformName] = kUniformValue;

    OCMVerifyAll(drawer);
  });

  it(@"should get uniforms", ^{
    [[drawer expect] uniformForName:kUniformName];

    LTGPUImageProcessor *processor =
        [[LTGPUImageProcessor alloc] initWithDrawer:drawer strategy:strategy
                               andAuxiliaryTextures:nil];
    __unused id value = processor[kUniformName];

    OCMVerifyAll(drawer);
  });
});

context(@"strategy", ^{
  __block LTGPUImageProcessor *processor;

  beforeEach(^{
    processor = [[LTGPUImageProcessor alloc] initWithDrawer:drawer strategy:strategy
                                       andAuxiliaryTextures:nil];
  });

  it(@"should notify strategy when processing begins", ^{
    [[strategy expect] processingWillBegin];

    LTGPUImageProcessor *processor =
        [[LTGPUImageProcessor alloc] initWithDrawer:drawer strategy:strategy
                               andAuxiliaryTextures:nil];
    [processor process];

    OCMVerifyAll(strategy);
  });

  it(@"should run the desired number of iterations", ^{
    LTFbo *targetFBO = OCMClassMock([LTFbo class]);
    LTNextIterationPlacement *placement = [[LTNextIterationPlacement alloc]
                                           initWithSourceTexture:texture andTargetFbo:targetFBO];

    const NSUInteger kNumberOfIterations = 4;

    for (NSUInteger i = 0; i < kNumberOfIterations; ++i) {
      [[[strategy expect] andReturnValue:@(YES)] hasMoreIterations];
    }
    [[[strategy expect] andReturnValue:@(NO)] hasMoreIterations];

    for (NSUInteger i = 0; i < kNumberOfIterations; ++i) {
      [[[strategy expect] andReturn:placement] iterationStarted];
      [[strategy expect] iterationEnded];
    }

    [processor process];

    OCMVerifyAll(strategy);
  });

  it(@"should produce outputs from strategy", ^{
    [[strategy expect] processingWillBegin];

    LTGPUImageProcessor *processor =
        [[LTGPUImageProcessor alloc] initWithDrawer:drawer strategy:strategy
                               andAuxiliaryTextures:nil];
    [processor process];

    OCMVerifyAll(strategy);
  });
});

SpecEnd
