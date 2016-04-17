// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Fake \c NSURLCache object used for testing.
@interface PTNCacheFakeNSURLCache : NSURLCache

/// Mapping of \c NSURLRequest objects to \c NSCachedURLResponse objects.
typedef NSDictionary<NSURLRequest *, NSCachedURLResponse *> PTNURLCacheStorage;

/// Storage simulation mapping \c NSURLRequest objects to the \c NSCachedURLResponse that was stored
/// for them.
@property (readonly, nonatomic) PTNURLCacheStorage *storage;

@end

NS_ASSUME_NONNULL_END
