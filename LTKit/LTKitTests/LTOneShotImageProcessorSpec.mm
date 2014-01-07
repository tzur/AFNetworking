// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

#import "LTFbo.h"
#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTShaderStorage+AdderFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTTestUtils.h"

SpecBegin(LTOneShotImageProcessor)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

__block LTTexture *input;
__block LTTexture *output;
__block LTProgram *program;

beforeEach(^{
  input = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                  precision:LTTexturePrecisionByte
                                   channels:LTTextureChannelsRGBA
                             allocateMemory:YES];

  output = [[LTGLTexture alloc] initWithSize:input.size
                                   precision:input.precision
                                    channels:input.channels
                              allocateMemory:YES];

  program = [[LTProgram alloc]
             initWithVertexSource:[LTShaderStorage passthroughVsh]
             fragmentSource:[LTShaderStorage adderFsh]];
});

afterEach(^{
  input = nil;
  output = nil;
  program = nil;
});

context(@"intialization", ^{
  it(@"should initialize with one input and output", ^{
    expect(^{
      __unused LTOneShotImageProcessor *processor = [[LTOneShotImageProcessor alloc]
                                                     initWithProgram:program inputs:@[input]
                                                     outputs:@[output]];
    }).toNot.raiseAny();
  });

  it(@"should not initialize with more than one input", ^{
    expect((^{
      __unused LTOneShotImageProcessor *processor = [[LTOneShotImageProcessor alloc]
                                                     initWithProgram:program inputs:@[input, input]
                                                     outputs:@[output]];
    })).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with more than one output", ^{
    expect((^{
      __unused LTOneShotImageProcessor *processor = [[LTOneShotImageProcessor alloc]
                                                     initWithProgram:program inputs:@[input]
                                                     outputs:@[output, output]];
    })).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  beforeEach(^{
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:input];
    [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
  });

  it(@"should produce correct output", ^{
    LTOneShotImageProcessor *processor = [[LTOneShotImageProcessor alloc]
                                          initWithProgram:program inputs:@[input]
                                          outputs:@[output]];
    processor[@"value"] = @0.5;

    LTSingleTextureOutput *processed = [processor process];

    cv::Scalar expected(128, 128, 128, 255);
    expect(LTCompareMatWithValue(expected, [processed.texture image])).to.beTruthy();
  });
});

SpecEnd
