// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsVariantSelector.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRProduct;

/// Selector that selects variants according to the locale of the product.
@interface BZRLocaleBasedVariantSelector : NSObject <BZRProductsVariantSelector>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c productDictionary, used to verify that products exist, and with
/// \c countryToTier, used to get the correct variant for the locale of the product.
/// \c countryToTier maps a country code (like "US", "IL") to a tier which specify the active
/// variant for that country.
- (instancetype)initWithProductDictionary:(BZRProductDictionary *)productDictionary
    countryToTier:(NSDictionary<NSString *, NSString *> *)countryToTier NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
