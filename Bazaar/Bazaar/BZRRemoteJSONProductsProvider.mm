// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRRemoteJSONProductsProvider.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/RACSignal+Fiber.h>

#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRRemoteJSONProductsProvider ()

/// Url to get the JSON file from.
@property (readonly, nonatomic) NSURL *URL;

/// Client used to make an HTTP request.
@property (readonly, nonatomic) FBRHTTPClient *HTTPClient;

@end

@implementation BZRRemoteJSONProductsProvider

- (instancetype)initWithURL:(NSURL *)URL HTTPClient:(FBRHTTPClient *)HTTPClient {
  if (self = [super init]) {
    _URL = URL;
    _HTTPClient = HTTPClient;
  }

  return self;
}

- (instancetype)initWithURL:(NSURL *)URL {
  return [self initWithURL:URL HTTPClient:[FBRHTTPClient client]];
}

- (RACSignal *)fetchJSONProductList {
  return [[[self.HTTPClient GET:self.URL.path withParameters:nil] fbr_deserializeJSON]
      tryMap:^id(id value, NSError **error) {
        if (![value isKindOfClass:[NSArray class]]) {
          *error = [NSError lt_errorWithCode:BZRErrorCodeJSONDataDeserializationFailed];
          return nil;
        }
        return value;
      }];
};

@end

NS_ASSUME_NONNULL_END
