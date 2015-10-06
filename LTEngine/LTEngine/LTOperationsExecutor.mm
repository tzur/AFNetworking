// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOperationsExecutor.h"

@interface LTOperationsExecutor ()

/// Holds the operations to execute in serial order.
@property (strong, nonatomic) NSMutableArray *operations;

@end

@implementation LTOperationsExecutor

- (instancetype)init {
  if (self = [super init]) {
    self.operations = [NSMutableArray array];
  }
  return self;
}

- (void)addOperation:(NSOperation *)operation {
  LTParameterAssert(operation);
  @synchronized(self.operations) {
    [self.operations addObject:operation];
  }
}

- (void)removeOperation:(NSOperation *)operation {
  LTParameterAssert(operation);
  @synchronized(self.operations) {
    [self.operations removeObject:operation];
  }
}

- (void)executeAll {
  if (!self.executionAllowed) {
    return;
  }

  @synchronized(self.operations) {
    for (NSOperation *operation in self.operations) {
      if (operation.isReady && !operation.isFinished &&
          !operation.isExecuting && !operation.isCancelled) {
        [operation start];
      }
    }
    [self.operations removeAllObjects];
  }
}

@end
