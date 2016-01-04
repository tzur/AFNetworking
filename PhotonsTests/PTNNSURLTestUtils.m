// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNNSURLTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

NSURL *PTNCreateURL(NSString * _Nullable scheme, NSString * _Nullable host,
                    NSArray<NSURLQueryItem *> * _Nullable query) {
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = scheme;
  components.host = host;
  components.queryItems = query;
  return components.URL;
}

NS_ASSUME_NONNULL_END
