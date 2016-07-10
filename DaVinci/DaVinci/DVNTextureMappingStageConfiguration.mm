// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNTextureMappingStageConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNTextureMappingStageConfiguration

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

@end

NS_ASSUME_NONNULL_END
