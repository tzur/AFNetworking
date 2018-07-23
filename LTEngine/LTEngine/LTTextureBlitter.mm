// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTextureBlitter.h"

#import "LTDynamicQuadDrawer.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTTextureBlitter ()

/// Internally used drawer.
@property (readonly, nonatomic) LTDynamicQuadDrawer *drawer;

@end

@implementation LTTextureBlitter

- (instancetype)init {
  if (self = [super init]) {
    _drawer = [[LTDynamicQuadDrawer alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                                 fragmentSource:[LTPassthroughShaderFsh source]
                                                     gpuStructs:[NSOrderedSet orderedSet]];
  }
  return self;
}

- (void)copyTexture:(LTTexture *)texture toNormalizedRect:(CGRect)rect {
  static const CGRect kCanonicalRect = CGRectFromSize(CGSizeMakeUniform(1));
  [self copyNormalizedRect:kCanonicalRect ofTexture:texture toNormalizedRect:rect];
}

- (void)copyNormalizedRect:(CGRect)rect ofTexture:(LTTexture *)texture
          toNormalizedRect:(CGRect)targetRect {
  static NSDictionary<NSString *, NSValue *> * const kUniforms = @{
    [LTPassthroughShaderVsh modelview]: $(GLKMatrix4Identity),
    [LTPassthroughShaderVsh texture]: $(GLKMatrix3Identity)
  };
  [self.drawer drawQuads:{lt::Quad(targetRect)} textureMapQuads:{lt::Quad(rect)}
           attributeData:@[] texture:texture auxiliaryTextures:@{} uniforms:kUniforms];
}

- (void)copyNormalizedRect:(CGRect)rect ofTexture:(LTTexture *)sourceTexture
          toNormalizedRect:(CGRect)targetRect ofTexture:(LTTexture *)targetTexture {
  LTFbo *fbo = [[LTFboPool currentPool] fboWithTexture:targetTexture];
  [fbo bindAndDraw:^{
    [self copyNormalizedRect:rect ofTexture:sourceTexture toNormalizedRect:targetRect];
  }];
}

- (void)copyTexture:(LTTexture *)sourceTexture toRect:(CGRect)rect
          ofTexture:(LTTexture *)targetTexture {
  [self copyRect:CGRectFromSize(sourceTexture.size) ofTexture:sourceTexture toRect:rect
       ofTexture:targetTexture];
}

- (void)copyRect:(CGRect)rect ofTexture:(LTTexture *)sourceTexture toRect:(CGRect)targetRect
       ofTexture:(LTTexture *)targetTexture {
  rect.origin = rect.origin / sourceTexture.size;
  rect.size = rect.size / sourceTexture.size;
  targetRect.origin = targetRect.origin / targetTexture.size;
  targetRect.size = targetRect.size / targetTexture.size;
  [self copyNormalizedRect:rect ofTexture:sourceTexture toNormalizedRect:targetRect
                 ofTexture:targetTexture];
}

@end

NS_ASSUME_NONNULL_END
