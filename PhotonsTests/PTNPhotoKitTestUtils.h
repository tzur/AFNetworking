// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Creates a fake PhotoKit asset collection with the given \c name.
id PTNPhotoKitCreateAssetCollection(NSString *name);

/// Creates a fake PhotoKit asset.
id PTNPhotoKitCreateAsset(NSString *localIdentifier);

/// Creates a \c PHFetchResultChangeDetails that returns the \c assets array for its
/// \c fetchResultAfterChanges property.
PHFetchResultChangeDetails *PTNPhotoKitCreateChangeDetailsForAssets(NSArray<PHAsset *> *assets);

/// Creates a \c PHObjectChangeDetails that returns \c asset for its \c objectAfterChanges property.
PHObjectChangeDetails *PTNPhotoKitCreateChangeDetailsForAsset(PHAsset *asset);

/// Creates a \c PHChange that always returns the given \c changeDetails.
PHChange *PTNPhotoKitCreateChangeForFetchDetails(PHFetchResultChangeDetails *changeDetails);

/// Creates a \c PHChange that always returns the given \c changeDetails.
PHChange *PTNPhotoKitCreateChangeForObjectDetails(PHObjectChangeDetails *changeDetails);
