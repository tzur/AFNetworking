// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "NSArray+NSSet.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSArray (NSSet)

- (NSSet *)lt_set {
  return [NSSet setWithArray:self];
}

- (NSOrderedSet *)lt_orderedSet {
  return [NSOrderedSet orderedSetWithArray:self];
}

@end

NS_ASSUME_NONNULL_END
