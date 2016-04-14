// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxFakeRestClientProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNDropboxFakeRestClientProvider

- (instancetype)initWithClient:(nullable DBRestClient *)client {
  if (self = [super init]) {
    self.restClient = client;
    self.isLinked = YES;
  }
  return self;
}

- (instancetype)init {
  return [self initWithClient:nil];
}

- (DBRestClient *)ptn_restClient {
  return self.restClient;
}

@end

NS_ASSUME_NONNULL_END
