// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQueue.h"

@interface LTQueue <ObjectType> ()

/// Underlying data structure used for storing the objects.
@property (strong, nonatomic) NSMutableArray<ObjectType> *queue;

@end

@implementation LTQueue

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSUInteger)count {
  return self.queue.count;
}

- (id)firstObject {
  return self.queue.firstObject;
}

- (id)lastObject {
  return self.queue.lastObject;
}

- (NSMutableArray *)queue {
  if(!_queue) {
    _queue = [NSMutableArray array];
  }
  return _queue;
}

#pragma mark -
#pragma mark Adding/Removing objects
#pragma mark -

- (void)pushObject:(id)object {
  [self willChangeValueForKey:@keypath(self, count)];
  [self.queue addObject:object];
  [self didChangeValueForKey:@keypath(self, count)];
}

- (id)popObject {
  if (!self.queue.count) {
    return nil;
  }
  id result = self.queue.firstObject;
  [self willChangeValueForKey:@keypath(self, count)];
  [self.queue removeObjectAtIndex:0];
  [self didChangeValueForKey:@keypath(self, count)];
  return result;
}

- (void)removeObject:(id)object {
  [self willChangeValueForKey:@keypath(self, count)];
  [self.queue removeObject:object];
  [self didChangeValueForKey:@keypath(self, count)];
}

- (void)removeFirstObject {
  if (!self.queue.count) {
    return;
  }

  [self willChangeValueForKey:@keypath(self, count)];
  [self.queue removeObjectAtIndex:0];
  [self didChangeValueForKey:@keypath(self, count)];
}

- (void)removeLastObject {
  if (!self.queue.count) {
    return;
  }

  [self willChangeValueForKey:@keypath(self, count)];
  [self.queue removeObjectAtIndex:self.queue.count - 1];
  [self didChangeValueForKey:@keypath(self, count)];
}

- (void)removeAllObjects {
  if (!self.queue.count) {
    return;
  }

  [self willChangeValueForKey:@keypath(self, count)];
  [self.queue removeAllObjects];
  [self didChangeValueForKey:@keypath(self, count)];
}

- (NSUInteger)indexOfObject:(id)object {
  return [self.queue indexOfObject:object];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object {
  [self.queue replaceObjectAtIndex:index withObject:object];
}

#pragma mark -
#pragma mark Retrieval of information about queue
#pragma mark -

- (NSArray *)array {
  return [self.queue copy];
}

- (BOOL)containsObject:(id)object {
  return [self.queue containsObject:object];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, %@>", [self class], self, self.queue];
}

@end
