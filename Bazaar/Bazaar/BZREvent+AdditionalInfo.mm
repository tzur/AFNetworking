// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREvent+AdditionalInfo.h"

#import "BZRReceiptValidationStatus.h"
#import "SKPaymentTransaction+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kBZREventAppStoreLocale = @"BZREventAppStoreLocale";
NSString * const kBZREventApplicationBundleID = @"BZREventApplicationBundleID";
NSString * const kBZREventCachingDate = @"BZREventCachingDate";
NSString * const kBZREventFirstErrorDate = @"BZREventFirstErrorDate";
NSString * const kBZREventReceiptValidationStatus = @"BZREventReceiptValidationStatus";
NSString * const kBZREventReceiptValidationRequestId = @"BZREventReceiptValidationRequestId";
NSString * const kBZREventProductIdentifier = @"BZREventProductIdentifier";
NSString * const kBZREventPromotedIAPAborted = @"BZREventPromotedIAPAborted";
NSString * const kBZREventPurchaseDate = @"BZREventPurchaseDate";
NSString * const kBZREventTransactionQuantity = @"BZREventTransactionQuantity";
NSString * const kBZREventTransactionDate = @"BZREventTransactionDate";
NSString * const kBZREventTransactionIdentifier = @"BZREventTransactionIdentifier";
NSString * const kBZREventTransactionState = @"BZREventTransactionState";
NSString * const kBZREventValidatricksRequestID = @"BZREventValidatricksRequestID";
NSString * const kBZREventOriginalTransactionIdentifier = @"BZREventOriginalTransactionIdentifier";
NSString * const kBZREventTransactionRemoved = @"BZREventTransactionRemoved";

@implementation BZREvent (AdditionalInfo)

+ (instancetype)receiptValidationStatusReceivedEvent:
    (BZRReceiptValidationStatus *)receiptValidationStatus
    requestId:(nullable NSString *)requestId {
  return [[BZREvent alloc] initWithType:$(BZREventTypeReceiptValidationStatusReceived)
      eventInfo:@{
        kBZREventReceiptValidationRequestId: requestId,
        kBZREventReceiptValidationStatus: receiptValidationStatus
      }];
}

+ (instancetype)transactionReceivedEvent:(SKPaymentTransaction *)transaction
                      removedTransaction:(BOOL)removedTransaction {
return [[BZREvent alloc] initWithType:$(BZREventTypeInformational)
                         eventSubtype:@"TransactionReceived" eventInfo:@{
  kBZREventProductIdentifier: transaction.payment.productIdentifier,
  kBZREventTransactionQuantity: @(transaction.payment.quantity),
  kBZREventTransactionDate: transaction.transactionDate ?: [NSNull null],
  kBZREventTransactionIdentifier: transaction.transactionIdentifier ?: [NSNull null],
  kBZREventTransactionState: transaction.transactionStateString,
  kBZREventOriginalTransactionIdentifier:
      transaction.originalTransaction.transactionIdentifier ?: [NSNull null],
  kBZREventTransactionRemoved: @(removedTransaction)
 }];
}

- (nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  return self.eventInfo[kBZREventReceiptValidationStatus];
}

- (nullable NSString *)receiptValidationRequestId {
  return self.eventInfo[kBZREventReceiptValidationRequestId];
}

@end

NS_ASSUME_NONNULL_END
