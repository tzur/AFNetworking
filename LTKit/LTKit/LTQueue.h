// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Implementation of a FIFO queue.
@interface LTQueue : NSObject

/// Pushes the provided \c object into the queue.
- (void)pushObject:(id)object;

/// Pops and returns the least recently added object from the queue. Returns \c nil if the queue is
/// empty.
- (id)popObject;

/// Removes the provided \c object from the queue. If the queue does not contain the \c object, the
/// method has no effect (although it does incur the overhead of searching the contents).
- (void)removeObject:(id)object;

/// Removes the last recently added object from the queue. Does nothing if the queue is empty.
- (void)removeFirstObject;

/// Removes the most recently added object from the queue. Does nothing if the queue is empty.
- (void)removeLastObject;

/// Removes all objects from the queue.
- (void)removeAllObjects;

/// Returns the lowest index whose corresponding array value is equal to \c object. If none of the
/// objects in the array is equal to \c object, returns \c NSNotFound.
- (NSUInteger)indexOfObject:(id)object;

/// Replaces the object at \c index with \c object. \c index must not exceed the bounds of the
/// array, otherwise an \c NSRangeException is raised. \c object must not be \c nil, otherwise an
/// \c NSInvalidArgumentException is raised.
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object;

/// Returns a copy of the queue in form of an array. The first entry of the array is the object
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
