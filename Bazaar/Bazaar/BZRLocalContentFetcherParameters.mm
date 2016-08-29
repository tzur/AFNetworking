// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalContentFetcherParameters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRLocalContentFetcherParameters

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
    @instanceKeypath(BZRLocalContentFetcherParameters, URL): @"URL"
  }];
}

@end

NS_ASSUME_NONNULL_END
