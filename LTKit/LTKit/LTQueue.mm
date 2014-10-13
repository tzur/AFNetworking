// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQueue.h"

@interface LTQueue ()

// Underlying data structure used for storing the objects.
@property (strong, nonatomic) NSMutableArray *queue;

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
  [self.queue addObject:object];
}

- (id)popObject {
  if (!self.queue.count) {
    return nil;
  }
  id result = self.queue.firstObject;
  [self.queue removeObjectAtIndex:0];
  return result;
}

- (void)removeObject:(id)object {
  [self.queue removeObject:object];
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
