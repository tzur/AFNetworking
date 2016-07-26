// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@class PHAsset, PHAssetCollection, PHCollectionList, PHFetchResult;

/// Protocol for changing PhotoKit entities in the shared \c PHPhotoLibrary.
@protocol PTNPhotoKitChangeManager <NSObject>

/// Type of block called by the \c -performChanges:completionHandler: when a request has finished.
typedef void (^PTNChangeRequestCompletionBlock)(BOOL success, NSError * _Nullable error);

/// Requests that the image at the specified \c fileURL will be created. Call this method within a
/// photo library change block to create image asset. For details on change blocks, see the
/// \c PTNPhotoKitChangeManager protocol.
- (void)createAssetFromImageAtFileURL:(NSURL *)fileURL;

/// Requests that the specified \c assets be deleted. Call this method within a photo library change
/// block to delete assets. For details on change blocks, see the \c PTNPhotoKitChangeManager
/// protocol.
- (void)deleteAssets:(id<NSFastEnumeration>)assets;

/// Requests that the specified \c assetCollections be deleted. Call this method within a photo
/// library change block to delete assets. For details on change blocks, see the
/// \c PTNPhotoKitChangeManager protocol.
- (void)deleteAssetCollections:(id<NSFastEnumeration>)assetCollections;

/// Requests that the specified \c collectionsLists be deleted. Call this method within a photo
/// library change block to delete assets. For details on change blocks, see the
/// \c PTNPhotoKitChangeManager protocol.
- (void)deleteCollectionLists:(id<NSFastEnumeration>)collectionsLists;

/// Requests that the specified \c assets be removed from \c assetCollection. Call this method
/// within a photo library change block to delete assets. For details on change blocks, see the
/// \c PTNPhotoKitChangeManager protocol.
- (void)removeAssets:(id<NSFastEnumeration>)assets
 fromAssetCollection:(PHAssetCollection *)assetCollection;

/// Requests that the specified \c collections be removed from \c collectionList. Call this method
/// within a photo library change block to delete assets. For details on change blocks, see the
/// \c PTNPhotoKitChangeManager protocol.
- (void)removeCollections:(id<NSFastEnumeration>)collections
       fromCollectionList:(PHCollectionList *)collectionList;

/// Requests that the favorite value of \c asset will be set to \c favorite. Call this method within
/// a photo library change block. For details on change blocks, see the \c PTNPhotoKitChangeManager
/// protocol.
- (void)favoriteAsset:(PHAsset *)asset favorite:(BOOL)favorite;

/// Asynchronously runs a block that requests changes to be performed in the Photos library. Photos
/// executes both the change block and the completion handler block on an arbitrary serial queue. To
/// update your app’s UI as a result of a change, dispatch that work to the main queue.
///
/// @note For each call to this method, iOS shows an alert asking the user for permission to edit
/// the contents of the photo library. If your app needs to submit several changes at once, combine
/// them into a single change block. For example, to edit the content of multiple existing photos,
/// create multiple \c PHAssetChangeRequest objects and set the \c contentEditingOutput property on
/// each to an independent \c PHContentEditingOutput object.
- (void)performChanges:(dispatch_block_t)changeBlock
     completionHandler:(nullable PTNChangeRequestCompletionBlock)completionHandler;

@end

/// Implementation of \c PTNPhotoKitChangeManager using the shared PHPhotoLibrary and the static
/// methods of \c PHAssetChangeRequest, \c PHAssetCollectionChangeRequest and
/// \c PHCollectionListChangeRequest.
@interface PTNPhotoKitChangeManager : NSObject <PTNPhotoKitChangeManager>
@end

NS_ASSUME_NONNULL_END
