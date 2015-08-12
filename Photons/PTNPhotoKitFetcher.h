// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

/// Adapter which converts class method calls on PhotoKit objects to instance methods for easier
/// testing.
@protocol PTNPhotoKitFetcher <NSObject>

/// Retrieves asset collections of the specified type and subtype.
///
/// @see [PHAssetCollection fetchAssetCollectionsWithType:subtype:options:].
- (PHFetchResult *)fetchAssetCollectionsWithType:(PHAssetCollectionType)type
                                         subtype:(PHAssetCollectionSubtype)subtype
                                         options:(nullable PHFetchOptions *)options;

/// Retrieves asset collections with the specified local identifiers.
///
/// @see [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:options:].
- (PHFetchResult *)fetchAssetCollectionsWithLocalIdentifiers:(NSArray *)identifiers
                                                     options:(nullable PHFetchOptions *)options;

/// Retrieves assets from the specified asset collection.
///
/// @see [PHAsset fetchAssetsInAssetCollection:options:].
- (PHFetchResult *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                        options:(nullable PHFetchOptions *)options;

/// Retrieves assets with the specified local identifiers.
///
/// @see [PHAsset fetchAssetsWithLocalIdentifiers:options:].
- (PHFetchResult *)fetchAssetsWithLocalIdentifiers:(NSArray *)identifiers
                                           options:(nullable PHFetchOptions *)options;


/// Retrieves assets marked as key assets in the specified asset collection.
///
/// @see [PHAsset fetchKeyAssetsInAssetCollection:options:].
- (PHFetchResult *)fetchKeyAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                           options:(nullable PHFetchOptions *)options;

/// Creates a change details object that summarizes the differences between two fetch results.
///
/// @see [PHFetchResultChangeDetails changeDetailsFromFetchResult:toFetchResult:changedObjects:].
- (PHFetchResultChangeDetails *)changeDetailsFromFetchResult:(PHFetchResult *)fromResult
                                               toFetchResult:(PHFetchResult *)toResult
                                              changedObjects:(NSArray *)changedObjects;


@end

/// Implementation of \c PTNPhotoKitFetcher by passing through the messages to the appropriate class
/// method in PhotoKit.
@interface PTNPhotoKitFetcher : NSObject <PTNPhotoKitFetcher>
@end

NS_ASSUME_NONNULL_END
