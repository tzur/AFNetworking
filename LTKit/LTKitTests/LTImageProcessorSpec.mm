// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

#import "LTGLTexture.h"

SpecBegin(LTImageProcessor)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

__block LTTexture *texture;

beforeEach(^{
  texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                    precision:LTTexturePrecisionByte
                                     channels:LTTextureChannelsRGBA
                               allocateMemory:YES];
});

context(@"initialization", ^{
  it(@"should initialize with inputs and outputs", ^{
    expect(^{
      __unused LTImageProcessor *processor = [[LTImageProcessor alloc] initWithInputs:@[texture]
                                                                              outputs:@[texture]];
    }).toNot.raiseAny();
  });

  it(@"should not initialize with no inputs", ^{
    expect(^{
      __unused LTImageProcessor *processor = [[LTImageProcessor alloc] initWithInputs:@[]
                                                                              outputs:@[texture]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with no outputs", ^{
    expect(^{
      __unused LTImageProcessor *processor = [[LTImageProcessor alloc] initWithInputs:@[texture]
                                                                              outputs:@[]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with non-texture inputs", ^{
    expect(^{
      __unused LTImageProcessor *processor = [[LTImageProcessor alloc]
                                              initWithInputs:@[[NSNull null]]
                                              outputs:@[[NSNull null]]];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"properties", ^{
  it(@"should set inputs and outputs", ^{
    LTImageProcessor *processor = [[LTImageProcessor alloc] initWithInputs:@[texture]
                                                                   outputs:@[texture]];

    expect(processor.inputs).to.equal(@[texture]);
    expect(processor.outputs).to.equal(@[texture]);
  });
});

context(@"input model", ^{
  it(@"should set an input model value", ^{
    LTImageProcessor *processor = [[LTImageProcessor alloc] initWithInputs:@[texture]
                                                                   outputs:@[texture]];

    static NSString * const kModelKey = @"MyModelKey";
    static NSString * const kModelValue = @"MyModelValue";

    processor[kModelKey] = kModelValue;

    expect(processor[kModelKey]).to.equal(kModelValue);
  });
});

SpecEnd
