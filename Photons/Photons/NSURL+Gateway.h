// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// URL category for gateway albums that enable wrapping of real albums by a proxy directory that
/// maps to them. This enables cleaner access to sources' root directories without mixing the assets
/// of multiple sources.
@interface NSURL (Gateway)

/// The URL scheme associated with gateway URLs.
+ (NSString *)ptn_gatewayScheme;

/// Unique identifier URL of a gateway asset identified by a unique \c key.
+ (NSURL *)ptn_gatewayAlbumURLWithKey:(NSString *)key;

/// Unique key associated with this Gateway URL or \c nil if this URL does not have a Gateway key.
- (nullable NSString *)ptn_gatewayKey;

@end

NS_ASSUME_NONNULL_END
