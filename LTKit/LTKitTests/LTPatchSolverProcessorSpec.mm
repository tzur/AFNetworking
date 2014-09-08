// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchSolverProcessor.h"

#import "LTGLContext.h"
#import "LTTexture+Factory.h"
#import "LTTestUtils.h"

SpecBegin(LTPatchSolverProcessor)

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

context(@"initialization", ^{
  it(@"should initialize with a half-float power of two output", ^{
    LTTexture *mask = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *source = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *target = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *output = [LTTexture textureWithSize:CGSizeMake(15, 16)
                                         precision:LTTexturePrecisionHalfFloat
                                            format:LTTextureFormatRGBA allocateMemory:YES];

    expect(^{
      LTPatchSolverProcessor __unused *processor = [[LTPatchSolverProcessor alloc]
                                                    initWithMask:mask
                                                    source:source target:target
                                                    output:output];
    }).toNot.raiseAny();
  });
  
  it(@"should not initialize with non half-float texture", ^{
    LTTexture *mask = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *source = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *target = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *output = [LTTexture textureWithSize:CGSizeMake(15, 16)
                                         precision:LTTexturePrecisionByte
                                            format:LTTextureFormatRGBA allocateMemory:YES];

    expect(^{
      LTPatchSolverProcessor __unused *processor = [[LTPatchSolverProcessor alloc]
                                                    initWithMask:mask
                                                    source:source target:target
                                                    output:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  it(@"should produce constant membrane on constant inputs", ^{
    LTTexture *mask = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *source = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *target = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *output = [LTTexture textureWithSize:CGSizeMake(16, 16)
                                         precision:LTTexturePrecisionHalfFloat
                                            format:LTTextureFormatRGBA allocateMemory:YES];

    [mask clearWithColor:LTVector4(1, 1, 1, 1)];
    [source clearWithColor:LTVector4(0.75, 0.75, 0.75, 1)];
    [target clearWithColor:LTVector4(0.5, 0.5, 0.5, 1)];

    LTPatchSolverProcessor *processor = [[LTPatchSolverProcessor alloc] initWithMask:mask
                                                                              source:source
                                                                              target:target
                                                                              output:output];
    [processor process];

    expect($([output image])).to.beCloseToScalarWithin($(cv::Scalar(-0.25, -0.25, -0.25, 0)), 1e-2);
  });
});

SpecEnd
