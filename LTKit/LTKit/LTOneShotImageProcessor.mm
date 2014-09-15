// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor+Protected.h"

#import "LTCGExtensions.h"
#import "LTGLContext.h"
#import "LTFbo.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTOneShotProcessingStrategy.h"
#import "LTProgramFactory.h"
#import "LTRectDrawer.h"

@interface LTOneShotImageProcessor ()

/// Output texture of the processor.
@property (strong, nonatomic) LTTexture *outputTexture;

/// Input texture of the processor.
@property (strong, nonatomic) LTTexture *inputTexture;

@end

@implementation LTOneShotImageProcessor

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                               input:(LTTexture *)input andOutput:(LTTexture *)output {
  return [self initWithVertexSource:vertexSource fragmentSource:fragmentSource
                      sourceTexture:input auxiliaryTextures:nil andOutput:output];
}

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                       sourceTexture:(LTTexture *)sourceTexture
                   auxiliaryTextures:(NSDictionary *)auxiliaryTextures
                           andOutput:(LTTexture *)output {
  self.inputTexture = sourceTexture;
  self.outputTexture = output;

  LTOneShotProcessingStrategy *strategy = [[LTOneShotProcessingStrategy alloc]
                                           initWithInput:sourceTexture andOutput:output];
  LTProgram *program = [[[self class] programFactory] programWithVertexSource:vertexSource
                                                               fragmentSource:fragmentSource];
  LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithProgram:program
                                                     sourceTexture:sourceTexture];
  return [super initWithDrawer:rectDrawer strategy:strategy andAuxiliaryTextures:auxiliaryTextures];
}

- (void)processToFramebufferWithSize:(CGSize)size outputRect:(CGRect)rect {
  [self preprocess];

  [self processWithPlacement:^(LTNextIterationPlacement *placement) {
    [self.drawer setSourceTexture:placement.sourceTexture];

    // Drawing from a subrect of the input to the entire framebuffer.
    CGRect sourceRect = [self sourceRectForFramebufferSize:size outputRect:rect
                                         sourceTextureSize:placement.sourceTexture.size];
    CGRect targetRect = [self targetRectForFramebufferSize:size outputRect:rect
                                   originalFramebufferSize:placement.targetFbo.size];

    [self.drawer drawRect:targetRect inFramebufferWithSize:size fromRect:sourceRect];
  }];
}

- (CGRect)sourceRectForFramebufferSize:(__unused CGSize)framebufferSize
                            outputRect:(__unused CGRect)rect sourceTextureSize:(CGSize)size {
  return CGRectFromSize(size);
}

- (CGRect)targetRectForFramebufferSize:(CGSize)framebufferSize outputRect:(CGRect)rect
               originalFramebufferSize:(CGSize)originalFramebufferSize {
  // Since we're drawing the entire source to the target while possibly clipping stuff that doesn't
  // fit into the framebuffer, we need to do two things:
  // 1. Invert the current translation, because for output rect of positive origin, we'd like the
  //    point (0, 0) of the source texture to be drawn outside the framebuffer bounds, therefore
  //    we'd like it to be on a negative origin.
  // 2. Match the scaling differences between the current framebuffer size and the original
  //    framebuffer. The ratio is better understood as (framebufferSize / originalFramebufferSize)
  //    * (originalFramebufferSize / rect.size). Where the first is the ratio between the sizes
  //    of the framebuffers and the second is the scaling ratio between the framebuffer size and the
  //    size of the rect we're drawing to (see \c size calculation).
  CGPoint origin = -1 * rect.origin * (framebufferSize / rect.size);

  // Size is calculated by measuring the ratio between the original framebuffer size and the rect
  // we're drawing to, and applying this factor to the framebuffer size we're rendering into.
  CGSize size = framebufferSize * (originalFramebufferSize / rect.size);

  return CGRectFromOriginAndSize(origin, size);
}

- (void)processInRect:(CGRect)rect {
  [self preprocess];
  
  [self processWithPlacement:^(LTNextIterationPlacement *placement) {
    [self.drawer setSourceTexture:placement.sourceTexture];

    CGSize ratio = placement.sourceTexture.size / placement.targetFbo.size;
    CGRect sourceRect = CGRectFromOriginAndSize(rect.origin * ratio, rect.size * ratio);

    [self.drawer drawRect:rect inFramebuffer:placement.targetFbo fromRect:sourceRect];
  }];
}

- (CGSize)inputSize {
  return self.inputTexture.size;
}

- (CGSize)outputSize {
  return self.outputTexture.size;
}

@end
