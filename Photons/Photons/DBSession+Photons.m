// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "DBSession+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DBSession (Photons)

- (DBRestClient *)ptn_restClient {
  return [[DBRestClient alloc] initWithSession:self];
}

@end

NS_ASSUME_NONNULL_END
