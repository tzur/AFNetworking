// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Holds a description of the price of a product.
@interface BZRProductPriceInfo : BZRModel <MTLJSONSerializing>

/// Price of the product (without the locale).
@property (readonly, nonatomic) NSDecimalNumber *price;

/// Identifier of the product's price locale.
@property (readonly, nonatomic) NSString *localeIdentifier;

@end

NS_ASSUME_NONNULL_END
