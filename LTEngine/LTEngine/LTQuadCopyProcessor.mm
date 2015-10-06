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
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTQuadCopyFsh.h"
#import "LTTexture.h"

@implementation LTQuadCopyProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {

  LTProgram *program =
      [[[self class] programFactory] programWithVertexSource:[LTPassthroughShaderVsh source]
                                              fragmentSource:[LTQuadCopyFsh source]];
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
  self[[LTQuadCopyFsh useAlphaValues]] = @NO;
}

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement {
  [((LTQuadDrawer *)self.drawer) drawQuad:self.outputQuad inFramebuffer:placement.targetFbo
                                 fromQuad:self.inputQuad];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setUseAlphaValues:(BOOL)useAlphaValues {
  _useAlphaValues = useAlphaValues;
  self[[LTQuadCopyFsh useAlphaValues]] = @(useAlphaValues);
}

@end
