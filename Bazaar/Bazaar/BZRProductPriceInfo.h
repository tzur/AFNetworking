// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Holds a description of the price of a product.
@interface BZRProductPriceInfo : BZRModel <MTLJSONSerializing>

/// Price of the product (without the locale).
@property (readonly, nonatomic) NSDecimalNumber *price;

/// Three-letter currency code of product's price. For example "USD", "ILS", "RUB".
@property (readonly, nonatomic) NSString *currencyCode;

/// Localized Price of the product with the locale.
@property (readonly, nonatomic) NSString *localizedPrice;

@end

NS_ASSUME_NONNULL_END
