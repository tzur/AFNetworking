// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentMultiFetcherParameters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProductContentMultiFetcherParameters

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
    @instanceKeypath(BZRProductContentMultiFetcherParameters, contentFetcherName):
        @"contentFetcherName",
    @instanceKeypath(BZRProductContentMultiFetcherParameters, parametersForContentFetcher):
        @"parametersForContentFetcher"
  }];
}

+ (NSValueTransformer *)parametersForContentFetcherJSONTransformer {
  return [NSValueTransformer
          mtl_JSONDictionaryTransformerWithModelClass:[BZRContentFetcherParameters class]];
}

#pragma mark -
#pragma mark BZRModel
#pragma mark -

+ (NSSet<NSString *> *)optionalPropertyKeys {
  static NSSet<NSString *> *optionalPropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    optionalPropertyKeys = [NSSet setWithArray:@[
      @instanceKeypath(BZRProductContentMultiFetcherParameters, parametersForContentFetcher)
    ]];
  });

  return optionalPropertyKeys;
}

@end

NS_ASSUME_NONNULL_END
