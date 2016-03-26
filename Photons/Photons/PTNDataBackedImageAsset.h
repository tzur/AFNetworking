// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataAsset.h"
#import "PTNImageAsset.h"

NS_ASSUME_NONNULL_BEGIN

/// Image asset backed by an \c NSData buffer.
///
/// @note \c saveToFile: will trigger a file write operation, \c fetchImage will decode the image
/// from the given \c data.
@interface PTNDataBackedImageAsset : NSObject <PTNDataAsset, PTNImageAsset>

/// Initializes with \c data to be treated as the raw image data.
- (instancetype)initWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
