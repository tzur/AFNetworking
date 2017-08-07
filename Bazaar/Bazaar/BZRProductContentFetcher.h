// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRProduct;

/// Protocol for fetching content of products.
@protocol BZRProductContentFetcher <BZREventEmitter>

/// Fetches the content of the given \c product.
///
/// Returns a signal that starts the fetching process. The signal sends \c LTProgress with
/// \c progress updates throughout the fetching process. When the fetch is complete, the signal
/// sends an \c LTProgress with \c result set to an \c NSBundle that provides access to the content.
/// The signal completes after sending the \c LTProgress with the \c result. The signal errs if
/// there was an error while fetching the content or if the given
/// \c product.contentFetcherParameters is invalid.
///
/// @return <tt>RACSignal<LTProgress<NSBundle>></tt>
///
/// @note \c product must specify the content source in \c product.contentFetcherParameters.
- (RACSignal *)fetchProductContent:(BZRProduct *)product;

/// Provides access to the content of \c product if the content exists.
///
/// Returns a signal that sends an \c NSBundle or \c nil if the content is not available on the
/// device. The bundle provides access to the content of the product specified by \c product. The
/// signal completes after sending the value. The signal doesn't err.
///
/// @return <tt>RACSignal<nullable NSBundle></tt>
///
/// @note \c product must specify the content source in \c product.contentFetcherParameters.
- (RACSignal *)contentBundleForProduct:(BZRProduct *)product;

@optional

/// Returns the class that an instance of the receiving class expects to receive from \c product.
+ (Class)expectedParametersClass;

@end

NS_ASSUME_NONNULL_END
