// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchCompositorProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTNextIterationPlacement.h"
#import "LTOneShotImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTRectMapping.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTPatchCompositorFsh.h"
#import "LTShaderStorage+LTPatchCompositorVsh.h"
#import "LTTexture.h"

@interface LTPatchCompositorProcessor ()
@property (strong, nonatomic) LTTexture *source;
@property (strong, nonatomic) LTTexture *target;
@end

@implementation LTPatchCompositorProcessor

- (instancetype)initWithSource:(LTTexture *)source target:(LTTexture *)target
                      membrane:(LTTexture *)membrane mask:(LTTexture *)mask
                        output:(LTTexture *)output {
  LTParameterAssert(target.size == output.size,
                    @"Target and output textures should have the same size");
  NSDictionary *auxiliaryTextures = @{
    [LTPatchCompositorFsh targetTexture]: target,
    [LTPatchCompositorFsh membraneTexture]: membrane,
    [LTPatchCompositorFsh maskTexture]: mask
  };
  if (self = [super initWithVertexSource:[LTPatchCompositorVsh source]
                          fragmentSource:[LTPatchCompositorFsh source] sourceTexture:source
                       auxiliaryTextures:auxiliaryTextures andOutput:output]) {
    self.source = source;
    self.target = target;
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.sourceRect = [LTRotatedRect rect:CGRectFromOriginAndSize(CGPointZero, self.source.size)];
  self.targetRect = [LTRotatedRect rect:CGRectFromOriginAndSize(CGPointZero, self.target.size)];
  self.sourceOpacity = self.defaultSourceOpacity;
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

LTPropertyWithoutSetter(CGFloat, sourceOpacity, SourceOpacity, 0, 1, 1);
- (void)setSourceOpacity:(CGFloat)sourceOpacity {
  [self _verifyAndSetSourceOpacity:sourceOpacity];
  self[[LTPatchCompositorFsh sourceOpacity]] = @(sourceOpacity);
}

@end
