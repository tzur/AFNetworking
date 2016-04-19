// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitChangeManager.h"

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@implementation PTNPhotoKitChangeManager

- (void)deleteAssets:(id<NSFastEnumeration>)assets {
  [PHAssetChangeRequest deleteAssets:assets];
}

- (void)deleteCollectionLists:(id<NSFastEnumeration>)collectionsLists {
  [PHCollectionListChangeRequest deleteCollectionLists:collectionsLists];
}

- (void)deleteAssetCollections:(id<NSFastEnumeration>)assetCollections {
  [PHAssetCollectionChangeRequest deleteAssetCollections:assetCollections];
}

- (void)performChanges:(dispatch_block_t)changeBlock
     completionHandler:(nullable PTNChangeRequestCompletionBlock)completionHandler {
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:changeBlock
                                    completionHandler:completionHandler];
}

@end

NS_ASSUME_NONNULL_END
