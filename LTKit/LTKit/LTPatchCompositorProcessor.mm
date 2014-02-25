// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchCompositorProcessor.h"

#import "LTCGExtensions.h"
#import "LTNextIterationPlacement.h"
#import "LTProgram.h"
#import "LTRectMapping.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTPatchCompositorFsh.h"
#import "LTShaderStorage+LTPatchCompositorVsh.h"
#import "LTTexture.h"

@interface LTGPUImageProcessor ()

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement;

@property (strong, nonatomic) id<LTProcessingDrawer> drawer;
@property (strong, nonatomic) id<LTProcessingStrategy> strategy;

@end

@interface LTPatchCompositorProcessor ()
@property (strong, nonatomic) LTTexture *target;
@end

@implementation LTPatchCompositorProcessor

- (instancetype)initWithSource:(LTTexture *)source target:(LTTexture *)target
                      membrane:(LTTexture *)membrane mask:(LTTexture *)mask
                        output:(LTTexture *)output {
  LTParameterAssert(target.size == output.size,
                    @"Target and output textures should have the same size");
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTPatchCompositorVsh source]
                                                fragmentSource:[LTPatchCompositorFsh source]];
  NSDictionary *auxiliaryTextures = @{
    [LTPatchCompositorFsh targetTexture]: target,
    [LTPatchCompositorFsh membraneTexture]: membrane,
    [LTPatchCompositorFsh maskTexture]: mask
  };
  if (self = [super initWithProgram:program sourceTexture:source
                  auxiliaryTextures:auxiliaryTextures andOutput:output]) {
    self.target = target;
  }
  return self;
}

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement {
  [self.drawer drawRotatedRect:self.targetRect inFramebuffer:placement.targetFbo
               fromRotatedRect:self.sourceRect];
}

- (void)setTargetRect:(LTRotatedRect *)targetRect {
  _targetRect = targetRect;

  GLKMatrix3 targetTextureMat = LTTextureMatrix3ForRotatedRect(targetRect, self.target.size);
  self[[LTPatchCompositorVsh targetTextureMat]] = $(targetTextureMat);
}

@end
