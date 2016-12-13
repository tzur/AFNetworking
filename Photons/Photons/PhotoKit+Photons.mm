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

- (PTNDescriptorCapabilities)descriptorCapabilities {
  return [self canPerformEditOperation:PHAssetEditOperationDelete] ?
      PTNDescriptorCapabilityDelete : PTNDescriptorCapabilityNone;
}

- (PTNAssetDescriptorCapabilities)assetDescriptorCapabilities {
  return PTNAssetDescriptorCapabilityFavorite;
}

- (NSSet<NSString *> *)descriptorTraits {
  NSMutableSet *set = [NSMutableSet set];
  if (self.sourceType == PHAssetSourceTypeCloudShared) {
      [set addObject:kPTNDescriptorTraitCloudBasedKey];
  }
  if (self.mediaType == PHAssetMediaTypeVideo) {
    [set addObject:kPTNDescriptorTraitVideoKey];
  }
  return set;
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

- (PTNDescriptorCapabilities)descriptorCapabilities {
  return [self canPerformEditOperation:PHCollectionEditOperationDelete] ?
      PTNDescriptorCapabilityDelete : PTNDescriptorCapabilityNone;
}

- (PTNAlbumDescriptorCapabilities)albumDescriptorCapabilities {
  return [self canPerformEditOperation:PHCollectionEditOperationRemoveContent] ?
      PTNAlbumDescriptorCapabilityRemoveContent : PTNAlbumDescriptorCapabilityNone;
}

- (NSSet<NSString *> *)descriptorTraits {
  return [NSSet set];
}

@end

NS_ASSUME_NONNULL_END
