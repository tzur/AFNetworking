// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRRemoteProductsProvider.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/RACSignal+Fiber.h>

#import "BZRProduct.h"
#import "NSErrorCodes+Bazaar.h"
#import "RACSignal+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRRemoteProductsProvider ()

/// URL to get the JSON file from.
@property (readonly, nonatomic) NSURL *URL;

/// Client used to make an HTTP request.
@property (readonly, nonatomic) FBRHTTPClient *HTTPClient;

@end

@implementation BZRRemoteProductsProvider

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

- (RACSignal *)fetchProductList {
  return [[[[self.HTTPClient GET:self.URL.path withParameters:nil] fbr_deserializeJSON]
      bzr_deserializeArrayOfModels:[BZRProduct class]]
      setNameWithFormat:@"%@ -fetchProductList", self.description];
};

@end

NS_ASSUME_NONNULL_END
