// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Implementation of a FIFO queue.
@interface LTQueue : NSObject

/// Pushes the provided \c object into the queue.
- (void)pushObject:(id)object;

/// Pops and returns the least recently added object from the queue. Returns \c nil if the queue is
/// empty.
- (id)popObject;

/// Removes the provided \c object from the queue. If the queue does not contain the \c object,the
/// method has no effect (although it does incur the overhead of searching the contents).
- (void)removeObject:(id)object;

/// Returns a copy of the queue in form of an NSArray. The first entry of the array is the object
/// which has been pushed to the queue least recently, while the last entry is the object which has
/// been pushed most recently.
- (NSArray *)array;

/// Returns \c YES if the provided \c object is contained in the queue.
- (BOOL)containsObject:(id)object;

/// The least recently added object in the queue. Returns \c nil if the queue is empty.
@property (readonly, nonatomic) id firstObject;

/// The most recently added object in the queue. Returns \c nil if the queue is empty.
@property (readonly, nonatomic) id lastObject;

/// Number of objects in queue.
@property (readonly, nonatomic) NSUInteger count;

@end
