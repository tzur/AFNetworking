// Copyright (c) 2012 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "NSObject+AddToContainer.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSObject (AddToContainer)

- (void)addToSet:(NSMutableSet *)set {
  [set addObject:self];
}

- (void)addToArray:(NSMutableArray *)array {
  [array addObject:self];
}

- (void)setInDictionary:(NSMutableDictionary *)dictionary forKey:(id<NSCopying>)aKey {
  [dictionary setObject:self forKey:aKey];
}

@end

NS_ASSUME_NONNULL_END
