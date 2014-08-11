// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchBoundaryProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTPatchBoundaryFsh.h"
#import "LTShaderStorage+LTPatchBoundaryVsh.h"
#import "LTTexture.h"

@interface LTPatchBoundaryProcessor ()

@property (strong, nonatomic) LTTexture *input;
@property (strong, nonatomic) LTTexture *output;

@property (nonatomic) GLKVector2 texelOffset;

@end

@implementation LTPatchBoundaryProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPatchBoundaryVsh source]
                          fragmentSource:[LTPatchBoundaryFsh source]
                                   input:input andOutput:output]) {
    self.input = input;
    self.output = output;
    self.texelOffset = GLKVector2Make(1.0 / input.size.width, 1.0 / input.size.height);
    self.threshold = self.defaultThreshold;
  }
  return self;
}

- (void)setTexelOffset:(GLKVector2)texelOffset {
  _texelOffset = texelOffset;
  self[[LTPatchBoundaryVsh texelOffset]] = $(texelOffset);
}

LTPropertyWithoutSetter(CGFloat, threshold, Threshold, 0, 1, 0);
- (void)setThreshold:(CGFloat)threshold {
  [self _verifyAndSetThreshold:threshold];
  self[[LTPatchBoundaryFsh threshold]] = @(threshold);
}

@end
