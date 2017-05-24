// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRContentFetcherParameters.h"

#import "BZRProductContentFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRContentFetcherParameters

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRContentFetcherParameters, type): @"type"
  };
}

+ (nullable Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary {
  if (!JSONDictionary[@"type"]) {
    LogError(@"The JSON field named 'type' is missing, so the class of the content fetcher "
             "couldn't be determined.");
    return nil;
  }
  Class contentFetcherClass = NSClassFromString(JSONDictionary[@"type"]);

  if(![contentFetcherClass conformsToProtocol:@protocol(BZRProductContentFetcher)]) {
    LogError(@"The JSON field named 'type' must specify a name of a class that conforms to the "
             "protocol %@, got: %@", @protocol(BZRProductContentFetcher),
             JSONDictionary[@"type"]);
    return nil;
  }

  return [contentFetcherClass expectedParametersClass];
}

@end

NS_ASSUME_NONNULL_END
