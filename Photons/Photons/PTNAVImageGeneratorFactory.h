// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Zur Tene.

@class AVAsset, AVAssetImageGenerator;

NS_ASSUME_NONNULL_BEGIN

/// Factory for creating \c AVAssetImageGenerator.
@interface PTNAVImageGeneratorFactory : NSObject

/// Creates \c AVAssetImageGenerator from the given \c asset.
- (AVAssetImageGenerator *)imageGeneratorForAsset:(AVAsset *)asset;

@end

NS_ASSUME_NONNULL_END
