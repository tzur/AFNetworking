// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNRenderStageConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNRenderStageConfiguration

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource {
  return [self initWithVertexSource:vertexSource fragmentSource:fragmentSource auxiliaryTextures:@{}
                           uniforms:@{}];
}

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                   auxiliaryTextures:(NSDictionary<NSString *, LTTexture *> *)auxiliaryTextures
                            uniforms:(NSDictionary<NSString *, NSValue *> *)uniforms {
  if (self = [super init]) {
    _vertexSource = vertexSource;
    _fragmentSource = fragmentSource;
    _auxiliaryTextures = [auxiliaryTextures copy];
    _uniforms = [uniforms copy];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
