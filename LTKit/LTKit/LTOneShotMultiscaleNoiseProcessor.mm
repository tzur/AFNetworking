// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotMultiscaleNoiseProcessor.h"

#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTOneShotMultiscaleNoiseFsh.h"
#import "LTTexture.h"

@implementation LTOneShotMultiscaleNoiseProcessor

- (instancetype)initWithOutput:(LTTexture *)output {
  if (self = [super initWithProgram:[self createProgram] sourceTexture:output auxiliaryTextures:nil
                          andOutput:output]) {
    self.seed = 0.0;
    self.density = 2.0;
    self.directionality = output.size.width / output.size.height;
  }
  return self;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                  fragmentSource:[LTOneShotMultiscaleNoiseFsh source]];
}

- (void)setSeed:(CGFloat)seed {
  _seed = seed;
  self[@"seed"] = @(seed);
}

- (void)setDensity:(CGFloat)density {
  _density = density;
  self[@"density"] = @(density);
}

- (void)setDirectionality:(CGFloat)directionality {
  _directionality = directionality;
  self[@"directionality"] = @(directionality);
}

@end
