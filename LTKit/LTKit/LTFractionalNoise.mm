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
    [[LTProgram alloc] initWithVertexSource:[LTFractionalNoiseVsh source]
                             fragmentSource:[LTFractionalNoiseFsh source]];

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

- (void)setHorizontalSeed:(CGFloat)horizontalSeed {
  _horizontalSeed = horizontalSeed;
  self[@"horizontalSeed"] = @(horizontalSeed);
}

- (void)setVerticalSeed:(CGFloat)verticalSeed {
  _verticalSeed = verticalSeed;
  self[@"verticalSeed"] = @(verticalSeed);
}

- (void)setVelocitySeed:(CGFloat)velocitySeed {
  _velocitySeed = velocitySeed;
  self[@"velocitySeed"] = @(velocitySeed);
}

- (void)updateSeeds {
  // Update random seed values.
  // The drand48() returns non-negative, double-precision, floating-point values, uniformly
  // distributed over the interval [0.0 , 1.0].
  self[@"horizontalSeed"] = @(drand48());
  self[@"verticalSeed"] = @(drand48());
  self[@"velocitySeed"] = @(drand48());
}

- (id<LTImageProcessorOutput>)process {
  return [super process];
}

@end

