// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <ReactiveCocoa/ReactiveCocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface RACSignal (Photons)

/// Multicasts the signal to a \c RACReplaySubject of capacity 1, and lazily connects to the
/// resulting \c RACMulticastConnection.
///
/// This means the returned signal will subscribe to the multicasted signal only when the former
/// receives its first subscription.
///
/// Returns the lazily connected, multicasted signal.
- (instancetype)ptn_replayLastLazily;

/// Catches errors sent by the receiver and maps them to \c error with the original error as its
/// underlying error. If \c error already has an underlying error, it will be overwritten.
///
/// @note Underlying error is stored in the error's \c userInfo property under the
/// \c NSUnderlyingErrorKey key.
- (instancetype)ptn_wrapErrorWithError:(NSError *)error;

/// Combines the latest values from each of the given \c signals by sending the latest value from
/// each signal accompanied with the index of the signal that caused a new value to be sent over the
/// receiver. For the returned signal to send an initial value, all the \c signals must send at least one
/// value. The initially sent value will send a \c nil index.
///
/// If \c signals is empty, the returned signal will immediately complete upon subscription.
///
/// Returns a signal in the format <tt>((v_0, v_1, ..., v_n), index)</tt>, where
/// <tt>{v_0, v_1, ..., v_n}</tt> are the latest values from the given \c signals and \c index is
/// the index in the range <tt>{0, 1, ..., n}</tt> of the latest signal that caused a new value to
/// be sent over the receiver. The returned signal forwards any \c error events, and completes when
/// all input signals complete.
///
/// @return RACSignal<RACTuple *>.
+ (RACSignal *)ptn_combineLatestWithIndex:(id<NSFastEnumeration>)signals;

@end

NS_ASSUME_NONNULL_END
