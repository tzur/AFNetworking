// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSeparableImageProcessor.h"

#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTShaderStorage+TexelOffsetVsh.h"
#import "LTShaderStorage+TexelOffsetFsh.h"

SpecBegin(LTSeprableImageProcessor)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

__block LTGLTexture *source;
__block LTGLTexture *output;

beforeEach(^{
  source = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                   precision:LTTexturePrecisionByte
                                    channels:LTTextureChannelsRGBA
                              allocateMemory:YES];
  output = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                   precision:LTTexturePrecisionByte
                                    channels:LTTextureChannelsRGBA
                              allocateMemory:YES];
});

afterEach(^{
  source = nil;
  output = nil;
});

context(@"initialization", ^{
  it(@"should not initialize on program that doesn't include texelOffset uniform", ^{
    expect(^{
      LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTShaderStorage passthroughVsh] fragmentSource:[LTShaderStorage passthroughFsh]];
      __unused LTSeparableImageProcessor *processor = [[LTSeparableImageProcessor alloc] initWithProgram:program sourceTexture:source outputs:@[output]];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should initialize on correct program", ^{
    expect(^{
      LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTShaderStorage texelOffsetVsh] fragmentSource:[LTShaderStorage texelOffsetFsh]];
      __unused LTSeparableImageProcessor *processor = [[LTSeparableImageProcessor alloc] initWithProgram:program sourceTexture:source outputs:@[output]];
    }).toNot.raiseAny();
  });
});

SpecEnd
