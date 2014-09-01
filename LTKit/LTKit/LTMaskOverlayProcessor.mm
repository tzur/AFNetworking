// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMaskOverlayProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTMaskOverlayFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"

@implementation LTMaskOverlayProcessor

- (instancetype)initWithImage:(LTTexture *)image mask:(LTTexture *)mask output:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTMaskOverlayFsh source]
                           sourceTexture:image
                       auxiliaryTextures:@{[LTMaskOverlayFsh maskTexture]: mask}
                               andOutput:output]) {
    self.maskColor = LTVector4(1.0, 0.0, 0.0, 0.5);
  }
  return self;
}

- (void)setMaskColor:(LTVector4)maskColor {
  _maskColor = maskColor;
  self[[LTMaskOverlayFsh maskColor]] = $(maskColor);
}

@end
