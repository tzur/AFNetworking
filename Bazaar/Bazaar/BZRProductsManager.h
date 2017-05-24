// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

/// A unified interface for managing an products. The products manager provides methods for:
///
///   - Refreshing the receipt.
///
///   - Purchasing products.
///
///   - Fetching/deleting products' content.
///
///   - Getting the list of products that was last fetched.
@protocol BZRProductsManager <BZREventEmitter>

/// Makes a purchase of the product specified by \c productIdentifier.
///
/// Returns a signal that makes a purchase of the product and completes. The signal doesn't download
/// the content of the product. To do so, \c fetchProductContent should be called. The signal errs
/// if there was an error in the purchase.
///
/// @return <tt>RACSignal</tt>
- (RACSignal *)purchaseProduct:(NSString *)productIdentifier;

/// Provides access to the content of the given \c product.
///
/// Returns a signal that starts the fetching process. The signal returns \c LTProgress with
/// \c progress updates throughout the fetching process. When fetching is complete, the signal sends
/// an \c LTProgress with \c NSBundle as the \c result that provides access to the content and then
/// completes. If the content already exists locally, the signal completes and sends the \c NSBundle
/// immediately. The signal sends \c nil and completes if the product has no content.
/// The signal errs if there was an error while fetching the content.
///
/// @return <tt>RACSignal<nullable LTProgress<NSBundle>></tt>
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

/// Returns most recently fetched list of products. This however doesn't trigger the fetching
/// process.
///
/// Returns a signal that send the list of products as \c BZRProduct and completes. The signal errs
/// if there was an error while fetching the list of products.
///
/// @return <tt>RACSignal<NSSet<BZRProduct>></tt>
- (RACSignal *)productList;

/// Validates the receipt.
///
/// Returns a signal that validates the receipt. If validation is completed successfully, the latest
/// receipt from Apple is received and the receipt validation status is sent. The signal completes
/// when the validation is completed successfully. Otherwise the signal errs.
///
/// @return <tt>RACSignal<BZRReceiptValidationStatus></tt>
- (RACSignal *)validateReceipt;

/// Sends transactions of purchases that were completed successfully but were not finished in the
/// last run of the application, and are finished in this run. Every \c SKPaymentTransaction object
/// sent should be considered a successful purchase. The signal completes when the receiver is
/// deallocated. The signal doesn't err.
///
/// @return <tt>RACSignal<SKPaymentTransaction></tt>
@property (readonly, nonatomic) RACSignal *completedTransactionsSignal;

@end

NS_ASSUME_NONNULL_END
