// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PhotoKit+Photons.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <mutex>

#import "NSURL+PhotoKit.h"

NS_ASSUME_NONNULL_BEGIN

/// Category used to seamlessly access undocumented API.
@interface PHAsset (UniformTypeIdentifier)

/// Undocumented method returning the UTI of this asset. In case where the asset has multiple
/// resources, it returns the UTI of the first resource. That means that assets that have multiple
/// resources like both JPEG and RAW resources, will have the UTI of the first resources. Other
/// resources will be ignored.
- (NSString *)uniformTypeIdentifier;

/// Undocumented method returning the file name of this asset. In case where the asset has multiple
/// resources, it returns the file name of the first resource.
///
/// @important since the PTNAssetDescriptor protocol requires this undocumented method which is
/// already implemented on \c PHAsset, there's no way to gracefully check if the selector is
/// implemented and return \c nil instead. However, this selector is available since the iOS 8.0,
/// where PhotoKit was introduced, so up to new iOS versions there's no worry that calling this
/// selector will crash the app.
- (nullable NSString *)filename;

@end

/// Returns \c YES if \c conformsToUTI is an ancestor of \c uti in the UTI hierarchy. For example,
/// the UTI "com.nikon.raw-image" conforms to "com.nikon.raw-image". Note that any UTI conforms to
/// itself, i.e. "com.compuserve.gif" conforms to "com.compuserve.gif".
static BOOL PTUConformsToUTI(NSString *uti, NSString *conformsToUTI) {
  static dispatch_once_t onceToken;
  static NSMutableDictionary<NSString *, NSNumber *> *cache;
  static std::mutex mutex;
  dispatch_once(&onceToken, ^{
    cache = [NSMutableDictionary dictionary];
  });

  // Colon is not a legal UTI character, so it can be used as a separator.
  // https://developer.apple.com/library/content/documentation/FileManagement/Conceptual/understanding_utis/understand_utis_conc/understand_utis_conc.html
  NSString *joinedUTI = [@[uti, conformsToUTI] componentsJoinedByString:@":"];

  std::lock_guard<std::mutex> lock(mutex);
  NSNumber * _Nullable conforms = cache[joinedUTI];
  if (!conforms) {
    conforms = @(UTTypeConformsTo((__bridge CFStringRef)uti, (__bridge CFStringRef)conformsToUTI));
    cache[joinedUTI] = conforms;
  }

  return [conforms boolValue];
}

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
    [set addObject:kPTNDescriptorTraitAudiovisualKey];
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
    return PTUConformsToUTI(self.uniformTypeIdentifier ,(NSString *)kUTTypeRawImage);
  }
  return NO;
}

- (BOOL)ptn_isGIF {
  if ([self respondsToSelector:@selector(uniformTypeIdentifier)]) {
    return PTUConformsToUTI(self.uniformTypeIdentifier, (NSString *)kUTTypeGIF);
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
