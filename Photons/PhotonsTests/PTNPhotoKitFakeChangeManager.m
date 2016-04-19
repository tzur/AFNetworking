// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitFakeChangeManager.h"

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitFakeChangeManager ()

/// Lock used to enforce registering of requests only within a change block.
@property (nonatomic) BOOL inChangeBlock;

/// Asset requested to be deleted by the manager.
@property (readonly, nonatomic) NSMutableArray *assetsDeleted;

/// Asset collections requested to be deleted by the manager.
@property (readonly, nonatomic) NSMutableArray *assetCollectionsDeleted;

/// Collection lists requested to be deleted by the manager.
@property (readonly, nonatomic) NSMutableArray *collectionListsDeleted;

/// Assets removed from an album.
@property (readonly, nonatomic) NSMutableDictionary *assetsRemovedFromAlbum;

/// Assets collections removed from an album.
@property (readonly, nonatomic) NSMutableDictionary *assetCollectionsRemovedFromAlbum;

@end

@implementation PTNPhotoKitFakeChangeManager

- (instancetype)init {
  if (self = [super init]) {
    _assetsDeleted = [NSMutableArray array];
    _assetCollectionsDeleted = [NSMutableArray array];
    _collectionListsDeleted = [NSMutableArray array];
    _assetsRemovedFromAlbum = [NSMutableDictionary dictionary];
    _assetCollectionsRemovedFromAlbum = [NSMutableDictionary dictionary];
    self.inChangeBlock = YES;
    self.success = YES;
  }
  return self;
}

- (NSArray *)assetDeleteRequests {
  return [self.assetsDeleted copy];
}

- (NSArray *)assetCollectionDeleteRequests {
  return [self.assetCollectionsDeleted copy];
}

- (NSArray *)collectionListDeleteRequests {
  return [self.collectionListsDeleted copy];
}

- (NSDictionary *)assetsRemovedFromAlbumRequests {
  return [self.assetsRemovedFromAlbum copy];
}

- (NSDictionary *)assetCollectionsRemovedFromAlbumRequests {
  return [self.assetCollectionsRemovedFromAlbum copy];
}

#pragma mark -
#pragma mark PTNPhotoKitChangeManager
#pragma mark -

#pragma mark -
#pragma mark Deletion
#pragma mark -

- (void)deleteAssets:(id<NSFastEnumeration>)assets {
  LTAssert(!self.inChangeBlock, @"Attempting to delete assetsDeleted not within a change block: %@",
           assets);
  for (id asset in assets) {
    [self.assetsDeleted addObject:asset];
  }
}

- (void)deleteAssetCollections:(id<NSFastEnumeration>)assetCollections {
  LTAssert(!self.inChangeBlock, @"Attempting to delete asset collections not within a change "
           "block:  %@", assetCollections);
  for (id collection in assetCollections) {
    [self.assetCollectionsDeleted addObject:collection];
  }
}

- (void)deleteCollectionLists:(id<NSFastEnumeration>)collectionsLists {
  LTAssert(!self.inChangeBlock, @"Attempting to delete collection lists not within a change block: "
           "%@", collectionsLists);
  for (id list in collectionsLists) {
    [self.collectionListsDeleted addObject:list];
  }
}

#pragma mark -
#pragma mark Removal
#pragma mark -

- (void)removeAssets:(id<NSFastEnumeration>)assets
 fromAssetCollection:(PHAssetCollection *)assetCollection {
  LTAssert(!self.inChangeBlock, @"Attempting to remove assetsDeleted: %@ from collection: %@ "
           "not within a change block", assets, assetCollection);
  self.assetsRemovedFromAlbum[assetCollection.localIdentifier] = assets;
}

- (void)removeCollections:(id<NSFastEnumeration>)collections
       fromCollectionList:(PHCollectionList *)collectionList {
  LTAssert(!self.inChangeBlock, @"Attempting to remove collections: %@ from collection list: %@ "
           "not within a change block", collections, collectionList);
  self.assetCollectionsRemovedFromAlbum[collectionList.localIdentifier] = collections;
}

#pragma mark -
#pragma mark Changes
#pragma mark -

- (void)performChanges:(dispatch_block_t)changeBlock
     completionHandler:(nullable PTNChangeRequestCompletionBlock)completionHandler {
  LTParameterAssert(changeBlock, @"Given a nil change block");
  self.inChangeBlock = NO;
  changeBlock();
  self.inChangeBlock = YES;
  completionHandler(self.success, self.error);
}

@end

NS_ASSUME_NONNULL_END
