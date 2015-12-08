// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PhotoKit+Photons.h"

#import "NSURL+PhotoKit.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PHAsset (Photons)

- (NSURL *)ptn_identifier {
  return [NSURL ptn_photoKitAssetURLWithAsset:self];
}

- (nullable NSString *)localizedTitle {
  return nil;
}

@end

@implementation PHCollection (Photons)

- (NSURL *)ptn_identifier {
  return [NSURL ptn_photoKitAlbumURLWithCollection:self];
}

- (NSUInteger)assetCount {
  if (![self isKindOfClass:[PHAssetCollection class]]) {
    return PTNNotFound;
  }
  
  NSUInteger estimatedAssetCount = [(PHAssetCollection *)self estimatedAssetCount];
  return estimatedAssetCount != NSNotFound ? estimatedAssetCount : PTNNotFound;
}

@end

NS_ASSUME_NONNULL_END
