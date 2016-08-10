// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalContentProviderParameters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRLocalContentProviderParameters

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
    @instanceKeypath(BZRLocalContentProviderParameters, URL): @"URL"
  }];
}

@end

NS_ASSUME_NONNULL_END
