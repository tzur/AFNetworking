// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRProductContentFetcher.h"

NS_ASSUME_NONNULL_BEGIN

/// Decorator fetcher used to share one content fetching signal between multiple subscribers.
/// Multiple calls to \c fetchProductContent with the same \c product will result in only one
/// content fetching action.
///
/// The fetching starts when the first subscriber subscribes to the signal, and the same events will
/// be sent to all subsequent subscribers.
/// The content will be refetched if the signal completed or erred, or if the number of subscribers
/// reached zero at some point.
///
/// For example using this fetcher is needed if the underlying fetcher signal shouldn't be executed
/// more than once for the same product simultaneously.
@interface BZRMulticastContentFetcher : NSObject <BZRProductContentFetcher>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c underlyingContentFetcher that is used to fetch the content.
- (instancetype)initWithUnderlyingContentFetcher:
    (id<BZRProductContentFetcher>)underlyingContentFetcher NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
