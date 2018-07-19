// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PhotoKit+Photons.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <mutex>

#import "NSString+UTI.h"
#import "NSURL+PhotoKit.h"

NS_ASSUME_NONNULL_BEGIN

/// Category used to seamlessly access undocumented API.
@interface PHAsset (UniformTypeIdentifier)

/// Undocumented method returning the UTI of this asset. In case where the asset has multiple
/// resources, it returns the UTI of the first resource. That means that assets that have multiple
/// resources like both JPEG and RAW resources, will have the UTI of the first resources. Other
/// resources will be ignored.
///
/// @note This method might return \c nil in unknown situations.
- (nullable NSString *)uniformTypeIdentifier;

/// Undocumented method returning the file name of this asset. In case where the asset has multiple
/// resources, it returns the file name of the first resource.
///
/// @important since the PTNAssetDescriptor protocol requires this undocumented method which is
/// already implemented on \c PHAsset, there's no way to gracefully check if the selector is
/// implemented and return \c nil instead. However, this selector is available since the iOS 8.0,
/// where PhotoKit was introduced, so up to new iOS versions there's no worry that calling this
/// selector will crash the app.
- (nullable NSString *)filename;

/// Undocumented method returning the kind of the cloud placeholder this asset represents. It seems
/// that PhotoKit uses placeholders when iCloud Photo Library is turned on but the asset's full data
/// is not located on the device. Once the cloud asset is downloaded it replaces this asset with
/// another asset that has a different \c cloudPlaceholderKind.
///
/// From code inspection and some dynamic reverse engineering, it seems that values of \c 3 and
/// \c 4 represent an asset that's not downloaded yet, while \c 5 represents an asset that's fully
/// available on the device.
///
/// @note the \c int value is probably represented as an enum in the actual code, but such data
/// is not available in the binary.
@property (readonly, nonatomic) int cloudPlaceholderKind API_AVAILABLE(ios(8.2));

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
  if (self.cloudPlaceholderKind == 3 || self.cloudPlaceholderKind == 4) {
    [set addObject:kPTNDescriptorTraitCloudBasedKey];
  }
  if (self.mediaType == PHAssetMediaTypeVideo) {
    [set addObject:kPTNDescriptorTraitAudiovisualKey];
  }
  if (@available(iOS 9.1, *)) {
    if (self.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
      [set addObject:kPTNDescriptorTraitLivePhotoKey];
    }
  }
  if ([self ptn_hasUniformTypeIdentifier]) {
    if ([nn(self.uniformTypeIdentifier) ptn_isRawImageUTI]) {
      [set addObject:kPTNDescriptorTraitRawKey];
    }
    if ([nn(self.uniformTypeIdentifier) ptn_isGIFUTI]) {
      [set addObject:kPTNDescriptorTraitGIFKey];
    }
  }
  return set;
}

- (BOOL)ptn_hasUniformTypeIdentifier {
  return [self respondsToSelector:@selector(uniformTypeIdentifier)] && self.uniformTypeIdentifier;
}

- (nullable NSString *)artist {
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
