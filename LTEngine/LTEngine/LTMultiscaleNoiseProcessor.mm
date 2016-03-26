// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTMultiscaleNoiseProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTMultiscaleNoiseFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@implementation LTMultiscaleNoiseProcessor

- (instancetype)initWithOutput:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTMultiscaleNoiseFsh source] sourceTexture:output
                       auxiliaryTextures:nil
                               andOutput:output]) {
    self.seed = 0.0;
    self.density = 2.0;
    self[@"directionality"] = @(output.size.width / output.size.height);
  }
  return self;
}

- (void)setSeed:(CGFloat)seed {
  _seed = seed;
  self[[LTMultiscaleNoiseFsh seed]] = @(seed);
}

- (void)setDensity:(CGFloat)density {
  _density = density;
  self[[LTMultiscaleNoiseFsh density]] = @(density);
}

@end
