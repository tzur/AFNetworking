// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRContentFetcherParameters.h"
#import "BZRProductContentFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRModel, BZRProductContentManager;

/// Provides product content by fetching an archived content from a local path, and extracting it
/// to the products' content folder.
@interface BZRLocalContentFetcher : NSObject <BZRProductContentFetcher>

/// Initializes with default \c fileManager and \c contentManager.
- (instancetype)init;

/// Initializes with \c fileManager, used to copy the content with, and \c contentManager used to
/// extract content from an archive.
- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                     contentManager:(BZRProductContentManager *)contentManager
    NS_DESIGNATED_INITIALIZER;

@end

/// Additional parameters required for fetching content with \c BZRLocalContentFetcher.
///
/// Example of a JSON serialized \c BZRLocalContentFetcherParameters:
/// @code
/// {
///   "type": "BZRLocalContentFetcher",
///   "URL": "file:///foo/bar.zip"
/// }
@interface BZRLocalContentFetcherParameters : BZRContentFetcherParameters

/// Local path to the content file.
@property (readonly, nonatomic) NSURL *URL;

@end

NS_ASSUME_NONNULL_END
