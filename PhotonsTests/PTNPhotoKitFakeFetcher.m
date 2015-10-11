// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitFakeFetcher.h"

#import "PTNPhotoKitAlbumType.h"

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

@end

@implementation PTNPhotoKitFakeFetcher

- (instancetype)init {
  if (self = [super init]) {
    self.localIdentifierToAsset = [NSMutableDictionary dictionary];
    self.localIdentifierToAssetCollection = [NSMutableDictionary dictionary];
    self.assetCollectionLocalIdentifierToKeyAsset = [NSMutableDictionary dictionary];
    self.typeToAssetCollections = [NSMutableDictionary dictionary];
    self.assetCollectionLocalIdentifierToAssets = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark -
#pragma mark Registration
#pragma mark -

- (void)registerAssets:(NSArray<PHAsset *> *)assets
   withAssetCollection:(PHAssetCollection *)assetCollection {
  self.assetCollectionLocalIdentifierToAssets[assetCollection.localIdentifier] = assets;
}

- (void)registerAssetCollections:(NSArray<PHAssetCollection *> *)assetCollections
                        withType:(PHAssetCollectionType)type
                      andSubtype:(PHAssetCollectionSubtype)subtype {
  PTNPhotoKitAlbumType *albumType = [PTNPhotoKitAlbumType albumTypeWithType:type subtype:subtype];
  self.typeToAssetCollections[albumType] = assetCollections;
}

- (void)registerAssetCollection:(PHAssetCollection *)assetCollection {
  self.localIdentifierToAssetCollection[assetCollection.localIdentifier] = assetCollection;
}

- (void)registerAsset:(PHAsset *)asset {
  self.localIdentifierToAsset[asset.localIdentifier] = asset;
}

- (void)registerAsset:(PHAsset *)asset
    asKeyAssetOfAssetCollection:(PHAssetCollection *)assetCollection {
  self.assetCollectionLocalIdentifierToKeyAsset[assetCollection.localIdentifier] = asset;
}

#pragma mark -
#pragma mark PTNPhotoKitFetcher
#pragma mark -

- (PTNAssetCollectionsFetchResult *)fetchAssetCollectionsWithLocalIdentifiers:
    (NSArray<NSString *> *)identifiers options:(nullable PHFetchOptions __unused *)options {
  id fetchResult = [identifiers.rac_sequence map:^(NSString *identifier) {
    return self.localIdentifierToAssetCollection[identifier];
  }].array;

  return fetchResult;
}

- (PTNAssetCollectionsFetchResult *)fetchAssetCollectionsWithType:(PHAssetCollectionType)type
    subtype:(PHAssetCollectionSubtype)subtype options:(nullable PHFetchOptions __unused *)options {
  PTNPhotoKitAlbumType *albumType = [PTNPhotoKitAlbumType albumTypeWithType:type subtype:subtype];
  return self.typeToAssetCollections[albumType];
}

- (PTNAssetsFetchResult *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                               options:(nullable PHFetchOptions __unused *)options {
  return self.assetCollectionLocalIdentifierToAssets[assetCollection.localIdentifier];
}

- (PTNAssetsFetchResult *)fetchAssetsWithLocalIdentifiers:(NSArray<NSString *> *)identifiers
    options:(nullable PHFetchOptions __unused *)options {
  id fetchResult = [identifiers.rac_sequence map:^(NSString *identifier) {
    return self.localIdentifierToAsset[identifier];
  }].array;

  return fetchResult;
}

- (nullable PTNAssetsFetchResult *)fetchKeyAssetsInAssetCollection:
    (PHAssetCollection *)assetCollection options:(nullable PHFetchOptions __unused *)options {
  PHAsset *keyAsset =
      self.assetCollectionLocalIdentifierToKeyAsset[assetCollection.localIdentifier];
  id fetchResult = keyAsset ? @[keyAsset] : @[];

  return fetchResult;
}

- (PHFetchResultChangeDetails *)changeDetailsFromFetchResult:(PHFetchResult *)fromResult
                                               toFetchResult:(PHFetchResult *)toResult
                                              changedObjects:(NSArray<PHObject *> *)changedObjects {
  id changeDetails = OCMClassMock([PHFetchResultChangeDetails class]);

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

  // This implementation is only partial and handles only in-place changed objects.
  OCMStub([changeDetails fetchResultBeforeChanges]).andReturn(fromResult);
  OCMStub([changeDetails fetchResultAfterChanges]).andReturn(toResult);
  OCMStub([changeDetails hasIncrementalChanges]).andReturn(YES);

  OCMStub([changeDetails changedObjects]).andReturn(changedObjects);
  OCMStub([changeDetails changedIndexes]).andReturn(indexSet);

  OCMStub([changeDetails removedObjects]).andReturn(@[]);
  OCMStub([changeDetails removedIndexes]).andReturn([NSIndexSet indexSet]);
  OCMStub([changeDetails insertedObjects]).andReturn(@[]);
  OCMStub([changeDetails insertedIndexes]).andReturn([NSIndexSet indexSet]);
  OCMStub([changeDetails hasMoves]).andReturn(NO);

  return changeDetails;
}

@end

NS_ASSUME_NONNULL_END
