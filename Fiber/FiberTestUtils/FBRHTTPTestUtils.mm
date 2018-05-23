// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPTestUtils.h"

#import <Fiber/FBRHTTPResponse.h>

NS_ASSUME_NONNULL_BEGIN

FBRHTTPResponse *FBRFakeHTTPResponse(NSString *requestURL, NSUInteger statusCode,
                                     FBRHTTPRequestHeaders * _Nullable headers,
                                     NSData * _Nullable content) {
  auto metadata = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:requestURL]
                                              statusCode:statusCode HTTPVersion:@"1.1"
                                            headerFields:headers];
  return [[FBRHTTPResponse alloc] initWithMetadata:metadata content:content];
}

NS_ASSUME_NONNULL_END
