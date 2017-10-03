// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitFakeChangeManager.h"

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitFakeChangeManager ()

/// Lock used to enforce registering of requests only within a change block.
@property (nonatomic) BOOL inChangeBlock;

/// Asset requested to be created by the manager.
@property (readonly, nonatomic) NSMutableArray *assetsCreated;

/// Asset requested to be created with options by the manager.
@property (readonly, nonatomic) NSMutableArray *assetsWithOptionsCreated;

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

/// Assets added to an album.
@property (readonly, nonatomic) NSMutableDictionary *assetsAddedToAlbum;

/// Current assets favorited by the manager.
@property (readonly, nonatomic) NSMutableArray *mutableFavoriteAssets;

/// Titles of asset colllections requested to be created by the manager.
@property (readonly, nonatomic) NSMutableArray *assetsCollectionsCreated;

@end

@implementation PTNPhotoKitFakeChangeManager

- (instancetype)init {
  if (self = [super init]) {
    _assetsCreated = [NSMutableArray array];
    _assetsWithOptionsCreated = [NSMutableArray array];;
    _assetsDeleted = [NSMutableArray array];
    _assetCollectionsDeleted = [NSMutableArray array];
    _collectionListsDeleted = [NSMutableArray array];
    _assetsRemovedFromAlbum = [NSMutableDictionary dictionary];
    _assetCollectionsRemovedFromAlbum = [NSMutableDictionary dictionary];
    _assetsAddedToAlbum = [NSMutableDictionary dictionary];
    _mutableFavoriteAssets = [NSMutableArray array];
    _assetsCollectionsCreated = [NSMutableArray array];
    self.inChangeBlock = YES;
    self.success = YES;
  }
  return self;
}

- (NSArray *)assetCreationRequests {
  return [self.assetsCreated copy];
}

- (NSArray *)assetWithOptionsCreationRequests {
  return [self.assetsWithOptionsCreated copy];
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

- (NSDictionary *)assetsAddedToAlbumRequests {
  return [self.assetsAddedToAlbum copy];
}

- (NSArray *)favoriteAssets {
  return [self.mutableFavoriteAssets copy];
}

- (NSArray *)assetCollectionCreationRequests {
  return [self.assetsCollectionsCreated copy];
}

#pragma mark -
#pragma mark PTNPhotoKitChangeManager
#pragma mark -

#pragma mark -
#pragma mark Creation
#pragma mark -

- (nullable PHAssetChangeRequest *)createAssetFromImageAtFileURL:(NSURL *)fileURL {
  LTAssert(!self.inChangeBlock, @"Attempting to create image at file URL %@ not within a change "
           "block", fileURL);

  [self.assetsCreated addObject:fileURL];
  return self.changeRequest;
}

- (nullable PHAssetChangeRequest *)createAssetFromVideoAtFileURL:(NSURL *)fileURL {
  LTAssert(!self.inChangeBlock, @"Attempting to create video at file URL %@ not within a change "
           "block", fileURL);

  [self.assetsCreated addObject:fileURL];
  return self.changeRequest;
}

- (nullable PHAssetChangeRequest *)createAssetFromVideoAtFileURL:(NSURL *)fileURL
      withOptions:(PHAssetResourceCreationOptions *)options {
  LTAssert(!self.inChangeBlock, @"Attempting to create video at file URL %@ not within a change "
           "block", fileURL);

  [self.assetsWithOptionsCreated addObject:RACTuplePack(fileURL, options)];
  return self.changeRequest;
}

- (void)creationRequestForAssetCollectionWithTitle:(NSString *)title {
  LTAssert(!self.inChangeBlock, @"Attempting to create album with title %@ not within a change "
           "block", title);
  [self.assetsCollectionsCreated addObject:title];
}

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
#pragma mark Favorite
#pragma mark -

- (void)favoriteAsset:(PHAsset *)asset favorite:(BOOL)favorite {
  if (favorite) {
    [self.mutableFavoriteAssets addObject:asset];
  } else {
    [self.mutableFavoriteAssets removeObject:asset];
  }
}

#pragma mark -
#pragma mark Addition
#pragma mark -

- (void)addAssets:(id<NSFastEnumeration>)assets
    toAssetCollection:(PHAssetCollection *)assetCollection {
  LTAssert(!self.inChangeBlock, @"Attempting to add assets: %@ to collection: %@ "
           "not within a change block", assets, assetCollection);
  self.assetsAddedToAlbum[assetCollection.localIdentifier] = assets;
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
