// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectCopyProcessor.h"

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTMathUtils.h"
#import "LTNextIterationPlacement.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTRectCopyFsh.h"
#import "LTTexture.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) id<LTProcessingDrawer> drawer;
@property (strong, nonatomic) id<LTProcessingStrategy> strategy;
@end

@interface LTRectCopyProcessor ()

/// Input texture.
@property (strong, nonatomic) LTTexture *input;

/// Output texture.
@property (strong, nonatomic) LTTexture *output;

@end

@implementation LTRectCopyProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                                fragmentSource:[LTRectCopyFsh source]];
  if (self = [super initWithProgram:program input:input andOutput:output]) {
    self.input = input;
    self.output = output;
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.inputRect = [LTRotatedRect rect:CGRectFromOriginAndSize(CGPointZero, self.input.size)];
  self.outputRect = [LTRotatedRect rect:CGRectFromOriginAndSize(CGPointZero, self.output.size)];
  self.texturingMode = LTRectCopyTexturingModeStretch;
}

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement {
  [self.drawer drawRotatedRect:self.outputRect inFramebuffer:placement.targetFbo
               fromRotatedRect:self.inputRect];
}

- (id<LTImageProcessorOutput>)process {
  switch (self.texturingMode) {
    case LTRectCopyTexturingModeStretch:
      return [super process];
    case LTRectCopyTexturingModeTile:
      return [self processTileTexturingMode];
  }
}

- (id<LTImageProcessorOutput>)processTileTexturingMode {
  CGSize scalingFactor = self.outputRect.rect.size / self.inputRect.rect.size;
  self[[LTRectCopyFsh scaling]] = $(GLKVector2Make(scalingFactor.width, scalingFactor.height));

  // Create to / from rotated rect coordinates transform matrices.
  GLKVector2 vx = [self directionVectorFromFirstPoint:self.inputRect.v0
                                          secondPoint:self.inputRect.v1];
  GLKVector2 vy = [self directionVectorFromFirstPoint:self.inputRect.v0
                                          secondPoint:self.inputRect.v3];
  GLKMatrix2 toRotatedRect = GLKMatrix2Make(vx.x, vy.x, vx.y, vy.y);
  GLKMatrix2 fromRotatedRect = GLKMatrix2Transpose(toRotatedRect);
  self[[LTRectCopyFsh toRotatedRect]] = $(toRotatedRect);
  self[[LTRectCopyFsh fromRotatedRect]] = $(fromRotatedRect);

  GLKVector2 origin = GLKVector2Make(self.inputRect.v0.x / self.inputSize.width,
                                     self.inputRect.v0.y / self.inputSize.height);
  self[[LTRectCopyFsh origin]] = $(origin);

  GLKVector2 size = GLKVector2Make(self.inputRect.rect.size.width / self.inputSize.width,
                                   self.inputRect.rect.size.height / self.inputSize.height);
  self[[LTRectCopyFsh size]] = $(size);

  return [super process];
}

- (GLKVector2)directionVectorFromFirstPoint:(CGPoint)first secondPoint:(CGPoint)second {
  GLKVector2 direction = GLKVector2Make((second.x - first.x) / self.inputSize.width,
                                        (second.y - first.y) / self.inputSize.height);
  return GLKVector2Normalize(direction);
}

- (void)setTexturingMode:(LTRectCopyTexturingMode)texturingMode {
  _texturingMode = texturingMode;
  self[[LTRectCopyFsh texturingMode]] = @(texturingMode);
}

@end
