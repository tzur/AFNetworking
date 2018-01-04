// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct.h"

NS_ASSUME_NONNULL_BEGIN

/// Category that adds helper methods and properties to associate a \c BZRProduct with an
/// \c SKProduct.
@interface BZRProduct (StoreKit)

/// Creates and returns a new \c BZRProduct instance that is a clone of the receiver and associates
/// it with the given \c storeKitProduct. Besides assigning the \c storeKitProduct to the new
/// product \c underlyingProduct this method will assign additional product metadata provided by
/// StoreKit (if available) such as price information, introductory discount etc.
- (instancetype)productByAssociatingStoreKitProduct:(SKProduct *)storeKitProduct;

/// \c SKProduct product associated with the BZRProduct.
@property (readonly, nonatomic, nullable) SKProduct *underlyingProduct;

@end

NS_ASSUME_NONNULL_END
