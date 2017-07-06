// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRProduct;

@protocol BZRProductsVariantSelector;

/// Protocol for creating \c BZRProductsVariantSelector instances.
@protocol BZRProductsVariantSelectorFactory <NSObject>

/// Creates a new instance of \c BZRProductsVariantSelector with the given \c productDictionary
/// and country to tier dictionary loaded with \c fileManager. if the dictionary couldn't be loaded,
/// \c nil is returned.
- (nullable id<BZRProductsVariantSelector>)productsVariantSelectorWithProductDictionary:
    (NSDictionary<NSString *, BZRProduct *> *)productDictionary error:(NSError **)error;

@end

/// Factory that creates a \c BZRProductsVariantSelector object, which is the default variant
/// selector.
@interface BZRProductsVariantSelectorFactory : NSObject <BZRProductsVariantSelectorFactory>
@end

NS_ASSUME_NONNULL_END
