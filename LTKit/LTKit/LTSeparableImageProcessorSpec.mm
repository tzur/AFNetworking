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
__block LTGLTexture *output0;
__block LTGLTexture *output1;
__block LTProgram *validProgram;
__block LTProgram *invalidProgram;

beforeEach(^{
  source = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                   precision:LTTexturePrecisionByte
                                    channels:LTTextureChannelsRGBA
                              allocateMemory:YES];
  output0 = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                    precision:LTTexturePrecisionByte
                                     channels:LTTextureChannelsRGBA
                               allocateMemory:YES];
  
  output1 = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                    precision:LTTexturePrecisionByte
                                     channels:LTTextureChannelsRGBA
                               allocateMemory:YES];
  
  validProgram = [[LTProgram alloc] initWithVertexSource:[LTShaderStorage texelOffsetVsh]
                                          fragmentSource:[LTShaderStorage texelOffsetFsh]];
  invalidProgram = [[LTProgram alloc] initWithVertexSource:[LTShaderStorage passthroughVsh]
                                            fragmentSource:[LTShaderStorage passthroughFsh]];
});

afterEach(^{
  source = nil;
  output0 = nil;
  output1 = nil;
  validProgram = nil;
  invalidProgram = nil;
});

context(@"initialization", ^{
  it(@"should not initialize on program that doesn't include texelOffset uniform", ^{
    expect(^{
      __unused LTSeparableImageProcessor *processor =
          [[LTSeparableImageProcessor alloc] initWithProgram:invalidProgram sourceTexture:source
                                                     outputs:@[output0]];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should initialize on correct program", ^{
    expect(^{
      __unused LTSeparableImageProcessor *processor =
          [[LTSeparableImageProcessor alloc] initWithProgram:validProgram sourceTexture:source
                                                     outputs:@[output0]];
    }).toNot.raiseAny();
  });
});

context(@"properties", ^{
  fit(@"iterations per output", ^{
    LTSeparableImageProcessor *processor =
        [[LTSeparableImageProcessor alloc] initWithProgram:validProgram sourceTexture:source
                                                   outputs:@[output0, output1]];
    NSArray * const kIterationPerOutput = @[@1, @7];
    processor.iterationsPerOutput = kIterationPerOutput;
    expect(processor.iterationsPerOutput).to.equal(kIterationPerOutput);
  });
});

SpecEnd
