// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Zur Tene.

#import "PTNImageAsset.h"
#import "PTNImageDataAsset.h"

@protocol PTNResizingStrategy;

@class AVAsset, AVAssetImageGenerator, PTNAVImageGeneratorFactory;

NS_ASSUME_NONNULL_BEGIN

/// \c PTNImageAsset for \c AVFoundation backing asset, the image of \c AVAsset is considered to be
/// its first video frame.
@interface PTNAVImageAsset : NSObject <PTNImageDataAsset>

/// Initializes with the underlying \c asset and \c resizingStrategy to apply on the fetched image.
- (instancetype)initWithAsset:(AVAsset *)asset
             resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy;

/// Initializes with the underlying \c asset, \c imageGeneratorFactory underlying image genarator
/// factory and \c resizingStrategy to apply on the fetched image.
- (instancetype)initWithAsset:(AVAsset *)asset
        imageGeneratorFactory:(PTNAVImageGeneratorFactory *)imageGeneratorFactory
             resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
