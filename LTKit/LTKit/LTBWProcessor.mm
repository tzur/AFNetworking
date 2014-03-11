// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWProcessor.h"

#import "LTBWTonalityProcessor.h"
#import "LTCGExtensions.h"
#import "LTColorGradient.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTBWProcessorFsh.h"
#import "LTShaderStorage+LTBWProcessorVsh.h"
#import "LTTexture+Factory.h"
// TODO: remove it.
#import "LTOneShotMultiscaleNoiseProcessor.h"

@interface LTBWProcessor ()

@property (strong, nonatomic) LTBWTonalityProcessor *toneProcessor;

@end

@implementation LTBWProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTBWProcessorVsh source]
                                                fragmentSource:[LTBWProcessorFsh source]];
  
  LTTexture *toneTexture = [LTTexture textureWithPropertiesOf:output];
  self.toneProcessor = [[LTBWTonalityProcessor alloc] initWithInput:input output:toneTexture];
  [self.toneProcessor process];
  
//  GLKMatrix3 scale = GLKMatrix3MakeScale(rect.size.width, rect.size.height, 1);
//  self[@"grainTexture"] = $(texture);
  
  // TODO:
  LTTexture *grainTexture = [LTTexture textureWithSize:CGSizeMake(128, 128)
      precision:LTTexturePrecisionByte format:LTTextureFormatRGBA allocateMemory:TRUE];
  grainTexture.wrap = LTTextureWrapRepeat;
  LTOneShotMultiscaleNoiseProcessor *fractionalNoise =
      [[LTOneShotMultiscaleNoiseProcessor alloc] initWithOutput:grainTexture];
  fractionalNoise.density = 10;
  [fractionalNoise process];
  //
  
  // TODO: Not fails on bad input and doesn't process on good one.
  self[@"grainScaling"] = @4.0;
  
  NSDictionary *auxiliaryTextures =
      @{[LTBWProcessorFsh grainTexture] : grainTexture,
        [LTBWProcessorFsh vignettingTexture] : input,
        [LTBWProcessorFsh frameTexture] : input};
  if (self = [super initWithProgram:program sourceTexture:toneTexture
                  auxiliaryTextures:auxiliaryTextures andOutput:output]) {
    // Setup the default parameters.
  }
  return self;
}

@end
