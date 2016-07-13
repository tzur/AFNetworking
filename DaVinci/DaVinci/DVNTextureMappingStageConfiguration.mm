// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNTextureMappingStageConfiguration.h"

#import <LTEngine/LTTexture.h>

#import "DVNTexCoordProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNTextureMappingStageConfiguration

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithTexCoordProviderModel:(id<DVNTexCoordProviderModel>)texCoordProviderModel
                                      texture:(LTTexture *)texture {
  LTParameterAssert(texCoordProviderModel);
  LTParameterAssert(texture);

  if (self = [super init]) {
    _texCoordProviderModel = texCoordProviderModel;
    _texture = texture;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNTextureMappingStageConfiguration *)configuration {
  if (self == configuration) {
    return YES;
  }

  if (![configuration isKindOfClass:[DVNTextureMappingStageConfiguration class]]) {
    return NO;
  }

  return [self.texCoordProviderModel isEqual:configuration.texCoordProviderModel] &&
      [self.texture isEqual:configuration.texture];
}

- (NSUInteger)hash {
  return self.texCoordProviderModel.hash;
}

@end

NS_ASSUME_NONNULL_END
