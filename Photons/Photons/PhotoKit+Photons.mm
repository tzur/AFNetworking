// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PhotoKit+Photons.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import "NSURL+PhotoKit.h"

NS_ASSUME_NONNULL_BEGIN

/// Category used to seamlessly access undocumented API.
@interface PHAsset (UniformTypeIdentifier)

/// Undocumented method returning the UTI of this asset. In case where the asset has multiple
/// resources, it returns the UTI of the first resource. That means that assets that have multiple
/// resources like both JPEG and RAW resources, will have the UTI of the first resources. Other
/// resources will be ignored.
- (NSString *)uniformTypeIdentifier;

@end

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
  if ([self ptn_isRaw]) {
    [set addObject:kPTNDescriptorTraitRawKey];
  }
  if ([self ptn_isGIF]) {
    [set addObject:kPTNDescriptorTraitGIFKey];
  }
  return set;
}

- (BOOL)ptn_isRaw {
  if ([self respondsToSelector:@selector(uniformTypeIdentifier)]) {
    return (UTTypeConformsTo((__bridge CFStringRef)self.uniformTypeIdentifier, kUTTypeRawImage));
  }
  return NO;
}

- (BOOL)ptn_isGIF {
  if ([self respondsToSelector:@selector(uniformTypeIdentifier)]) {
    return (UTTypeConformsTo((__bridge CFStringRef)self.uniformTypeIdentifier, kUTTypeGIF));
  }
  return NO;
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
