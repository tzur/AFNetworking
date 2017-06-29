// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNFakeMediaQueryProvider.h"

#import <MediaPlayer/MPMediaQuery.h>

#import "PTNFakeMediaQuery.h"
#import "PTNMediaQueryProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFakeMediaQueryProvider ()

/// Backing query object.
@property (readonly, nonatomic) id<PTNMediaQuery>query;

@end

@implementation PTNFakeMediaQueryProvider

- (instancetype)initWithQuery:(PTNFakeMediaQuery *)query {
  if (self = [super init]) {
    _query = query;
  }
  return self;
}

- (id<PTNMediaQuery>)queryWithFilterPredicates:(NSSet<MPMediaPredicate *> *)predicates {
  auto mergedPredicates = [predicates setByAddingObjectsFromSet:self.query.filterPredicates];
  self.query.filterPredicates = mergedPredicates;
  return self.query;
}

@end

NS_ASSUME_NONNULL_END
