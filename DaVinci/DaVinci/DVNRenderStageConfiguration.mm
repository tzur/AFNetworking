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

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNRenderStageConfiguration *)configuration {
  if (self == configuration) {
    return YES;
  }

  if (![configuration isKindOfClass:[DVNRenderStageConfiguration class]]) {
    return NO;
  }

  return [self.vertexSource isEqual:configuration.vertexSource] &&
      [self.fragmentSource isEqual:configuration.fragmentSource] &&
      [self.auxiliaryTextures isEqual:configuration.auxiliaryTextures] &&
      [self.uniforms isEqual:configuration.uniforms];
}

- (NSUInteger)hash {
  return self.vertexSource.hash ^ self.fragmentSource.hash ^ self.uniforms.hash;
}

#pragma mark -
#pragma mark Public API
#pragma mark -

- (instancetype)copyWithAuxiliaryTextures:(NSDictionary<NSString *, LTTexture *> *)auxiliaryTextures
                                 uniforms:(NSDictionary<NSString *, NSValue *> *)uniforms {
  return [[[self class] alloc] initWithVertexSource:self.vertexSource
                                     fragmentSource:self.fragmentSource
                                  auxiliaryTextures:auxiliaryTextures uniforms:uniforms];
}

@end

NS_ASSUME_NONNULL_END
