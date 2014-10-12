// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTLimitedCapacityQueue.h"

@interface LTLimitedCapacityQueue ()

/// Maximum number of objects allowed to reside simultaneously in the queue.
@property (nonatomic) NSUInteger maximumCapacity;

@end

@implementation LTLimitedCapacityQueue

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  LTMethodNotImplemented();
  return nil;
}

- (instancetype)initWithMaximumCapacity:(NSUInteger)capacity {
  if (self = [super init]) {
    LTParameterAssert(capacity > 0);
    self.maximumCapacity = capacity;
  }
  return self;
}

#pragma mark -
#pragma mark ENQueue
#pragma mark -

- (void)pushObject:(id)object {
  if (super.count == self.maximumCapacity) {
    [self popObject];
  }
  [super pushObject:object];
}

@end
