// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

@interface RACSignal (Intelligence)

/// Returns a \c RACSignal that, upon subscription, subscribes to the returned \c RACSignal by
/// \c signalBlock, after opening a background task with \c application. When the \c RACSignal
/// completes \c application is invoked with \c endBackgroundTask:. Errs with
/// \c INTErrorCodeBackgroundTaskFailedToStart if the \c application fails to start a background
/// task. If the underlying operation takes too much time, \c application notifies that the time
/// for execution is over, and the underlying signal is disposed of.
///
/// @note Subscription to this signal should be made on the main thread so that calls of
/// \c UIApplication are made on the main thread.
+ (RACSignal *)backgroundTaskWithSignalBlock:(RACSignal *(^)(void))signalBlock
                                 application:(UIApplication *)application;

/// Convenient method for calling \c backgroundTaskWithSignalBlock:application: with
/// <tt>+[UIApplication sharedApplication]</tt> as the \c application parameter.
+ (RACSignal *)backgroundTaskWithSignalBlock:(RACSignal *(^)(void))signalBlock
    NS_EXTENSION_UNAVAILABLE_IOS("[RACSignal backgroundTaskWithSignalBlock:application:] instead.");

@end

NS_ASSUME_NONNULL_END
