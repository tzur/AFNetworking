// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNAttributeStageConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNAttributeStageConfiguration

- (instancetype)init {
  return [self initWithAttributeProviderModels:@[]];
}

- (instancetype)initWithAttributeProviderModels:(NSArray<id<DVNAttributeProviderModel>> *)models {
  LTParameterAssert(models);
  if (self = [super init]) {
    _attributeProviderModels = [models copy];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
