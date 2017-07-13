// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNMediaQueryProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNMediaQueryProvider

- (id<PTNMediaQuery>)queryWithFilterPredicates:(NSSet<MPMediaPredicate *> *)predicates {
  return [[MPMediaQuery alloc] initWithFilterPredicates:predicates];
}

@end

NS_ASSUME_NONNULL_END
