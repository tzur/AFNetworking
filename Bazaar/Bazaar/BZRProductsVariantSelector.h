// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Selector that enables selection from a product to its appropriate variant.
@protocol BZRProductsVariantSelector <NSObject>

/// Provides the selected variant for the product specified by \c productIdentifier. If an
/// appropriate variant couldn't be found, \c productIdentifier is returned. If the product
/// specified by \c productIdentifier does not exist, an \c NSInvalidArgumentException is raised.
- (NSString *)selectedVariantForProductWithIdentifier:(NSString *)productIdentifier;

@end

/// Default selector that returns the given product identifier.
@interface BZRProductsVariantSelector : NSObject <BZRProductsVariantSelector>
@end

NS_ASSUME_NONNULL_END
