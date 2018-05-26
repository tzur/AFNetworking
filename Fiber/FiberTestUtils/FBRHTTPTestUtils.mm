// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPTestUtils.h"

#import <Fiber/FBRHTTPResponse.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

FBRHTTPResponse *FBRFakeHTTPResponse(NSString *requestURL, NSUInteger statusCode,
                                     FBRHTTPRequestHeaders * _Nullable headers,
                                     NSData * _Nullable content) {
  auto metadata = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:requestURL]
                                              statusCode:statusCode HTTPVersion:@"1.1"
                                            headerFields:headers];
  return [[FBRHTTPResponse alloc] initWithMetadata:metadata content:content];
}

FBRHTTPResponse *FBRFakeHTTPJSONResponse(NSString *requestURL, id JSONObject,
                                         NSUInteger statusCode,
                                         FBRHTTPRequestHeaders * _Nullable headers) {
  if ([JSONObject conformsToProtocol:@protocol(MTLJSONSerializing)]) {
    JSONObject = [MTLJSONAdapter JSONDictionaryFromModel:JSONObject];
  }

  NSData *content = [NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:nil];
  LTAssert(content, @"Invalid JSONObject provided. Expected JSON NSArray or NSDictionary or JSON "
           "serializable model, got %@ of kind %@", JSONObject, [JSONObject class]);

  FBRHTTPRequestHeaders *actualHeaders = @{
    @"Content-Type": @"application/json",
    @"Content-Length": [NSString stringWithFormat:@"%lu", (unsigned long)content.length]
  };

  if (headers) {
    actualHeaders = [actualHeaders mtl_dictionaryByAddingEntriesFromDictionary:headers];
  }

  return FBRFakeHTTPResponse(requestURL, statusCode, actualHeaders, content);
}

NS_ASSUME_NONNULL_END
