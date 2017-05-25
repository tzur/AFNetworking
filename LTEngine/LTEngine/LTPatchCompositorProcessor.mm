// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchCompositorProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTNextIterationPlacement.h"
#import "LTOneShotImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTProgramFactory.h"
#import "LTQuad.h"
#import "LTQuadDrawer.h"
#import "LTQuadMapping.h"
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
  LTProgram *program =
      [[[self class] programFactory] programWithVertexSource:[LTPatchCompositorVsh source]
                                              fragmentSource:[LTPatchCompositorFsh source]];
  NSDictionary *auxiliaryTextures = @{
    [LTPatchCompositorFsh targetTexture]: target,
    [LTPatchCompositorFsh membraneTexture]: membrane,
    [LTPatchCompositorFsh maskTexture]: mask
  };
  LTQuadDrawer *drawer = [[LTQuadDrawer alloc] initWithProgram:program sourceTexture:source
                                             auxiliaryTextures:auxiliaryTextures];
  if (self = [super initWithDrawer:drawer sourceTexture:source auxiliaryTextures:auxiliaryTextures
                         andOutput:output]) {
    self.source = source;
    self.target = target;
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.sourceQuad = [LTQuad quadFromRect:CGRectFromSize(self.source.size)];
  self.targetQuad = [LTQuad quadFromRect:CGRectFromSize(self.target.size)];
  self.sourceOpacity = self.defaultSourceOpacity;
  self.flip = NO;
  self.smoothingAlpha = self.defaultSmoothingAlpha;
}

#pragma mark -
#pragma mark LTGPUImageProcessor
#pragma mark -

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement {
  [((LTQuadDrawer *)self.drawer) drawQuad:self.targetQuad inFramebuffer:placement.targetFbo
                                 fromQuad:self.sourceQuad];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setTargetQuad:(LTQuad *)targetQuad {
  _targetQuad = targetQuad;

  GLKMatrix3 targetTextureMat = LTTextureMatrix3ForQuad(targetQuad, self.target.size);
  self[[LTPatchCompositorFsh targetTextureMat]] = $(targetTextureMat);
}

- (void)setSourceQuad:(LTQuad *)sourceQuad {
  _sourceQuad = sourceQuad;

  GLKMatrix3 sourceTextureMat = LTTextureMatrix3ForQuad(sourceQuad, self.source.size);
  self[[LTPatchCompositorFsh sourceTextureMat]] = $(sourceTextureMat);
}

LTPropertyWithoutSetter(CGFloat, sourceOpacity, SourceOpacity, 0, 1, 1);
- (void)setSourceOpacity:(CGFloat)sourceOpacity {
  [self _verifyAndSetSourceOpacity:sourceOpacity];
  self[[LTPatchCompositorFsh sourceOpacity]] = @(sourceOpacity);
}

- (void)setFlip:(BOOL)flip {
  _flip = flip;
  self[[LTPatchCompositorVsh flipSourceTextureCoordinates]] = @(flip);
}

LTPropertyWithoutSetter(CGFloat, smoothingAlpha, SmoothingAlpha, 0, 1, 1);
- (void)setSmoothingAlpha:(CGFloat)smoothingAlpha {
  [self _verifyAndSetSmoothingAlpha:smoothingAlpha];
  self[[LTPatchCompositorFsh smoothingAlpha]] = @(smoothingAlpha);
}

@end
