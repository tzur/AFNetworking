// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Selector that enables bi-directional selection from a product to its appropriate variant.
@protocol BZRProductsVariantSelector <NSObject>

/// Provides the selected variant for the product specified by \c productIdentifier. If an
/// appropriate variant couldn't be found, \c productIdentifier is returned. If the product
/// specified by \c productIdentifier does not exist, an \c NSInvalidArgumentException is raised.
- (NSString *)selectedVariantForProductWithIdentifier:(NSString *)productIdentifier;

/// Provides the base product for the product specified by \c productIdentifier. If the product is
/// a base product, \c productIdentifier is returned. If the product specified by
/// \c productIdentifier does not exist, an \c NSInvalidArgumentException is raised. If the
/// identifier of the base doesn't exist, an \c NSInternalConsistencyException is raised.
- (NSString *)baseProductForProductWithIdentifier:(NSString *)productIdentifier;

@end

NS_ASSUME_NONNULL_END
