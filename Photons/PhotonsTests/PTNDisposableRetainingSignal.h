// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Signal that doesn't send any values but maintains bookkeeping of each disposable returned on
/// subscription.
@interface PTNDisposableRetainingSignal : RACSignal

/// Disposable objects returned on subscriptions in the order they were returned.
@property (readonly, nonatomic) NSArray<RACDisposable *> *disposables;

@end

NS_ASSUME_NONNULL_END
