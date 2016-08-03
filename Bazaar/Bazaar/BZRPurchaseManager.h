// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRPurchase.h"

NS_ASSUME_NONNULL_BEGIN

/// Class for initiating payments and following their corresponding \c SKPaymentTransaction's state
/// in an \c SKPaymentQueue.
@interface BZRPurchaseManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with \c paymentQueue, \c applicationUserId, \c unhandledUpdatesBlock and
/// \c updatesQueue. Payments will be performed on \c paymentQueue which will
/// be observed for updates. \c unhandledUpdatesBlock will be called on
/// \c updatesQueue for every \c SKPaymentTransaction update that does not correspond
/// to an \c SKPayment initiated by this instance of \c BZRPurchaseManager.
///
/// The \c applicationUserId is a user ID provided by the application that uniquely identifies the
/// user (i.e. it must be different for different users and identical for the same user across
/// devices). If it is not \c nil, it will be used when making purchases to assist with
/// fraud detection. For more information about the application user identifier follow this link:
/// https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/RequestPayment.html#//apple_ref/doc/uid/TP40008267-CH4-SW6
- (instancetype)initWithPaymentQueue:(SKPaymentQueue *)paymentQueue
                   applicationUserId:(nullable NSString *)applicationUserId
               unhandledUpdatesBlock:(BZRTransactionUpdateBlock)unhandledUpdatesBlock
                        updatesQueue:(dispatch_queue_t)updatesQueue
    NS_DESIGNATED_INITIALIZER;

/// Initiates a payment for \c product with \c quantity. \c paymentQueue is observed for
// \c SKPaymentTransaction updates, \c updateBlock will be called on \c updatesQueue for every
/// transaction update that belongs to the purchasing process of that payment.
- (void)purchaseProduct:(SKProduct *)product quantity:(NSUInteger)quantity
            updateBlock:(BZRTransactionUpdateBlock)updateBlock;

@end

NS_ASSUME_NONNULL_END
