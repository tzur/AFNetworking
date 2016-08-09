// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentMultiProviderParameters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProductContentMultiProviderParameters

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRProductContentMultiProviderParameters, contentProviderName):
        @"contentProviderName",
    @instanceKeypath(BZRProductContentMultiProviderParameters, parametersForContentProvider):
        @"parametersForContentProvider"
  };
}

#pragma mark -
#pragma mark BZRModel
#pragma mark -

+ (NSSet<NSString *> *)nullablePropertyKeys {
  static NSSet<NSString *> *nullablePropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nullablePropertyKeys = [NSSet setWithArray:@[
      @instanceKeypath(BZRProductContentMultiProviderParameters, parametersForContentProvider)
    ]];
  });
  
  return nullablePropertyKeys;
}

@end

NS_ASSUME_NONNULL_END
