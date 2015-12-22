// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSeparableImageProcessor.h"

#import "LTProgram.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTShaderStorage+TexelOffsetVsh.h"
#import "LTShaderStorage+TexelOffsetFsh.h"
#import "LTTexture+Factory.h"

SpecBegin(LTSeprableImageProcessor)

__block LTTexture *source;
__block LTTexture *output0;
__block LTTexture *output1;

beforeEach(^{
  source = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
  output0 = [LTTexture textureWithPropertiesOf:source];
  output1 = [LTTexture textureWithPropertiesOf:source];
});

afterEach(^{
  source = nil;
  output0 = nil;
  output1 = nil;
});

context(@"initialization", ^{
  it(@"should not initialize on program that doesn't include texelOffset uniform", ^{
    expect(^{
      __unused LTSeparableImageProcessor *processor =
          [[LTSeparableImageProcessor alloc] initWithVertexSource:[PassthroughVsh source]
                                                   fragmentSource:[PassthroughFsh source]
                                                    sourceTexture:source
                                                          outputs:@[output0]];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should initialize on correct program", ^{
    expect(^{
      __unused LTSeparableImageProcessor *processor =
          [[LTSeparableImageProcessor alloc] initWithVertexSource:[TexelOffsetVsh source]
                                                   fragmentSource:[TexelOffsetFsh source]
                                                    sourceTexture:source
                                                          outputs:@[output0]];
    }).toNot.raiseAny();
  });
});

context(@"properties", ^{
  it(@"iterations per output", ^{
    LTSeparableImageProcessor *processor =
        [[LTSeparableImageProcessor alloc] initWithVertexSource:[TexelOffsetVsh source]
                                                 fragmentSource:[TexelOffsetFsh source]
                                                  sourceTexture:source
                                                        outputs:@[output0, output1]];
    static NSArray * const kIterationPerOutput = @[@1, @7];
    processor.iterationsPerOutput = kIterationPerOutput;
    expect(processor.iterationsPerOutput).to.equal(kIterationPerOutput);
  });
});

SpecEnd
