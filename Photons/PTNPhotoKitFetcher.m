// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNPhotoKitFetcher

- (PHFetchResult *)fetchAssetCollectionsWithType:(PHAssetCollectionType)type
                                         subtype:(PHAssetCollectionSubtype)subtype
                                         options:(nullable PHFetchOptions *)options {
  return [PHAssetCollection fetchAssetCollectionsWithType:type subtype:subtype options:options];
}

- (PHFetchResult *)fetchAssetCollectionsWithLocalIdentifiers:(NSArray *)identifiers
                                                     options:(nullable PHFetchOptions *)options {
  return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:identifiers options:options];
}

- (PHFetchResult *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                        options:(nullable PHFetchOptions *)options {
  return [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
}

@end

NS_ASSUME_NONNULL_END
