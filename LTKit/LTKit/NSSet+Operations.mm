// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSSet+Operations.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSSet (Operations)

- (NSSet *)lt_union:(NSSet *)otherSet {
  auto unionSet = [NSMutableSet setWithSet:self];
  [unionSet unionSet:otherSet];
  return unionSet;
}

- (NSSet *)lt_minus:(NSSet *)otherSet {
  auto minusSet = [NSMutableSet setWithSet:self];
  [minusSet minusSet:otherSet];
  return minusSet;
}

- (NSSet *)lt_intersect:(NSSet *)otherSet {
  auto intersectSet = [NSMutableSet setWithSet:self];
  [intersectSet intersectSet:otherSet];
  return intersectSet;
}

@end

NS_ASSUME_NONNULL_END
