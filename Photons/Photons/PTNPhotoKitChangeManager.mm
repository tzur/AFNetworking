// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitChangeManager.h"

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@implementation PTNPhotoKitChangeManager

- (nullable PHAssetChangeRequest *)createAssetFromImageAtFileURL:(NSURL *)fileURL {
  return [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
}

- (nullable PHAssetChangeRequest *)createAssetFromVideoAtFileURL:(NSURL *)fileURL {
  return [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
}

- (nullable PHAssetChangeRequest *)createAssetFromVideoAtFileURL:(NSURL *)fileURL
      withOptions:(PHAssetResourceCreationOptions *)options {
  PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
  [request addResourceWithType:PHAssetResourceTypeVideo fileURL:fileURL options:options];
  return request;
}

- (void)deleteAssets:(id<NSFastEnumeration>)assets {
  [PHAssetChangeRequest deleteAssets:assets];
}

- (void)deleteCollectionLists:(id<NSFastEnumeration>)collectionsLists {
  [PHCollectionListChangeRequest deleteCollectionLists:collectionsLists];
}

- (void)deleteAssetCollections:(id<NSFastEnumeration>)assetCollections {
  [PHAssetCollectionChangeRequest deleteAssetCollections:assetCollections];
}

- (void)removeAssets:(id<NSFastEnumeration>)assets
 fromAssetCollection:(PHAssetCollection *)assetCollection {
  PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest
                                             changeRequestForAssetCollection:assetCollection];
  [request removeAssets:assets];
}

- (void)removeCollections:(id<NSFastEnumeration>)collections
       fromCollectionList:(PHCollectionList *)collectionList {
  PHCollectionListChangeRequest *request = [PHCollectionListChangeRequest
                                             changeRequestForCollectionList:collectionList];
  [request removeChildCollections:collections];
}

- (void)addAssets:(id<NSFastEnumeration>)assets
    toAssetCollection:(PHAssetCollection *)assetCollection {
  PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest
                                             changeRequestForAssetCollection:assetCollection];
  [request addAssets:assets];
}

- (void)favoriteAsset:(PHAsset *)asset favorite:(BOOL)favorite {
  PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:asset];
  request.favorite = favorite;
}

- (void)creationRequestForAssetCollectionWithTitle:(NSString *)title {
  [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
}

- (void)performChanges:(dispatch_block_t)changeBlock
     completionHandler:(nullable PTNChangeRequestCompletionBlock)completionHandler {
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:changeBlock
                                    completionHandler:completionHandler];
}

@end

NS_ASSUME_NONNULL_END
