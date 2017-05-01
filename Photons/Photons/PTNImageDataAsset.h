// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for an image in an \c NSData format, enabling fetching of image data and metadata.
@protocol PTNImageDataAsset <NSObject>

/// Fetches the data of the image backed up by this asset. The returned signal sends a single
/// \c NSData object on an arbitrary thread, and completes. If data can't be fetched the signal errs
/// instead.
///
/// @return <tt>RACSignal<NSData *></tt>.
- (RACSignal *)fetchImageData;

/// Fetches the image metadata of image backed by this asset. The returned signal sends a single
/// \c PTNImageMetadata object on an arbitrary thread, and completes. If the image metadata cannot
/// be fetched the signal errs instead.
///
/// @return <tt>RACSignal<PTNImageMetadata *></tt>.
- (RACSignal *)fetchImageMetadata;

/// The uniform type identifier of the data or \c nil if UTI was not specified.
///
/// @see https://developer.apple.com/library/content/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html
@property (copy, nonatomic, nullable) NSString *uniformTypeIdentifier;

/// The orientation of the image.
@property (nonatomic) UIImageOrientation orientation;

@end

/// Default implementation of \c PTNImageDataAsset.
@interface PTNImageDataAsset : NSObject <PTNImageDataAsset>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c data as the image data. \c uniformTypeIdentifier will be set to \c nil and
/// \c orientation to \c UIImageOrientationUp.
- (instancetype)initWithData:(NSData *)data;

/// Initializes with \c data as the image data, the \c uniformTypeIdentifier of the image and the
/// \c orientation of the image.
- (instancetype)initWithData:(NSData *)data
       uniformTypeIdentifier:(nullable NSString *)uniformTypeIdentifier
                 orientation:(UIImageOrientation)orientation NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
