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
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

__block LTGLTexture *source;
__block LTGLTexture *output0;
__block LTGLTexture *output1;
__block LTProgram *validProgram;
__block LTProgram *invalidProgram;

beforeEach(^{
  source = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                   precision:LTTexturePrecisionByte
                                      format:LTTextureFormatRGBA
                              allocateMemory:YES];
  output0 = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                    precision:LTTexturePrecisionByte
                                       format:LTTextureFormatRGBA
                               allocateMemory:YES];
  output1 = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                    precision:LTTexturePrecisionByte
                                       format:LTTextureFormatRGBA
                               allocateMemory:YES];
  
  validProgram = [[LTProgram alloc] initWithVertexSource:[TexelOffsetVsh source]
                                          fragmentSource:[TexelOffsetFsh source]];
  invalidProgram = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                            fragmentSource:[PassthroughFsh source]];
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
  it(@"iterations per output", ^{
    LTSeparableImageProcessor *processor =
        [[LTSeparableImageProcessor alloc] initWithProgram:validProgram sourceTexture:source
                                                   outputs:@[output0, output1]];
    NSArray * const kIterationPerOutput = @[@1, @7];
    processor.iterationsPerOutput = kIterationPerOutput;
    expect(processor.iterationsPerOutput).to.equal(kIterationPerOutput);
  });
});

SpecEnd
