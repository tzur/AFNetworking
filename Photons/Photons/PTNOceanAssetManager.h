// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNCacheAwareAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNOceanClient;

@protocol LTDateProvider;

/// Asset manager for fetching Ocean based assets. Supported URLs for album and descriptor fetching
/// should have <tt>[NSURL ptn_oceanScheme]</tt> scheme, \c album or \c asset host and \c phrase or
/// \c id query parameters, respectively.
///
/// Albums returned by this manager will be set with maximum age for caching of five
/// minutes, album descriptors with maximum possible age and asset related ones will be set with
/// maximum age of a single day.
@interface PTNOceanAssetManager : NSObject <PTNCacheAwareAssetManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c APIKey which is used to initialize \c FBRHTTPClient and the default
/// \c LTDateProvider. \c preferredImageDataPixelCount and \c preferredImageDataPixelCount are set
/// to NSUIntegerMax.
- (instancetype)initWithAPIKey:(NSString *)APIKey;

/// Initializes with \c APIKey which is used to initialize \c FBRHTTPClient and the default
/// \c LTDateProvider. \c preferredImageDataPixelCount and \c preferredImageDataPixelCount are the
/// preferred sizes for image data and video data respectively. When fetching the data of a
/// descriptor, the asset with the closest pixel count to these values is fetched.
- (instancetype)initWithAPIKey:(NSString *)APIKey
  preferredImageDataPixelCount:(NSUInteger)preferredImageDataPixelCount
  preferredVideoDataPixelCount:(NSUInteger)preferredVideoDataPixelCount;

/// Initializes with the given \c client and \c date Provider. The given \c dateProvider is used for
/// providing initial date reference for the maximum ages of the cached objects.
/// \c preferredImageDataPixelCount and \c preferredImageDataPixelCount are the preferred sizes for
/// image data and video data respectively. When fetching the data of a descriptor, the asset with
/// the closest pixel count to these values is fetched.
- (instancetype)initWithClient:(PTNOceanClient *)client
                  dateProvider:(id<LTDateProvider>)dateProvider
  preferredImageDataPixelCount:(NSUInteger)preferredImageDataPixelCount
  preferredVideoDataPixelCount:(NSUInteger)preferredVideoDataPixelCount NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
