// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRProduct;

/// Protocol for fetching content of products.
@protocol BZRProductContentFetcher <NSObject>

/// Provides access to the content of the given \c product.
///
/// Returns a signal that starts the fetching process. The signal sends \c LTProgress with
/// \c progress updates throughout the fetching process. When the fetch is complete, the signal
/// sends an \c LTProgress with \c result set to an \c NSBundle that provides access to the content.
/// The signal completes after sending the \c LTProgress with the \c result. The signal errs if
/// there was an error while fetching the content.
///
/// @return <tt>RACSignal<LTProgress<NSBundle>></tt>
///
/// @note \c product must specify the content source in \c contentFetcherParameters.
- (RACSignal *)fetchProductContent:(BZRProduct *)product;

/// Returns an \c NSBundle that provides access to the content of the product specified by
/// \c product, if the content is available on the device. Returns \c nil if the product content is
/// unavailable on the device.
///
/// @note \c product must specify the content source in \c contentFetcherParameters.
- (nullable NSBundle *)contentBundleForProduct:(BZRProduct *)product;

@optional

/// Returns the class that an instance of the receiving class expects to receive from \c product.
+ (Class)expectedParametersClass;

@end

NS_ASSUME_NONNULL_END
