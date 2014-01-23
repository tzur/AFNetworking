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

  if (self = [super initWithProgram:program sourceTexture:output auxiliaryTextures:nil
                          andOutput:output]) {
    self.amplitude = 1.0;
    [self updateSeeds];
  }
  return self;
}

- (void)setAmplitude:(CGFloat)amplitude {
  LTParameterAssert(amplitude >= 0, @"Amplitude should be greater than or equal to 0");
  _amplitude = amplitude;
  self[@"amplitude"] = @(amplitude);
}

- (void)setSeed0:(CGFloat)seed0 {
  _seed0 = seed0;
  self[@"seed0"] = @(seed0);
}

- (void)setSeed1:(CGFloat)seed1 {
  _seed1 = seed1;
  self[@"seed1"] = @(seed1);
}

- (void)setSeed2:(CGFloat)seed2 {
  _seed2 = seed2;
  self[@"seed2"] = @(seed2);
}

- (void)updateSeeds {
  // Update random seed values.
  // The drand48() returns non-negative, double-precision, floating-point values, uniformly
  // distributed over the interval [0.0 , 1.0].
  self[@"seed0"] = @(drand48());
  self[@"seed1"] = @(drand48());
  self[@"seed2"] = @(drand48());
}

- (id<LTImageProcessorOutput>)process {
  return [super process];
}

@end

