// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitFakeFetcher.h"

#import <Photos/Photos.h>

#import "PTNPhotoKitFakeFetchResultChangeDetails.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitFakeFetcher ()

/// Maps between local identifier to its matching asset.
@property (strong, nonatomic) NSMutableDictionary *localIdentifierToAsset;

/// Maps between local identifier to its matching asset collection.
@property (strong, nonatomic) NSMutableDictionary *localIdentifierToAssetCollection;

/// Masp between asset collection's local identifier to its key asset.
@property (strong, nonatomic) NSMutableDictionary *assetCollectionLocalIdentifierToKeyAsset;

/// Maps between collection type to an array of asset collection matching the type.
@property (strong, nonatomic) NSMutableDictionary *typeToAssetCollections;

/// Maps between asset collection's local identifier to its assets array.
@property (strong, nonatomic) NSMutableDictionary *assetCollectionLocalIdentifierToAssets;

/// Maps between collection list to asset collections.
@property (strong, nonatomic) NSMutableDictionary *collectionListToAssetCollections;

/// Maps between asset collections to collection list.
@property (strong, nonatomic) NSMutableDictionary *assetCollectionsToCollectionList;

@end

@implementation PTNPhotoKitFakeFetcher

- (instancetype)init {
  if (self = [super init]) {
    self.localIdentifierToAsset = [NSMutableDictionary dictionary];
    self.localIdentifierToAssetCollection = [NSMutableDictionary dictionary];
    self.assetCollectionLocalIdentifierToKeyAsset = [NSMutableDictionary dictionary];
    self.typeToAssetCollections = [NSMutableDictionary dictionary];
    self.assetCollectionLocalIdentifierToAssets = [NSMutableDictionary dictionary];
    self.collectionListToAssetCollections = [NSMutableDictionary dictionary];
    self.assetCollectionsToCollectionList = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark -
#pragma mark Registration
#pragma mark -

- (void)registerAssets:(NSArray<PHAsset *> *)assets
   withAssetCollection:(PHAssetCollection *)assetCollection {
  @synchronized (self.assetCollectionLocalIdentifierToAssets) {
    self.assetCollectionLocalIdentifierToAssets[assetCollection.localIdentifier] = assets;
  }
}

- (void)registerAssetCollections:(NSArray<PHAssetCollection *> *)assetCollections
                        withType:(PHAssetCollectionType)type
                      andSubtype:(PHAssetCollectionSubtype)subtype {
  NSArray *albumType = @[@(type), @(subtype)];
  @synchronized (self.typeToAssetCollections) {
    self.typeToAssetCollections[albumType] = assetCollections;
  }
}

- (void)registerAssetCollection:(PHAssetCollection *)assetCollection {
  self.localIdentifierToAssetCollection[assetCollection.localIdentifier] = assetCollection;
}

- (void)registerCollectionList:(PHCollectionList *)collectionList
          withAssetCollections:(NSArray<PHCollection *> *)assetCollections {
  self.assetCollectionsToCollectionList[assetCollections] = collectionList;
}

- (void)registerAssetCollections:(NSArray<PHAssetCollection *> *)assetCollections
              withCollectionList:(PHCollectionList *)collectionList {
  self.collectionListToAssetCollections[collectionList.localIdentifier] = assetCollections;
}

- (void)registerAsset:(PHAsset *)asset {
  @synchronized (self.localIdentifierToAsset) {
    self.localIdentifierToAsset[asset.localIdentifier] = asset;
  }
}

- (void)registerAsset:(PHAsset *)asset
    asKeyAssetOfAssetCollection:(PHAssetCollection *)assetCollection {
  @synchronized (self.assetCollectionLocalIdentifierToKeyAsset) {
    self.assetCollectionLocalIdentifierToKeyAsset[assetCollection.localIdentifier] = asset;
  }
}

#pragma mark -
#pragma mark PTNPhotoKitFetcher
#pragma mark -

- (PTNAssetCollectionsFetchResult *)fetchAssetCollectionsWithLocalIdentifiers:
    (NSArray<NSString *> *)identifiers options:(nullable PHFetchOptions __unused *)options {
  id fetchResult;
  @synchronized (self.localIdentifierToAssetCollection) {
    fetchResult = [identifiers.rac_sequence map:^(NSString *identifier) {
      return self.localIdentifierToAssetCollection[identifier];
    }].array;
  }

  return fetchResult;
}

- (PHCollectionList *)transientCollectionListWithCollections:(NSArray<PHCollection *> *)collections
                                                       title:(NSString __unused *)title {
  PHCollectionList *result;
  @synchronized (self.typeToAssetCollections) {
    result = self.assetCollectionsToCollectionList[collections];
  }
  return result;
}

- (PTNCollectionsFetchResult *)fetchCollectionsInCollectionList:(PHCollectionList *)collectionList
    options:(nullable PHFetchOptions __unused *)options {
  PTNCollectionsFetchResult *result;
  @synchronized (self.typeToAssetCollections) {
    result = self.collectionListToAssetCollections[collectionList.localIdentifier];
  }
  return result;
}

- (PTNAssetCollectionsFetchResult *)fetchAssetCollectionsWithType:(PHAssetCollectionType)type
    subtype:(PHAssetCollectionSubtype)subtype options:(nullable PHFetchOptions __unused *)options {
  NSArray *albumType = @[@(type), @(subtype)];
  PTNAssetCollectionsFetchResult *result;
  @synchronized (self.typeToAssetCollections) {
    result = self.typeToAssetCollections[albumType];
  }
  return result;
}

- (PTNAssetsFetchResult *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                               options:(nullable PHFetchOptions __unused *)options {
  return self.assetCollectionLocalIdentifierToAssets[assetCollection.localIdentifier];
}

- (PTNAssetsFetchResult *)fetchAssetsWithLocalIdentifiers:(NSArray<NSString *> *)identifiers
    options:(nullable PHFetchOptions __unused *)options {
  id fetchResult;
  @synchronized (self.localIdentifierToAsset) {
    fetchResult = [identifiers.rac_sequence map:^(NSString *identifier) {
      return self.localIdentifierToAsset[identifier];
    }].array;
  }

  return fetchResult;
}

- (nullable PTNAssetsFetchResult *)fetchKeyAssetsInAssetCollection:
    (PHAssetCollection *)assetCollection options:(nullable PHFetchOptions __unused *)options {
  PHAsset *keyAsset;
  
  @synchronized (self.assetCollectionLocalIdentifierToKeyAsset) {
    keyAsset = self.assetCollectionLocalIdentifierToKeyAsset[assetCollection.localIdentifier];
  }

  return (id)(keyAsset ? @[keyAsset] : @[]);
}

- (PHFetchResultChangeDetails *)changeDetailsFromFetchResult:(PHFetchResult *)fromResult
                                               toFetchResult:(PHFetchResult *)toResult
                                              changedObjects:(NSArray<PHObject *> *)changedObjects {
  NSArray<NSNumber *> *indexes = [[changedObjects.rac_sequence
      filter:^BOOL(PHObject *object) {
        return [toResult containsObject:object];
      }] map:^(PHObject *object) {
        return @([toResult indexOfObject:object]);
      }].array;

  NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
  for (NSNumber *index in indexes) {
    [indexSet addIndex:index.unsignedIntegerValue];
  }
  
  PTNPhotoKitFakeFetchResultChangeDetails *changeDetails =
      [[PTNPhotoKitFakeFetchResultChangeDetails alloc] initWithBeforeChanges:fromResult
                                                                afterChanges:toResult
                                                       hasIncrementalChanges:YES
                                                              removedIndexes:[NSIndexSet indexSet]
                                                              removedObjects:@[]
                                                             insertedIndexes:[NSIndexSet indexSet]
                                                             insertedObjects:@[]
                                                              changedIndexes:indexSet
                                                              changedObjects:changedObjects
                                                                    hasMoves:NO];

  return changeDetails;
}

@end

NS_ASSUME_NONNULL_END
