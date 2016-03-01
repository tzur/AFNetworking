// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAssetManager.h"

@class PTNDropboxRestClient, PTNDropboxThumbnailType, PTNImageResizer;

@protocol PTNDropboxPathProvider;

NS_ASSUME_NONNULL_BEGIN

/// Asset manager which backs Dropbox assets.
///
/// @note When fetching images with \c PTNImageDeliveryModeFast and
/// \c PTNImageDeliveryModeOpportunistic the low quality version of an image is made by fetching a
/// 32 by 32 thumbnail of the fetched file. This is only possible when fetching the latest version
/// of a file, since thumbnails of pervious revisions are not available from the Dropbox SDK.
@interface PTNDropboxAssetManager : NSObject <PTNAssetManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c dropboxClient as the interface to the Dropbox SDK and \c imageResizer and
/// \c fileManager to be used when creating image assets.
- (instancetype)initWithDropboxClient:(PTNDropboxRestClient *)dropboxClient
                         imageResizer:(PTNImageResizer *)imageResizer
                          fileManager:(NSFileManager *)fileManager NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
