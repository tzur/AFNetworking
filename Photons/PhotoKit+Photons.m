// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PhotoKit+Photons.h"

#import "NSURL+PhotoKit.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PHAsset (Photons)

- (NSURL *)ptn_identifier {
  return [NSURL ptn_photoKitAssetURLWithAsset:self];
}

@end

@implementation PHCollection (Photons)

- (NSURL *)ptn_identifier {
  return [NSURL ptn_photoKitAlbumURLWithCollection:self];
}

@end

NS_ASSUME_NONNULL_END
