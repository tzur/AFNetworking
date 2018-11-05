// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREvent.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptValidationStatus, SKPaymentTransaction;

/// Key in the event info dictionary mapping to a boolean flag indicating whether a purchase that
/// was intiated through the App Store is aborted.
extern NSString * const kBZREventPromotedIAPAborted;

/// Key in the event info dictionary mapping to the App Store locale.
extern NSString * const kBZREventAppStoreLocale;

/// Key in the event info dictionary mapping to bundle ID of an application.
extern NSString * const kBZREventApplicationBundleID;

/// Key in the event info dictionary mapping to caching date of a receipt validation status.
extern NSString * const kBZREventCachingDate;

/// Key in the event info dictionary mapping to the first error date in receipt validation.
extern NSString * const kBZREventFirstErrorDate;

/// Key in the event info dictionary mapping to a product's identifier. The product identifier may
/// be sent as additional information in another event, e.g. transaction event.
extern NSString * const kBZREventProductIdentifier;

/// Key in the event info dictionary mapping to the purchase date of a product.
extern NSString * const kBZREventPurchaseDate;

/// Key in the event info dictionary mapping to a transaction's quantity.
extern NSString * const kBZREventTransactionQuantity;

/// Key in the event info dictionary mapping to a transaction's date.
extern NSString * const kBZREventTransactionDate;

/// Key in the event info dictionary mapping to a transaction's identifier.
extern NSString * const kBZREventTransactionIdentifier;

/// Key in the event info dictionary mapping to a transaction's state.
extern NSString * const kBZREventTransactionState;

/// Key in the event info dictionary mapping to Validatricks Request ID.
extern NSString * const kBZREventValidatricksRequestID;

/// Key in the event info dictionary mapping to an original transaction's identifier.
extern NSString * const kBZREventOriginalTransactionIdentifier;

/// Key in the event info dictionary mapping to a flag indicating whether the transaction is
/// removed.
extern NSString * const kBZREventTransactionRemoved;

/// Adds methods to conveniently create \c BZREvent objects for various types of events.
@interface BZREvent (AdditionalInfo)

/// Creates a \c BZREvent when a receipt validation status is received with the given
/// \c receiptValidationStatus and the given \c requestId.
+ (instancetype)receiptValidationStatusReceivedEvent:
    (BZRReceiptValidationStatus *)receiptValidationStatus
    requestId:(nullable NSString *)requestId;

/// Creates a \c BZREvent when an \c SKPaymentTransaction is received.
+ (instancetype)transactionReceivedEvent:(SKPaymentTransaction *)transaction
                      removedTransaction:(BOOL)removedTransaction;

/// Receipt validation status associated with this event. \c nil if this event is not of
/// \c BZREventTypeReceiptValidationStatusReceived type.
@property (readonly, nonatomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;

/// Request ID of the receipt validation status that triggered sending the event. \c nil if this
/// event is not of \c BZREventTypeReceiptValidationStatusReceived type, or if the receipt
/// validation status doesn't have a \c requestId.
@property (readonly, nonatomic, nullable) NSString *receiptValidationRequestId;

@end

NS_ASSUME_NONNULL_END
