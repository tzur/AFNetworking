// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataAsset.h"
#import "PTNImageAsset.h"
#import "PTNImageDataAsset.h"

NS_ASSUME_NONNULL_BEGIN

/// Image asset backed by a file.
///
/// @note This asset assumes that the file at the given path doesn't change its location or contents
/// while the asset exists. If underlying data or location does change the asset's behavior is
/// undefined.
///
/// @note \c saveToFile: will trigger a file copying operation, \c fetchImage will trigger a file
/// read operation from \c path, followed by decoding of the image from the retrieved data.
@interface PTNFileBackedImageAsset : NSObject <PTNImageDataAsset>

/// Initializes with file located at \c path, \c fileManager, \c resizer and \c resizingStrategy.
/// \c fileManager will be used to handle file system interaction. \c resizer and
/// \c resizingStrategy will be used when fetching the underlying image.  \c PTNResizingStrategy is
/// required for optimization; it allows a single underlying file to be shared by multiple instances
/// of \c PTNImageAsset conforming classes, each using a different resizing strategy to resolve the
/// desired size from the original.
///
/// If \c resizingStrategy is \c nil, the identity resizing strategy is used.
- (instancetype)initWithFilePath:(LTPath *)path fileManager:(NSFileManager *)fileManager
                    imageResizer:(PTNImageResizer *)resizier
                resizingStrategy:(nullable id<PTNResizingStrategy>)resizingStrategy;

@end

NS_ASSUME_NONNULL_END
