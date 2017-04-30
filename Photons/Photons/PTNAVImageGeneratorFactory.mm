// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Zur Tene.

#import "PTNAVImageGeneratorFactory.h"

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@implementation PTNAVImageGeneratorFactory

- (AVAssetImageGenerator *)imageGeneratorForAsset:(AVAsset *)asset {
  return [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
}

@end

NS_ASSUME_NONNULL_END
