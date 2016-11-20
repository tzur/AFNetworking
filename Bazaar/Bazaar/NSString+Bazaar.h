// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Category that adds ability to get product identifier of variant of a product and vice versa.
@interface NSString (Bazaar)

/// Creates a new \c NSString with the variant of \c self specified by \c variantSuffix.
- (NSString *)bzr_variantWithSuffix:(NSString *)variantSuffix;

/// Creates a new \c NSString with the identifier of the base product of \c self. If \c self already
/// represents a base product, \c self is returned.
- (NSString *)bzr_baseProductIdentifier;

@end

NS_ASSUME_NONNULL_END
