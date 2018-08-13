// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Category that adds methods for getting a description of the transaction.
@interface SKPaymentTransaction (Bazaar)

/// Returns a description of the transaction with some of its properties.
- (NSDictionary *)bzr_transactionInfo;

/// Transaction state represented as a string.
@property (readonly, nonatomic) NSString *transactionStateString;

@end

NS_ASSUME_NONNULL_END
