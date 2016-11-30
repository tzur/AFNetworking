// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTexture+RectCopying.h"

#import "LTDynamicQuadDrawer.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTTexture (RectCopying)

static const CGRect kCanonicalRect = CGRectFromSize(CGSizeMakeUniform(1));

- (void)copyToNormalizedRect:(CGRect)rect {
  [self copyNormalizedRect:kCanonicalRect toNormalizedRect:rect];
}

- (void)copyNormalizedRect:(CGRect)rect toNormalizedRect:(CGRect)targetRect {
  LTDynamicQuadDrawer *drawer =
      [[LTDynamicQuadDrawer alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                         fragmentSource:[LTPassthroughShaderFsh source]
                                             gpuStructs:[NSOrderedSet orderedSet]];
  [drawer drawQuads:{lt::Quad(targetRect)} textureMapQuads:{lt::Quad(rect)} attributeData:@[]
            texture:self auxiliaryTextures:@{}
           uniforms:@{[LTPassthroughShaderVsh modelview]: $(GLKMatrix4Identity),
                      [LTPassthroughShaderVsh texture]: $(GLKMatrix3Identity)}];
}

- (void)copyNormalizedRect:(CGRect)rect toNormalizedRect:(CGRect)targetRect
                 ofTexture:(LTTexture *)texture {
  LTFbo *fbo = [[LTFboPool currentPool] fboWithTexture:texture];
  [fbo bindAndDraw:^{
    [self copyNormalizedRect:rect toNormalizedRect:targetRect];
  }];
}

- (void)copyToRect:(CGRect)rect ofTexture:(LTTexture *)texture {
  [self copyRect:CGRectFromSize(self.size) toRect:rect ofTexture:texture];
}

- (void)copyRect:(CGRect)rect toRect:(CGRect)targetRect ofTexture:(LTTexture *)texture {
  rect.origin = rect.origin / self.size;
  rect.size = rect.size / self.size;
  targetRect.origin = targetRect.origin / texture.size;
  targetRect.size = targetRect.size / texture.size;
  [self copyNormalizedRect:rect toNormalizedRect:targetRect ofTexture:texture];
}

@end

NS_ASSUME_NONNULL_END
