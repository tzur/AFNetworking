// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "SKPaymentTransaction+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

#define BZREnumToStringMapping(enum_value) @(enum_value): @#enum_value

@implementation SKPaymentTransaction (Bazaar)

- (NSDictionary *)bzr_transactionInfo {
  return @{
    @keypath(self.payment, productIdentifier): self.payment.productIdentifier,
    @keypath(self.payment, quantity): @(self.payment.quantity),
    @keypath(self, transactionDate): self.transactionDate ?: [NSNull null],
    @keypath(self, transactionIdentifier): self.transactionIdentifier ?: [NSNull null],
    @keypath(self, transactionState): self.transactionStateString,
    @keypath(self, originalTransaction):
        self.originalTransaction.bzr_transactionInfo ?: [NSNull null]
  };
}

- (NSString *)transactionStateString {
  static auto const transactionStateStringMapping = @{
    BZREnumToStringMapping(SKPaymentTransactionStatePurchasing),
    BZREnumToStringMapping(SKPaymentTransactionStatePurchased),
    BZREnumToStringMapping(SKPaymentTransactionStateFailed),
    BZREnumToStringMapping(SKPaymentTransactionStateRestored),
    BZREnumToStringMapping(SKPaymentTransactionStateDeferred)
  };

  return transactionStateStringMapping[@(self.transactionState)];
}

@end

NS_ASSUME_NONNULL_END
