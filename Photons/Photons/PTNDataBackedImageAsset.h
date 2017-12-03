// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNImageAsset.h"
#import "PTNImageDataAsset.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNResizingStrategy;

@class PTNImageResizer;

/// Image asset backed by an \c NSData buffer.
///
/// @note \c saveToFile: will trigger a file write operation, \c fetchImage will decode the image
/// from the given \c data. \c fetchData will return the data.
@interface PTNDataBackedImageAsset : NSObject <PTNImageDataAsset, PTNImageAsset>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c data to be treated as the raw image data and \c uniformTypeIdentifier as the
/// uniform type identifier of \c data, \c resizer used to resize the data according
/// to \c resizingStrategy.
- (instancetype)initWithData:(NSData *)data
       uniformTypeIdentifier:(nullable NSString *)uniformTypeIdentifier
                     resizer:(PTNImageResizer *)resizer
            resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy NS_DESIGNATED_INITIALIZER;

/// Initializes with \c data to be treated as the raw image data. \c uniformTypeIdentifier as the
/// uniform type identifier of \c data. The image is sized according to \c resizingStrategy using
/// the default implementation of \c PTNImageResizer.
/// @see -[PTNDataBackedImageAsset initWithData:uniformTypeIdentifier:resizer:resizingStrategy].
- (instancetype)initWithData:(NSData *)data
       uniformTypeIdentifier:(nullable NSString *)uniformTypeIdentifier
            resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy;

/// Initializes with \c data to be treated as the raw image data sized according to
/// \c resizingStrategy using \c resizer. \c uniformTypeIdentifier is set to \c nil.
/// @see -[PTNDataBackedImageAsset initWithData:uniformTypeIdentifier:resizer:resizingStrategy].
- (instancetype)initWithData:(NSData *)data
                     resizer:(PTNImageResizer *)resizer
            resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy;

/// Initializes with \c data to be treated as the raw image data sized according to
/// \c resizingStrategy using the default implementation of \c PTNImageResizer.
/// \c uniformTypeIdentifier is set to \c nil.
/// @see -[PTNDataBackedImageAsset initWithData:uniformTypeIdentifier:resizer:resizingStrategy].
- (instancetype)initWithData:(NSData *)data
            resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy;

/// Initializes with \c data to be treated as the raw image data and \c uniformTypeIdentifier as the
/// uniform type identifier of \c data, the image is sized according to the identity resizing
/// strategy and the default implementation of \c PTNImagerResizer.
- (instancetype)initWithData:(NSData *)data
       uniformTypeIdentifier:(nullable NSString *)uniformTypeIdentifier;

/// Initializes with \c data to be treated as the raw image data sized according to the identity
/// resizing strategy and the default implementation of \c PTNImagerResizer.
/// \c uniformTypeIdentifier is set to \c nil.
/// @see -[PTNDataBackedImageAsset initWithData:uniformTypeIdentifier:resizer:resizingStrategy].
- (instancetype)initWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
