// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPClient;

/// Asset manager for fetching Ocean based assets. Supported URLs for album and descriptor fetching
/// should have <tt>[NSURL ptn_oceanScheme]</tt> scheme, \c album or \c asset host and \c phrase or
/// \c id query parameters, respectively. Fetching images data and audiovisual assets is
/// unsupported.
@interface PTNOceanAssetManager : NSObject <PTNAssetManager>

/// Initializes with the default \c FBRHTTPClient.
- (instancetype)init;

/// Initializes with the given \c client.
- (instancetype)initWithClient:(FBRHTTPClient *)client NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
