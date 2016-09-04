// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRContentFetcherParameters, BZRProduct;

/// Returns a \c BZRProduct with identifier set to \c identifier with content.
BZRProduct *BZRProductWithIdentifierAndContent(NSString *identifier);

/// Returns a \c BZRProduct with identifier set to \c identifier without content.
BZRProduct *BZRProductWithIdentifier(NSString *identifier);

/// Returns a \c BZRProduct with identifier set to \c identifier and with
/// \c contentProviderParameters set to \c parameters.
BZRProduct *BZRProductWithIdentifierAndParameters(NSString *identifier,
    BZRContentFetcherParameters * _Nullable parameters);

NS_ASSUME_NONNULL_END
