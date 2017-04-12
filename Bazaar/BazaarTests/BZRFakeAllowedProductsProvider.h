// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAllowedProductsProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake provider that provides a set of allowed products manually injected to its
/// \c allowedProducts property.
@interface BZRFakeAllowedProductsProvider : BZRAllowedProductsProvider

/// Initializes the receiver with mock providers.
- (instancetype)init;

/// A replaceable allowed products set.
@property (strong, nonatomic) NSSet<NSString *> *allowedProducts;

@end

NS_ASSUME_NONNULL_END
