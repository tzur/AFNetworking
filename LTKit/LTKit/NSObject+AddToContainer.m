// Copyright (c) 2012 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "NSObject+AddToContainer.h"

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
