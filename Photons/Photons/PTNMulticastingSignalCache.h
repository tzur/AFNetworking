// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNSignalCache.h"

NS_ASSUME_NONNULL_BEGIN

/// \c PTNSignalCache implementation that stores multicasted versions of every stored signal,
/// manually disposing of them when removed from the cache.
///
/// @important This cache manually disposes of any signal previously stored once removed from the
/// cache, this means that removing from the cache or overriding values should be done only when
/// no subscribers are subscribed to the removed signal.
@interface PTNMulticastingSignalCache : NSObject <PTNSignalCache>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c replayCapacity to be used when multicasting the stored signals. A capacity
/// of \c RACReplaySubjectUnlimitedCapacity means values are never trimmed.
- (instancetype)initWithReplayCapacity:(NSUInteger)replayCapacity;

@end

NS_ASSUME_NONNULL_END
