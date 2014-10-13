// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQueue.h"

/// Implementation of a FIFO queue with limited capacity.
@interface LTLimitedCapacityQueue : LTQueue

/// Initializes the queue with a maximal \c capacity of objects allowed to be simultaneously in the
/// queue. Pushing an object to a full queue will discard the least recently added object of the
/// queue.
- (instancetype)initWithMaximalCapacity:(NSUInteger)capacity;

/// Maximal capacity of the queue.
@property (readonly, nonatomic) NSUInteger maximalCapacity;

@end
