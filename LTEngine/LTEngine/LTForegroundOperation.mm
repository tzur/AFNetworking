// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTForegroundOperation.h"

#import "LTOperationsExecutor.h"

@implementation LTForegroundOperation

+ (LTOperationsExecutor *)executor {
  static LTOperationsExecutor *executor;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    executor = [[LTOperationsExecutor alloc] init];
  });

  return executor;
}

+ (instancetype)blockOperationWithBlock:(void (^)(void))block {
  return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(LTCompletionBlock)block {
  if (self = [super init]) {
    [self addExecutionBlock:block];
    [[[self class] executor] addOperation:self];
  }
  return self;
}

- (LTCompletionBlock)foregroundBlock {
  return ^{
    if (![[self class] executor].executionAllowed) {
      return;
    }

    [self start];
    [[[self class] executor] removeOperation:self];
  };
}

@end
