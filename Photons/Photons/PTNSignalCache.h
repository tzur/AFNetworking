// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a thread safe cache for \c RACSignal entities based on URLs.
@protocol PTNSignalCache <NSObject>

/// Stores \c signal in the cache for \c url. If \c signal is \c nil the cached entry for \c url
/// will be removed.
- (void)storeSignal:(nullable RACSignal *)signal forURL:(NSURL *)url;

/// Retrieves cached signal for \c url if exists or \c nil if no cached signal exists for \c url.
- (nullable RACSignal *)signalForURL:(NSURL *)url;

/// Stores \c obj in the cache for \c key. If \c obj is \c nil the cached entry for \c key will be
/// removed.
///
/// @see -[PTNSignalCache storeSignal:forURL:].
- (void)setObject:(nullable RACSignal *)obj forKeyedSubscript:(NSURL *)key;

/// Retrieves cached signal for \c key if exists or \c nil if no cached signal exists for \c key.
///
/// @see -[PTNSignalCache signalForURL:].
- (nullable RACSignal *)objectForKeyedSubscript:(NSURL *)key;

/// Removes signal stored for \c url if exists from the cache.
- (void)removeSignalForURL:(NSURL *)url;

@end

/// Default implementation of \c PTNSignalCache.
@interface PTNSignalCache : NSObject <PTNSignalCache>
@end

NS_ASSUME_NONNULL_END
