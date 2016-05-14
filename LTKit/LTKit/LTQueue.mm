// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQueue.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTQueue ()

/// Internally used ordered collection holding the queue content.
@property (strong, nonatomic) NSMutableArray *queue;

@end

@implementation LTQueue

- (instancetype)init {
  if (self = [super init]) {
    self.queue = [NSMutableArray array];
  }
  return self;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSUInteger)count {
  return self.queue.count;
}

- (nullable id)firstObject {
  return self.queue.firstObject;
}

- (nullable id)lastObject {
  return self.queue.lastObject;
}

- (NSArray *)array {
  return [self.queue copy];
}

#pragma mark -
#pragma mark Adding/Removing objects
#pragma mark -

- (void)pushObject:(id)object {
  [self willChangeValueForKey:@keypath(self, count)];
  [self insertObject:object inArrayAtIndex:self.queue.count];
  [self didChangeValueForKey:@keypath(self, count)];
}

- (nullable id)popObject {
  if (!self.queue.count) {
    return nil;
  }

  id result = self.queue.firstObject;

  [self willChangeValueForKey:@keypath(self, count)];
  [self removeObjectFromArrayAtIndex:0];
  [self didChangeValueForKey:@keypath(self, count)];

  return result;
}

- (void)removeObject:(id)object {
  NSUInteger index = [self.queue indexOfObject:object];
  if (index == NSNotFound) {
    return;
  }

  [self willChangeValueForKey:@keypath(self, count)];
  [self removeObjectFromArrayAtIndex:index];
  [self didChangeValueForKey:@keypath(self, count)];
}

- (void)removeFirstObject {
  if (!self.queue.count) {
    return;
  }

  [self willChangeValueForKey:@keypath(self, count)];
  [self removeObjectFromArrayAtIndex:0];
  [self didChangeValueForKey:@keypath(self, count)];
}

- (void)removeLastObject {
  if (!self.queue.count) {
    return;
  }

  [self willChangeValueForKey:@keypath(self, count)];
  [self removeObjectFromArrayAtIndex:self.queue.count - 1];
  [self didChangeValueForKey:@keypath(self, count)];
}

- (void)removeAllObjects {
  if (!self.queue.count) {
    return;
  }

  [self willChangeValueForKey:@keypath(self, count)];
  NSRange range = NSMakeRange(0, self.queue.count);
  [self removeArrayAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
  [self didChangeValueForKey:@keypath(self, count)];
}

- (NSUInteger)indexOfObject:(id)object {
  return [self.queue indexOfObject:object];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object {
  [self replaceObjectInArrayAtIndex:index withObject:object];
}

#pragma mark -
#pragma mark Retrieval of information about queue
#pragma mark -

- (BOOL)containsObject:(id)object {
  return [self.queue containsObject:object];
}

#pragma mark -
#pragma mark Collection Accessor Patterns
#pragma mark -

- (NSUInteger)countOfArray {
  return self.queue.count;
}

- (NSArray *)arrayAtIndexes:(NSIndexSet *)indexes {
  return [self.queue objectsAtIndexes:indexes];
}

- (void)insertObject:(id)object inArrayAtIndex:(NSUInteger)index {
  [self.queue insertObject:object atIndex:index];
}

- (void)removeArrayAtIndexes:(NSIndexSet *)indexes {
  [self.queue removeObjectsAtIndexes:indexes];
}

- (void)removeObjectFromArrayAtIndex:(NSUInteger)index {
  [self.queue removeObjectAtIndex:index];
}

- (void)replaceObjectInArrayAtIndex:(NSUInteger)index withObject:(id)object {
  [self.queue replaceObjectAtIndex:index withObject:object];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, %@>", [self class], self, self.queue];
}

@end

NS_ASSUME_NONNULL_END
