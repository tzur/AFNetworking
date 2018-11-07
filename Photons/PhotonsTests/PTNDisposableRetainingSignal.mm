// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDisposableRetainingSignal.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDisposableRetainingSignal ()

/// Disposable objects returned on subscriptions in the order they were returned.
@property (readonly, nonatomic) NSMutableArray<RACDisposable *> *mutableDisposables;

@end

@implementation PTNDisposableRetainingSignal

- (instancetype)init {
  if (self = [super init]) {
    _mutableDisposables = [NSMutableArray array];
  }
  return self;
}

- (RACDisposable *)subscribe:(__unused id<RACSubscriber>)subscriber {
  RACDisposable *disposable = [RACDisposable disposableWithBlock:^{
    // The subscriber disposes of this disposable when deallocated, so it must be retained until
    // the disposable is manually disposed.
    id<RACSubscriber> __unused retainedSubscriber = subscriber;
  }];
  [self.mutableDisposables addObject:disposable];
  return disposable;
}

- (NSArray<RACDisposable *> *)disposables {
  return [self.mutableDisposables copy];
}

@end

NS_ASSUME_NONNULL_END
