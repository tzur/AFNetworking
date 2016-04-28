// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFImageProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Generic asynchronous loader of images. Routes image URL to actual providers based on URL's
/// scheme. URL without a scheme, or an empty scheme are both treated as an empty scheme string.
///
/// In default configuration, supports asset catalogs, bundles and PaintCode.
///
/// Avoid direct dependencies on this class in code that loads images. Use \c id<WFImageProvider>
/// protocol instead.
///
/// @see WFAssetCatalogImageProvider, WFPaintCodeImageProvider.
@interface WFImageLoader : NSObject <WFImageProvider>

/// Initializes the loader with the given dictionary of providers, mapped by URL schemes. A URL
/// is routed to a provider whose key matches the URL's scheme. A single provider instance can be
/// used for a number of different schemes.
///
/// @note schemes must be lowercase.
///
/// @note an empty string scheme matches all URL's without scheme at all, and with empty scheme
/// (that is, \c -[NSURL scheme] can be empty or \c nil).
- (instancetype)initWithProviders:(NSDictionary<NSString *, id<WFImageProvider>> *)providers
    NS_DESIGNATED_INITIALIZER;

/// Initializes the loader with a default configuration, in which images could be loaded from asset
/// catalogs, bundles and PaintCode. See the class documentation for more information.
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
