// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectCopyProcessor.h"

#import "LTCGExtensions.h"
#import "LTNextIterationPlacement.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
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
                                                fragmentSource:[LTPassthroughShaderFsh source]];
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
}

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement {
  [self.drawer drawRotatedRect:self.outputRect inFramebuffer:placement.targetFbo
               fromRotatedRect:self.inputRect];
}

@end
