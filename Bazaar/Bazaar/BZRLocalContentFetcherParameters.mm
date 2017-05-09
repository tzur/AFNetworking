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

+ (NSValueTransformer *)URLJSONTransformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:^NSURL *(NSString *string) {
    return [NSURL URLWithString:string];
  } reverseBlock:^NSString *(NSURL *URL) {
    return URL.absoluteString;
  }];
}

@end

NS_ASSUME_NONNULL_END
