// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "NSObject+NSSet.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSObject (NSSet)

- (NSSet *)lt_set {
  return [NSSet setWithObject:self];
}

@end

NS_ASSUME_NONNULL_END
