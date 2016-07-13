// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNAttributeStageConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNAttributeStageConfiguration

#pragma mark -
#pragma mark Initialization
#pragma mark -

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

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNAttributeStageConfiguration *)configuration {
  if (self == configuration) {
    return YES;
  }

  if (![configuration isKindOfClass:[DVNAttributeStageConfiguration class]]) {
    return NO;
  }

  return [self.attributeProviderModels isEqualToArray:configuration.attributeProviderModels];
}

- (NSUInteger)hash {
  return self.attributeProviderModels.hash;
}

@end

NS_ASSUME_NONNULL_END
