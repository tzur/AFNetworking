// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Adds convenience method to query whether a product has been purchased.
@interface BZRReceiptInfo (ProductPurchased)

/// Returns \c YES if the product has been purchased and \c NO otherwise.
- (BOOL)wasProductPurchased:(NSString *)productIdentifier;

@end

NS_ASSUME_NONNULL_END
