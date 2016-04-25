// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataAsset.h"
#import "PTNImageAsset.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNResizingStrategy;

@class PTNImageResizer;

/// Image asset backed by an \c NSData buffer.
///
/// @note \c saveToFile: will trigger a file write operation, \c fetchImage will decode the image
/// from the given \c data.
@interface PTNDataBackedImageAsset : NSObject <PTNDataAsset, PTNImageAsset>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c data to be treated as the raw image data and \c resizer used to resize the
/// data according to \c resizingStrategy.
- (instancetype)initWithData:(NSData *)data resizer:(PTNImageResizer *)resizer
            resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy NS_DESIGNATED_INITIALIZER;

/// Initializes with \c data to be treated as the raw image data sized according to
/// \c resizingStrategy using the default implementation of \c PTNImageResizier.
/// @see -[PTNDataBackedImageAsset initWithData:resizier:resizingStrategy].
- (instancetype)initWithData:(NSData *)data
            resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy;

/// Initializes with \c data to be treated as the raw image data sized according to the identity
/// resizing strategy and the default implementation of \c PTNImagerResizer.
/// @see -[PTNDataBackedImageAsset initWithData:resizier:resizingStrategy].
- (instancetype)initWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
