// Copyright (c) 2012 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (AddToContainer)

/// Add the object to the given mutable set.
- (void)addToSet:(NSMutableSet *)set;

/// Add the object to the given mutable array.
- (void)addToArray:(NSMutableArray *)array;

/// Sets the object for the given key in the given \c dictionary.
- (void)setInDictionary:(NSMutableDictionary *)dictionary forKey:(id<NSCopying>)aKey;

@end

NS_ASSUME_NONNULL_END
