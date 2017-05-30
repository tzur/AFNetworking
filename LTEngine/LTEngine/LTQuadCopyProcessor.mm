// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadCopyProcessor.h"

#import "LTDynamicQuadDrawer.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture.h"

@interface LTQuadCopyProcessor ()

/// Drawer.
@property (readonly, nonatomic) LTDynamicQuadDrawer *drawer;

/// Input texture of the processor.
@property (strong, nonatomic) LTTexture *inputTexture;

/// Output texture of the processor.
@property (strong, nonatomic) LTTexture *outputTexture;

@end

@implementation LTQuadCopyProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super init]) {
    _drawer = [[LTDynamicQuadDrawer alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                                 fragmentSource:[LTPassthroughShaderFsh source]
                                                     gpuStructs:[NSOrderedSet orderedSet]];
    _inputTexture = input;
    _outputTexture = output;

    [self resetInputModel];
  }
  return self;
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
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

- (void)copyNormalizedQuad:(lt::Quad)inputQuad toNormalizedQuad:(lt::Quad)outputQuad {
  [self.drawer drawQuads:{outputQuad} textureMapQuads:{inputQuad}
           attributeData:@[] texture:self.inputTexture auxiliaryTextures:@{}
                uniforms:@{[LTPassthroughShaderVsh modelview]: $(GLKMatrix4Identity),
                           [LTPassthroughShaderVsh texture]: $(GLKMatrix3Identity)}];
}

- (void)preprocess {
  LTFbo *fbo = [[LTFboPool currentPool] fboWithTexture:self.outputTexture];
  [fbo bindAndDraw:^{
    lt::Quad inputQuad =
        self.inputQuad.quad.scaledAround(1.0 / LTVector2(self.inputTexture.size), CGPointZero);
    lt::Quad outputQuad =
        self.outputQuad.quad.scaledAround(1.0 / LTVector2(self.outputTexture.size), CGPointZero);
    [self copyNormalizedQuad:inputQuad toNormalizedQuad:outputQuad];
  }];
}

- (void)process {
  [self preprocess];
}

#pragma mark -
#pragma mark Screen processing
#pragma mark -

- (void)processToFramebufferWithSize:(__unused CGSize)size outputRect:(CGRect)rect {
  lt::Quad inputQuad =
      self.inputQuad.quad.scaledAround(1 / LTVector2(self.inputTexture.size), CGPointZero);
  lt::Quad outputQuad =
      self.outputQuad.quad.translatedBy(-1 * rect.origin).scaledAround(1 / LTVector2(rect.size),
                                                                       CGPointZero);
  [self copyNormalizedQuad:inputQuad toNormalizedQuad:outputQuad];
}

- (lt::Quad)targetQuadFromQuad:(lt::Quad)quad scaleFactor:(CGSize)scaleFactor
                   translation:(CGPoint)translation {
  LTQuadCorners corners = quad.corners();
  std::transform(corners.begin(), corners.end(), corners.begin(),
                 [translation, scaleFactor](CGPoint corner) {
                   return (corner + translation) * scaleFactor;
                 });
  return [[LTQuad alloc] initWithCorners:corners].quad;
}
@end
