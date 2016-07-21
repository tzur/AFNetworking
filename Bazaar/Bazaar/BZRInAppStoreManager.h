// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRProduct;

/// A unified interface for managing an in-application store.
///
/// The store manager provides methods for:
///
///   - Fetching product list.
///
///   - Syncing the products purchased by the user.
///
///   - Purchasing products.
///
///   - Managing products' content.
///
///   - Getting the user's subscription information.
@interface BZRInAppStoreManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c applicationId, used to fetch the correct product list with, and with
/// \c applicationUserId, used to restore the list of products purchased by the user.
- (instancetype)initWithApplicationId:(NSString *)applicationId
                    applicationUserId:(nullable NSString *)applicationUserId NS_DESIGNATED_INITIALIZER;

/// Fetches the list of available products for the application.
///
/// Returns a signal that fetches the list of \c BZRProduct that are available for the application.
/// The signal sends a single \c NSArray<BZRProduct> and completes. The signal errs if the
/// fetching has failed.
///
/// @return <tt>RACSignal<NSArray<BZRProduct>></tt>
- (RACSignal *)fetchProductList;

/// Restores the list of products previously purchased by the user, but doesn't download the content
/// for them. To do so, the method named \c fetchProductContent should be called.
///
/// Returns a signal that sends the list of purchased products as a single
/// \c NSArray<BZRProduct> and completes. The signal errs if the fetching has failed.
///
/// @return <tt>RACSignal<NSArray<BZRProduct>></tt>
- (RACSignal *)restorePurchasedProducts;

/// Provides the list of products that were purchased by the user.
///
/// Returns a signal that sends the list of products purchased by the user. Whenever the list
/// changes the signal sends it. The signal completes when the class' instance is deallocated. The
/// list of purchased products includes products that the user has acquired through subscription and
/// are available on the device. The list might be outdated, for example if the user has made
/// purchases on a another device. In order to update it, \c restorePurchasedProducts should be
/// called. The signal doesn't err.
///
/// @return <tt>RACSignal<NSArray<BZRProduct>></tt>
- (RACSignal *)purchasedProducts;

/// Provides the list of products that their content is already available on the device.
///
/// Returns a signal that sends the list of products with downloaded content. Whenever the list
/// changes the signal sends it. The signal completes when the class' instance is deallocated.
/// Products without content will be in the list as well. The signal errs if there was an error when
/// trying to assemble the list.
///
/// @return <tt>RACSignal<NSArray<BZRProduct>></tt>
- (RACSignal *)productsWithDownloadedContent;

/// Makes a purchase of the given \c product.
///
/// Returns a signal that makes a purchase of the product and completes. The signal errs if there
/// was an error in the purchase.
///
/// @return <tt>RACSignal</tt>
- (RACSignal *)purchaseProduct:(BZRProduct *)product;

/// Fetches the content of the given \c product.
///
/// Returns a signal that fetches the content. Before fetching, the signal checks whether the user
/// is allowed to use the product. If the content already exists locally, the signal just returns an
/// \c LTPath to that content. Otherwise, it fetches the content and sends an \c LTPath to the 
/// content. The signal completes after sending a single \c LTPath. The signal errs if the user is
/// not allowed to use the product, or if there was an error when fetching the content.
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

/// Checks whether the user is allowed to use product specified by \c productIdentifier. The user is
/// allowed to use a product if he purchased it or if he purchased a subscription that grants him
/// the right to use the product.
///
/// Returns a signal that sends a single \c NSNumber value boxing a \c BOOL value, the boxed value
/// will be \c YES if the user is allowed to use the product, otherwise it will be \c NO. The signal
/// completes after sending the value. The signal errs if there was an error when checking if the
/// product is available.
///
/// @return <tt>RACSignal<NSNumber></tt>
- (RACSignal *)checkUserEligibilityForProduct:(NSString *)productIdentifier;

/// Fetches subscription information of the user.
///
/// Returns a signal that fetches the subscription information of the user and sends it. The signal
/// completes after sending the information. The signal errs if the fetching has failed.
///
/// @return <tt>RACSignal<BZRReceiptSubscriptionInfo></tt>
- (RACSignal *)fetchUserSubscriptionInfo;

@end

NS_ASSUME_NONNULL_END
