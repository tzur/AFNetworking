// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

/// \c PHFetchResult backing \c PHAsset objects.
typedef PHFetchResult<PHAsset *> PTNAssetsFetchResult;

/// \c PHFetchResult backing \c PHCollection objects.
typedef PHFetchResult<PHCollection *> PTNCollectionsFetchResult;

/// \c PHFetchResult backing \c PHAssetCollection objects.
typedef PHFetchResult<PHAssetCollection *> PTNAssetCollectionsFetchResult;

/// Adapter which converts class method calls on PhotoKit objects to instance methods for easier
/// testing.
@protocol PTNPhotoKitFetcher <NSObject>

/// Retrieves asset collections of the specified type and subtype.
///
/// @see [PHAssetCollection fetchAssetCollectionsWithType:subtype:options:].
- (PTNAssetCollectionsFetchResult *)fetchAssetCollectionsWithType:(PHAssetCollectionType)type
    subtype:(PHAssetCollectionSubtype)subtype options:(nullable PHFetchOptions *)options;

/// Retrieves a temporary collection list that contains the specified asset collections.
///
/// @see [PHCollectionList transientCollectionListWithCollections:title:].
- (PHCollectionList *)transientCollectionListWithCollections:(NSArray<PHCollection *> *)collections
                                                       title:(NSString *)title;

/// Retrieves collections from the specified collection list.
///
/// @see [PHCollectionList fetchCollectionsInCollectionList:options:].
- (PTNCollectionsFetchResult *)fetchCollectionsInCollectionList:(PHCollectionList *)collectionList
                                                        options:(nullable PHFetchOptions *)options;

/// Retrieves asset collections with the specified local identifiers.
///
/// @see [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:options:].
- (PHFetchResult<PHCollection *> *)fetchAssetCollectionsWithLocalIdentifiers:
    (NSArray<NSString *> *)identifiers options:(nullable PHFetchOptions *)options;

/// Retrieves assets from the specified asset collection.
///
/// @see [PHAsset fetchAssetsInAssetCollection:options:].
- (PTNAssetsFetchResult *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                        options:(nullable PHFetchOptions *)options;

/// Retrieves assets with the specified local identifiers.
///
/// @see [PHAsset fetchAssetsWithLocalIdentifiers:options:].
- (PTNAssetsFetchResult *)fetchAssetsWithLocalIdentifiers:(NSArray<NSString *> *)identifiers
                                           options:(nullable PHFetchOptions *)options;

/// Retrieves assets that match the specified media type and options.
///
/// @see [PHAsset fetchAssetsWithMediaType:options:].
- (PTNAssetsFetchResult *)fetchAssetsWithMediaType:(PHAssetMediaType)mediaType
                                           options:(nullable PHFetchOptions *)options;

/// Retrieves assets marked as key assets in the specified asset collection, or \c nil if no objects
/// match the request.
///
/// @see [PHAsset fetchKeyAssetsInAssetCollection:options:].
- (nullable PTNAssetsFetchResult *)fetchKeyAssetsInAssetCollection:
    (PHAssetCollection *)assetCollection options:(nullable PHFetchOptions *)options;

/// Creates a change details object that summarizes the differences between two fetch results.
/// \c changedObject is a collection of objects to manually note as changed between the two fetch
/// results, or \c nil to compare the fetch results entirely.
///
/// @see [PHFetchResultChangeDetails changeDetailsFromFetchResult:toFetchResult:changedObjects:].
- (PHFetchResultChangeDetails *)changeDetailsFromFetchResult:(PHFetchResult *)fromResult
    toFetchResult:(PHFetchResult *)toResult
    changedObjects:(nullable NSArray<PHObject *> *)changedObjects;

/// Creates a temporary asset collection containing the assets from the specified fetch result, and
/// named with the specified title.
///
/// @see [PHAssetCollection transientAssetCollectionWithAssetFetchResult:title:]
- (PHAssetCollection *)
    transientAssetCollectionWithAssetFetchResult:(PHFetchResult<PHAsset *> *)fetchResult
                                           title:(nullable NSString *)title;

/// Returns the list of data resources associated with \c asset.
///
/// @see [PHAssetResource assetResourcesForAsset:]
- (NSArray<PHAssetResource *> *)assetResourcesForAsset:(PHAsset *)asset;

@end

/// Implementation of \c PTNPhotoKitFetcher by passing through the messages to the appropriate class
/// method in PhotoKit.
@interface PTNPhotoKitFetcher : NSObject <PTNPhotoKitFetcher>
@end

NS_ASSUME_NONNULL_END
