// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for sending events through \c eventsSignal.
@protocol BZREventEmitter <NSObject>

/// Sends messages of important events that occur throughout the receiver. The events can be
/// informational or errors. The signal doesn't err.
///
/// @return <tt>RACSignal<BZREvent></tt>
@property (readonly, nonatomic) RACSignal *eventsSignal;

@end

NS_ASSUME_NONNULL_END
