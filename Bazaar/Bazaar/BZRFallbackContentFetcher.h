// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRContentFetcherParameters.h"
#import "BZRProductContentFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRCompositeContentFetcher;

/// Fetcher that tries fetching content using multiple fetchers one by one until one succeeds.
@interface BZRFallbackContentFetcher : NSObject <BZRProductContentFetcher>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c compositeContentFetcher that is used to route the content fetcher parameters
/// to the appropriate fetcher.
- (instancetype)initWithCompositeContentFetcher:
    (BZRCompositeContentFetcher *)compositeContentFetcher NS_DESIGNATED_INITIALIZER;

/// Fetches product content using the underlying composite content fetcher with a list of parameters
/// as specified by \c product.contentFetcherParameters.fetcherParameters.
///
/// Returns a signal that on subscription iteratively unpacks parameters from
/// \c product.contentFetcherParameters.fetcherParameters and pass them to the underlying
/// \c BZRCompositeContentFetcher. The signal forwards the progress values delivered by the
/// underlying fetcher and completes if the underlying fetcher completes. If the underlying fetcher
/// errs the signal will try fetching again with the next packed parameters. The signal errs if all
/// the underlying fetch attempts errs.
///
/// @note If fetching has failed in the middle, the values from the next fetcher will be sent with
/// new progress values, which may start again from 0.
///
/// @return <tt>RACSignal<LTProgress<NSBundle>></tt>
- (RACSignal *)fetchProductContent:(BZRProduct *)product;

/// Checks if the content bundle exists using the underlying composite content fetcher with
/// a list of parameters as specified by \c product.contentFetcherParameters.fetcherParameters.
///
/// Returns a signal that on subscription iteratively unpacks parameters from
/// \c product.contentFetcherParameters.fetcherParameters and pass them to the underlying
/// \c BZRCompositeContentFetcher. The signal completes if the underlying fetcher sends a non \c nil
/// bundle. If the underlying fetcher sent \c nil the signal will check again with the next packed
/// parameters. The signal sends \c nil if all the underlying check attempts sent \c nil.
/// The signal errs if one of the underlying check attempts erred.
///
/// @return <tt>RACSignal<nullable NSBundle></tt>
- (RACSignal *)contentBundleForProduct:(BZRProduct *)product;

@end

/// Additional parameters required for fetching content with \c BZRFallbackContentFetcher.
///
/// Example of a JSON serialized \c BZRFallbackContentFetcherParameters:
/// @code
/// {
///   "type": "BZRFallbackContentFetcher",
///   "fetchersParameters": [
///     {
///       "type": "FooFetcher",
///       "URL": "file:///foo/bar.zip"
///     },
///     {
///       "type": "BarFetcher",
///       "URL": "https:///moo/bar.zip"
///     }
///    ]
/// }
@interface BZRFallbackContentFetcherParameters : BZRContentFetcherParameters

/// Array that contains a list of fetcher parameters that defines the fetching order.
@property (readonly, nonatomic) NSArray<BZRContentFetcherParameters *> *fetchersParameters;

@end

NS_ASSUME_NONNULL_END
