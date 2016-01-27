// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Creates a fake PhotoKit asset collection with the given \c name.
/// If a \c nil \c name is passed the asset collection's \c localIdentifier property will be \c nil.
PHAssetCollection *PTNPhotoKitCreateAssetCollection(NSString * _Nullable name);

/// Creates a fake PhotoKit asset.
/// If a \c nil \c localIdentifier is passed the asset's \c localIdentifier property will be \c nil.
PHAsset *PTNPhotoKitCreateAsset(NSString * _Nullable localIdentifier);

/// Creates a fake PhotoKit asset with \c pixelWidth and \c pixelHeight properties as specified by
/// \c size.
id PTNPhotoKitCreateAssetWithSize(NSString *localIdentifier, CGSize size);

/// Creates a fake PhotoKit asset with \c -[PHAsset requestContentEditingInput:completion:]
/// capabilities. The request's completion block will be invoked with \c contentEditingInput and
/// \c contentEditingInfo.
/// if a \c nil \c contentEditingInput or \c contentEditingInfo are passed, these parameters will be
/// nil in the the call to the request's completion block.
PHAsset *PTNPhotoKitCreateAssetForContentEditing(NSString *localIdentifier,
    PHContentEditingInput * _Nullable contentEditingInput,
    NSDictionary * _Nullable contentEditingInfo, PHContentEditingInputRequestID requestID);

/// Creates a \c PHContentEditingInput that returns \c fullSizeImageURL for its \c fullSizeImageURL
/// property.
/// If a \c nil \c fullSizeImageURL is passed the content editing input's \c fullSizeImageURL
/// property will be \c nil.
PHContentEditingInput *PTNPhotoKitCreateContentEditingInput(NSURL * _Nullable fullSizeImageURL);

/// Creates a \c PHFetchResultChangeDetails that returns the \c assets array for its
/// \c fetchResultAfterChanges property.
PHFetchResultChangeDetails *PTNPhotoKitCreateChangeDetailsForAssets(NSArray<PHAsset *> *assets);

/// Creates a \c PHObjectChangeDetails that returns \c asset for its \c objectAfterChanges property.
PHObjectChangeDetails *PTNPhotoKitCreateChangeDetailsForAsset(PHAsset *asset);

/// Creates a \c PHChange that always returns the given \c changeDetails.
PHChange *PTNPhotoKitCreateChangeForFetchDetails(PHFetchResultChangeDetails *changeDetails);

/// Creates a \c PHChange that always returns the given \c changeDetails.
PHChange *PTNPhotoKitCreateChangeForObjectDetails(PHObjectChangeDetails *changeDetails);

NS_ASSUME_NONNULL_END
