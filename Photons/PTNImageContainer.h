// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@class PTNImageMetadata;

NS_ASSUME_NONNULL_BEGIN

/// Value class which transfers a \c UIImage and its corresponding \c PTNImageMetadata.
@interface PTNImageContainer : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a \c PTNProgress object with \c image as its image value.
- (instancetype)initWithImage:(UIImage *)image;

/// Initializes a \c PTNProgress object with \c image as its image value and \c metadata as its
/// corresponding image metadata.
- (instancetype)initWithImage:(UIImage *)image
                     metadata:(nullable PTNImageMetadata *)metadata NS_DESIGNATED_INITIALIZER;

/// Image object containing the image data.
@property (readonly, nonatomic) UIImage *image;

/// Image metadata corresponding to \c image.
@property (readonly, nonatomic, nullable) PTNImageMetadata *metadata;

@end

NS_ASSUME_NONNULL_END
