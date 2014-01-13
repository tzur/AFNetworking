// Copyright (c) 2012 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@interface NSObject (AddToContainer)

// Add the object to the given mutable set.
- (void)addToSet:(NSMutableSet *)set;

// Add the object to the given mutable array.
- (void)addToArray:(NSMutableArray *)array;

@end
