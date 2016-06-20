// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitFetcher.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake fetcher for easier PhotoKit integration testing.
@interface PTNPhotoKitFakeFetcher : NSObject <PTNPhotoKitFetcher>

/// Registers the given \c assets to the given \c assetCollection. If a registration already exists,
/// it will be replaced.
- (void)registerAssets:(NSArray<PHAsset *> *)assets
   withAssetCollection:(PHAssetCollection *)assetCollection;

/// Registers the given \c assetCollections with the \c type and \c subtype asset collection query.
/// If a registration already exists, it will be replaced.
- (void)registerAssetCollections:(NSArray<PHAssetCollection *> *)assetCollections
                        withType:(PHAssetCollectionType)type
                      andSubtype:(PHAssetCollectionSubtype)subtype;

/// Registers the given \c collectionList with \c assetCollections. If a registration already exists
/// it will be replaced.
- (void)registerCollectionList:(PHCollectionList *)collectionList
          withAssetCollections:(NSArray<PHCollection *> *)assetCollections;

/// Registers the given \c assetCollections with \c collectionList. If a registration already exists
/// it will be replaced. Registering and fetching of \c assetCollections is done with the
/// \c localIdentifer of \c collectionList.
- (void)registerAssetCollections:(NSArray<PHAssetCollection *> *)assetCollections
              withCollectionList:(PHCollectionList *)collectionList;

/// Registers the given \c assetCollection so it will be returned when querying for asset
/// collections with a given local identifiers.
- (void)registerAssetCollection:(PHAssetCollection *)assetCollection;

/// Registers the given \c asset so it will be returned when querying for assets with a given local
/// identifiers.
- (void)registerAsset:(PHAsset *)asset;

/// Registers the given \c asset as the key asset of the given \c assetCollection.
- (void)registerAsset:(PHAsset *)asset
    asKeyAssetOfAssetCollection:(PHAssetCollection *)assetCollection;

@end

NS_ASSUME_NONNULL_END
