// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRContentFetcherParameters.h"
#import "BZRProductContentFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRProductContentManager, FBRHTTPClient;

/// Provides product content by fetching an archived content from a remote URL, and extracting it
/// to the products' content folder. The fetcher accepts only zip archive files and URL with HTTPS
/// or HTTP schemes.
@interface BZRRemoteContentFetcher : NSObject <BZRProductContentFetcher>

/// Initializes with the default \c fileManager, the default \c contentManger and an HTTP \c client
/// with default parameters.
- (instancetype)init;

/// Initializes with \c fileManager used to delete the archive file after extracting the product
/// content with \c contentManager, and with \c HTTPClient, used to download content from a remote
/// URL.
- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                     contentManager:(BZRProductContentManager *)contentManager
                         HTTPClient:(FBRHTTPClient *)HTTPClient NS_DESIGNATED_INITIALIZER;

@end

/// Additional parameters required for fetching content with \c BZRRemoteContentFetcher.
/// Example of a JSON serialized \c BZRLocalContentFetcherParameters:
/// @code
/// {
///   "type": "BZRRemoteContentFetcher",
///   "URL": "https://foo/bar.zip"
/// }
@interface BZRRemoteContentFetcherParameters : BZRContentFetcherParameters

/// Remote path to the content.
@property (readonly, nonatomic) NSURL *URL;

@end

NS_ASSUME_NONNULL_END
