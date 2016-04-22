// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFImageProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Provider of images located in Asset Catalogs and bundles. Any asset loaded with
/// <tt>+[UIImage imageNamed:]</tt> can also be loaded by this provider, using the same asset name
/// as its URL.
///
/// Images in asset catalogs are referenced by their asset names, exactly as in
/// <tt>+[UIImage imageNamed:]</tt>.
///
/// Images stored as files are referenced either by file URL (either absolute or relative to the
/// main bundle), or <file URL to bundle>#<path to image in the bundle>.
///
/// Example URLs:
///
/// <tt>
/// asset
///
/// asset.jpg
///
/// /path/to/asset.jpg
///
/// //url/to/bundle#asset
///
/// //url/to/bundle#asset.jpg
/// </tt>
///
/// @note URL queries are not supported and are silently ignored.
@interface WFAssetCatalogImageProvider : NSObject <WFImageProvider>
@end

NS_ASSUME_NONNULL_END
