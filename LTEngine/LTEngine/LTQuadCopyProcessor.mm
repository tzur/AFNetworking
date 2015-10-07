// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadCopyProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTNextIterationPlacement.h"
#import "LTOneShotImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTProgramFactory.h"
#import "LTQuad.h"
#import "LTQuadDrawer.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture.h"

@implementation LTQuadCopyProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program =
      [[[self class] programFactory] programWithVertexSource:[LTPassthroughShaderVsh source]
                                              fragmentSource:[LTPassthroughShaderFsh source]];
  LTQuadDrawer *drawer = [[LTQuadDrawer alloc] initWithProgram:program sourceTexture:input];
  if (self = [super initWithDrawer:drawer sourceTexture:input auxiliaryTextures:nil
                         andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.inputQuad = [LTQuad quadFromRect:CGRectFromSize(self.inputTexture.size)];
  self.outputQuad = [LTQuad quadFromRect:CGRectFromSize(self.outputTexture.size)];
}

#pragma mark -
#pragma mark LTGPUImageProcessor
#pragma mark -

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement {
  [((LTQuadDrawer *)self.drawer) drawQuad:self.outputQuad inFramebuffer:placement.targetFbo
                                 fromQuad:self.inputQuad];
}

#pragma mark -
#pragma mark Screen processing
#pragma mark -

- (void)processToFramebufferWithSize:(CGSize)size outputRect:(CGRect)rect {
  [self preprocess];

  LTQuad *targetQuad = [self targetQuadFromQuad:self.outputQuad scaleFactor:size / rect.size
                                    translation:-1 * rect.origin];
  [((LTQuadDrawer *)self.drawer) drawQuad:targetQuad inFramebufferWithSize:size
                                 fromQuad:self.inputQuad];
}

- (LTQuad *)targetQuadFromQuad:(LTQuad *)quad scaleFactor:(CGSize)scaleFactor
                   translation:(CGPoint)translation {
  LTQuadCorners corners = quad.corners;
  std::transform(corners.begin(), corners.end(), corners.begin(),
                 [translation, scaleFactor](CGPoint corner) {
    return (corner + translation) * scaleFactor;
  });
  return [[LTQuad alloc] initWithCorners:corners];
}

@end
