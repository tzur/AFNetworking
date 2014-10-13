// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTLimitedCapacityQueue.h"

@interface LTLimitedCapacityQueue ()

/// Maximal number of objects allowed to reside simultaneously in the queue.
@property (nonatomic) NSUInteger maximalCapacity;

@end

@implementation LTLimitedCapacityQueue

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  LTMethodNotImplemented();
}

- (instancetype)initWithMaximalCapacity:(NSUInteger)capacity {
  if (self = [super init]) {
    LTParameterAssert(capacity > 0);
    self.maximalCapacity = capacity;
  }
  return self;
}

#pragma mark -
#pragma mark ENQueue
#pragma mark -

- (void)pushObject:(id)object {
  if (self.count == self.maximalCapacity) {
    [self popObject];
  }
  [super pushObject:object];
}

@end
