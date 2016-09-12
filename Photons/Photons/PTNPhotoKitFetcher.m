// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNPhotoKitFetcher

- (PTNAssetCollectionsFetchResult *)fetchAssetCollectionsWithType:(PHAssetCollectionType)type
    subtype:(PHAssetCollectionSubtype)subtype options:(nullable PHFetchOptions *)options {
  return [PHAssetCollection fetchAssetCollectionsWithType:type subtype:subtype options:options];
}

- (PHCollectionList *)transientCollectionListWithCollections:(NSArray<PHCollection *> *)collections
                                                       title:(NSString *)title {
  return [PHCollectionList transientCollectionListWithCollections:collections title:title];
}

- (PTNCollectionsFetchResult *)fetchCollectionsInCollectionList:(PHCollectionList *)collectionList
                                                        options:(nullable PHFetchOptions *)options {
  return [PHCollectionList fetchCollectionsInCollectionList:collectionList options:options];
}

- (PTNAssetCollectionsFetchResult *)fetchAssetCollectionsWithLocalIdentifiers:
    (NSArray<NSString *> *)identifiers options:(nullable PHFetchOptions *)options {
  return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:identifiers options:options];
}

- (PTNAssetsFetchResult *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                               options:(nullable PHFetchOptions *)options {
  return [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
}

- (PTNAssetsFetchResult *)fetchAssetsWithLocalIdentifiers:(NSArray<NSString *> *)identifiers
                                                  options:(nullable PHFetchOptions *)options {
  return [PHAsset fetchAssetsWithLocalIdentifiers:identifiers options:options];
}

- (nullable PTNAssetsFetchResult *)fetchKeyAssetsInAssetCollection:
    (PHAssetCollection *)assetCollection options:(nullable PHFetchOptions *)options {
  return [PHAsset fetchKeyAssetsInAssetCollection:assetCollection options:options];
}

- (PHFetchResultChangeDetails *)changeDetailsFromFetchResult:(PHFetchResult *)fromResult
    toFetchResult:(PHFetchResult *)toResult
    changedObjects:(nullable NSArray<PHObject *> *)changedObjects {
  return [PHFetchResultChangeDetails changeDetailsFromFetchResult:fromResult toFetchResult:toResult
                                                   changedObjects:changedObjects];
}

@end

NS_ASSUME_NONNULL_END
