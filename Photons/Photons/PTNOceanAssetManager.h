// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNCacheAwareAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNDateProvider, PTNOceanClient;

/// Asset manager for fetching Ocean based assets. Supported URLs for album and descriptor fetching
/// should have <tt>[NSURL ptn_oceanScheme]</tt> scheme, \c album or \c asset host and \c phrase or
/// \c id query parameters, respectively.
///
/// Albums returned by this manager will be set with maximum age for caching of five
/// minutes, album descriptors with maximum possible age and asset related ones will be set with
/// maximum age of a single day.
@interface PTNOceanAssetManager : NSObject <PTNCacheAwareAssetManager>

/// Initializes with the default \c FBRHTTPClient and \c PTNDateProvider.
- (instancetype)init;

/// Initializes with the given \c client and \c dateProvider. The given \c dateProvider is used for
/// providing initial time reference for the maximum ages of the cached objects.
- (instancetype)initWithClient:(PTNOceanClient *)client
                  dateProvider:(PTNDateProvider *)dateProvider NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
