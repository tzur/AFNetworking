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

@end

NS_ASSUME_NONNULL_END
