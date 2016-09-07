// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// A unified interface for managing an products. The products manager provides methods for:
///
///   - Refreshing the receipt.
///
///   - Purchasing products.
///
///   - Fetching/deleting products' content.
///
///   - Fetching price information of products.
///
@protocol BZRProductsManager <NSObject>

/// Makes a purchase of the product specified by \c productIdentifier.
///
/// Returns a signal that makes a purchase of the product and completes. The signal doesn't download
/// the content of the product. To do so, \c fetchProductContent should be called. The signal errs
/// if there was an error in the purchase.
///
/// @return <tt>RACSignal</tt>
- (RACSignal *)purchaseProduct:(NSString *)productIdentifier;

/// Fetches the content of the given \c product.
///
/// Returns a signal that fetches the content. If the content already exists locally, the signal
/// just returns an \c LTPath to that content. Otherwise, it fetches the content and sends an
/// \c LTPath to the content. The signal completes if there is no content to be downloaded, or after
/// sending the path to it. The signal errs if the user is not allowed to use the product, if there
/// was an error while fetching the content.
///
/// @return <tt>RACSignal<LTPath></tt>
- (RACSignal *)fetchProductContent:(NSString *)productIdentifier;

/// Deletes the content of the given \c product.
///
/// Returns a \c RACSignal that completes when the deletion has completed successfully. The signal
/// errs if an error occurred.
///
/// @return <tt>RACSignal</tt>
- (RACSignal *)deleteProductContent:(NSString *)productIdentifier;

/// Refreshes the receipt. This updates the subscription information and restores the list of
/// purchased products on all devices.
///
/// Returns a signal that refreshes the receipt and completes. The signal errs if the refresh has
/// failed.
///
/// @return <tt>RACSignal</tt>
- (RACSignal *)refreshReceipt;

/// Fetches the price of each product specified by \c productIdentifiers.
///
/// Returns a signal that sends the price information of the products specified by
/// \c productIdentifiers and completes. The signal errs if the fetching has failed.
///
/// @return <tt><RACSignal<NSArray<BZRProductPriceInfo>></tt>
- (RACSignal *)priceForProducts:(NSArray<NSString *> *)productIdentifiers;

@end

NS_ASSUME_NONNULL_END
