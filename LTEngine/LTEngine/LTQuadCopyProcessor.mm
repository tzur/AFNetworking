// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadCopyProcessor.h"

#import "LTDynamicQuadDrawer.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTShaderStorage+LTPassthroughWithPerspectiveShaderFsh.h"
#import "LTShaderStorage+LTPassthroughWithPerspectiveShaderVsh.h"
#import "LTTexture.h"

@interface LTQuadCopyProcessor ()

/// Object used to render the copied quadrilateral region.
@property (readonly, nonatomic) LTDynamicQuadDrawer *drawer;

/// Input texture of the processor.
@property (strong, nonatomic) LTTexture *inputTexture;

/// Output texture of the processor.
@property (strong, nonatomic) LTTexture *outputTexture;

/// Framebuffer object used to update \c outputTexture.
@property (readonly, nonatomic) LTFbo *fbo;

/// Input quad in normalized coordinates.
@property (readonly, nonatomic) lt::Quad normalizedInputQuad;

/// Output quad in normalized coordinates.
@property (readonly, nonatomic) lt::Quad normalizedOutputQuad;

@end

@implementation LTQuadCopyProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super init]) {
    _drawer = [[LTDynamicQuadDrawer alloc]
               initWithVertexSource:[LTPassthroughWithPerspectiveShaderVsh source]
               fragmentSource:[LTPassthroughWithPerspectiveShaderFsh source]
               gpuStructs:[NSOrderedSet orderedSet]];
    _inputTexture = input;
    _outputTexture = output;
    _fbo = [[LTFboPool currentPool] fboWithTexture:self.outputTexture];

    [self resetInputModel];
  }
  return self;
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet<NSString *> *)inputModelPropertyKeys {
  static NSSet *properties;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTQuadCopyProcessor, inputQuad),
      @instanceKeypath(LTQuadCopyProcessor, outputQuad)
    ]];
  });

  return properties;
}

- (LTQuad *)defaultInputQuad {
  return [LTQuad quadFromRect:CGRectFromSize(self.inputTexture.size)];
}

- (LTQuad *)defaultOutputQuad {
  return [LTQuad quadFromRect:CGRectFromSize(self.outputTexture.size)];
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  [self.fbo bindAndDraw:^{
    [self copyNormalizedQuad:self.normalizedInputQuad toNormalizedQuad:self.normalizedOutputQuad];
  }];
}

- (void)copyNormalizedQuad:(lt::Quad)inputQuad toNormalizedQuad:(lt::Quad)outputQuad {
  [self.drawer drawQuads:{outputQuad} textureMapQuads:{inputQuad}
           attributeData:@[] texture:self.inputTexture auxiliaryTextures:@{}
                uniforms:@{}];
}

#pragma mark -
#pragma mark LTScreenProcessing
#pragma mark -

- (void)processToFramebufferWithSize:(__unused CGSize)size outputRect:(CGRect)rect {
  lt::Quad outputQuad =
      self.outputQuad.quad.translatedBy(-1 * rect.origin).scaledAround(1 / LTVector2(rect.size),
                                                                       CGPointZero);
  [self copyNormalizedQuad:self.normalizedInputQuad toNormalizedQuad:outputQuad];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setInputQuad:(LTQuad *)inputQuad {
  _inputQuad = inputQuad;
  _normalizedInputQuad = inputQuad.quad.scaledAround(1.0 / LTVector2(self.inputTexture.size),
                                                     CGPointZero);
}

- (void)setOutputQuad:(LTQuad *)outputQuad {
  _outputQuad = outputQuad;
  _normalizedOutputQuad = outputQuad.quad.scaledAround(1.0 / LTVector2(self.outputTexture.size),
                                                       CGPointZero);
}

@end
