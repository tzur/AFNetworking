// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTOneShotProcessingStrategy.h"
#import "LTRectDrawer.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) id<LTProcessingDrawer> drawer;
@end

@interface LTOneShotImageProcessor ()

/// Output texture of the processor.
@property (strong, nonatomic) LTTexture *outputTexture;

/// Input texture of the processor.
@property (strong, nonatomic) LTTexture *inputTexture;

@end

@implementation LTOneShotImageProcessor

- (instancetype)initWithProgram:(LTProgram *)program input:(LTTexture *)input
                      andOutput:(LTTexture *)output {
  return [self initWithProgram:program sourceTexture:input auxiliaryTextures:nil andOutput:output];
}

- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)sourceTexture
              auxiliaryTextures:(NSDictionary *)auxiliaryTextures andOutput:(LTTexture *)output {
  self.inputTexture = sourceTexture;
  self.outputTexture = output;

  LTOneShotProcessingStrategy *strategy = [[LTOneShotProcessingStrategy alloc]
                                           initWithInput:sourceTexture andOutput:output];
  LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithProgram:program
                                                     sourceTexture:sourceTexture];
  return [super initWithDrawer:rectDrawer strategy:strategy andAuxiliaryTextures:auxiliaryTextures];
}

- (void)processToFramebufferWithSize:(CGSize)size outputRect:(CGRect)rect {
  [self processWithPlacement:^(LTNextIterationPlacement *placement) {
    [self.drawer setSourceTexture:placement.sourceTexture];

    // Drawing from a subrect of the input to the entire framebuffer.
    CGRect sourceRect = CGRectFromSize(placement.sourceTexture.size);
    CGRect targetRect = [self targetRectForFramebufferSize:size outputRect:rect
                                                 placement:placement];

    [self.drawer drawRect:targetRect inFramebufferWithSize:size fromRect:sourceRect];
  }];
}

- (CGRect)targetRectForFramebufferSize:(CGSize)framebufferSize outputRect:(CGRect)rect
                             placement:(LTNextIterationPlacement *)placement {
  // Since we're drawing the entire source to the target while possibly clipping stuff that doesn't
  // fit into the framebuffer, we need to do two things:
  // 1. Invert the current translation, because for output rect of positive origin, we'd like the
  //    point (0, 0) of the source texture to be drawn outside the framebuffer bounds, therefore
  //    we'd like it to be on a negative origin.
  // 2. Match the scaling differences between the current framebuffer size and the original
  //    framebuffer. The ratio is better understood as (framebufferSize / placement.targetFbo.size)
  //    * (placement.targetFbo.size / rect.size). Where the first is the ratio between the sizes
  //    of the framebuffers and the second is the scaling ratio between the framebuffer size and the
  //    size of the rect we're drawing to (see \c size calculation).
  CGPoint origin = -1 * rect.origin * (framebufferSize / rect.size);

  // Size is calculated by measuring the ratio between the original framebuffer size and the rect
  // we're drawing to, and applying this factor to the framebuffer size we're rendering into.
  CGSize size = framebufferSize * (placement.targetFbo.size / rect.size);

  return CGRectFromOriginAndSize(origin, size);
}

- (CGSize)inputSize {
  return self.inputTexture.size;
}

- (CGSize)outputSize {
  return self.outputTexture.size;
}

@end
