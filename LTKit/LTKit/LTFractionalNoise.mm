// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTFractionalNoise.h"

#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTFractionalNoiseVsh.h"
#import "LTShaderStorage+LTFractionalNoiseFsh.h"

@implementation LTFractionalNoise

- (instancetype)initWithOutput:(LTTexture *)output {
  LTProgram *program =
    [[LTProgram alloc] initWithVertexSource:[LTShaderStorage LTFractionalNoiseVsh]
                             fragmentSource:[LTShaderStorage LTFractionalNoiseFsh]];
  // TODO:(zeev) Hack - remove this hack once Yaron patches the processor to recieve nil as input.
  LTTexture *input = [[LTGLTexture alloc] initWithSize:CGSizeMake(32, 32)
                                             precision:LTTexturePrecisionByte
                                              channels:LTTextureChannelsRGBA
                                        allocateMemory:YES];
  
  if (self = [super initWithProgram:program inputs:@[input] outputs:@[output]]) {
    // Default values correspond to pronounced, high-frequency noise.
    self.frequency = 1.0;
    self.amplitude = 1.0;
  }
  return self;
}

- (void)setFrequency:(CGFloat)frequency {
  LTParameterAssert(frequency >= 0 && frequency <= 1, @"Frequency should be between 0 and 1");
  _frequency = frequency;
}

- (void)setAmplitude:(CGFloat)amplitude {
  LTParameterAssert(amplitude >= 0, @"Amplitude should be greater than or equal to 0");
  _amplitude = amplitude;
  self[@"amplitude"] = @(amplitude);
}

- (id<LTImageProcessorOutput>)process {
  // Update random seed values.
  // The drand48() returns non-negative, double-precision, floating-point values, uniformly
  // distributed over the interval [0.0 , 1.0].
  self[@"seed0"] = @(drand48());
  self[@"seed1"] = @(drand48());
  self[@"seed2"] = @(drand48());
  return [super process];
}

@end

