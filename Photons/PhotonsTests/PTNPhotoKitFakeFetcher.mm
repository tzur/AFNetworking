// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitFakeFetcher.h"

#import <Photos/Photos.h>

#import "PTNPhotoKitFakeFetchResultChangeDetails.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitFakeFetcher ()

/// Maps between local identifier to its matching asset.
@property (strong, nonatomic) NSMutableDictionary<NSString *, PHAsset *> *localIdentifierToAsset;

/// Maps between local identifier to its matching asset collection.
@property (strong, nonatomic)
    NSMutableDictionary<NSString *, PHAssetCollection *> *localIdentifierToAssetCollection;

/// Masp between asset collection's local identifier to its key asset.
@property (strong, nonatomic)
    NSMutableDictionary<NSString *, PHAsset *> *assetCollectionLocalIdentifierToKeyAsset;

/// Maps between collection type to an array of asset collection matching the type.
@property (strong, nonatomic)
    NSMutableDictionary<NSArray<NSNumber *> *, id> *typeToAssetCollections;

/// Maps between asset collection's local identifier to its assets array.
@property (strong, nonatomic)
    NSMutableDictionary<NSString *, id> *assetCollectionLocalIdentifierToAssets;

/// Maps between collection list to asset collections.
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *collectionListToAssetCollections;

/// Maps between asset collections to collection list.
@property (strong, nonatomic)
    NSMutableDictionary<NSArray<PHCollection *> *,
                        PHCollectionList *> *assetCollectionsToCollectionList;

/// All threads from which calls to the receiver were made.
@property (strong, atomic) NSSet<NSThread *> *operatingThreads;

/// Mock used to register change details between fetch results.
@property (readonly, nonatomic) PTNPhotoKitFetcher *changeDetailsMock;

/// Maps between media type to its matching assets.
@property (strong, nonatomic) NSMutableDictionary *mediaTypeToAssets;

/// Maps between fetch result to its matching asset collection.
@property (strong, nonatomic)
    NSMutableDictionary<PHFetchResult *, PHAssetCollection *> *fetchResultToAssetCollection;

/// Maps between asset and its associated asset resources.
@property (strong, nonatomic)
    NSMutableDictionary<NSString *, NSArray<PHAssetResource *> *> *assetLocalIdentifierToResources;

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
    self.operatingThreads = [NSSet set];
    _changeDetailsMock = OCMClassMock(PTNPhotoKitFetcher.class);
    self.mediaTypeToAssets = [NSMutableDictionary dictionary];
    self.fetchResultToAssetCollection = [NSMutableDictionary dictionary];
    self.assetLocalIdentifierToResources = [NSMutableDictionary dictionary];
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

- (void)registerChangeDetails:(PHFetchResultChangeDetails *)changeDetails
           forFromFetchResult:(PHFetchResult *)fromResult
                toFetchResult:(PHFetchResult *)toResult
               changedObjects:(nullable NSArray<PHObject *> *)changedObjects {
  OCMStub([self.changeDetailsMock changeDetailsFromFetchResult:fromResult toFetchResult:toResult
      changedObjects:changedObjects]).andReturn(changeDetails);
}

- (void)registerAssets:(NSArray<PHAsset *> *)assets withMediaType:(PHAssetMediaType)mediaType {
  @synchronized (self.mediaTypeToAssets) {
    self.mediaTypeToAssets[@(mediaType)] = assets;
  }
}

- (void)registerAssetCollection:(PHAssetCollection *)assetCollection
                withFetchResult:(PHFetchResult *)fetchResult {
  @synchronized (self.mediaTypeToAssets) {
    self.mediaTypeToAssets[fetchResult] = assetCollection;
  }
}

- (void)registerAssetResources:(NSArray<PHAssetResource *> *)assetResources
                     withAsset:(PHAsset *)asset {
  @synchronized (self.assetLocalIdentifierToResources) {
    self.assetLocalIdentifierToResources[asset.localIdentifier] = assetResources;
  }
}

#pragma mark -
#pragma mark PTNPhotoKitFetcher
#pragma mark -

- (PTNAssetCollectionsFetchResult *)fetchAssetCollectionsWithLocalIdentifiers:
    (NSArray<NSString *> *)identifiers options:(nullable PHFetchOptions __unused *)options {
  self.operatingThreads = [self.operatingThreads setByAddingObject:[NSThread currentThread]];
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
  self.operatingThreads = [self.operatingThreads setByAddingObject:[NSThread currentThread]];
  PHCollectionList *result;
  @synchronized (self.assetCollectionsToCollectionList) {
    result = self.assetCollectionsToCollectionList[collections];
  }
  return result;
}

- (PTNCollectionsFetchResult *)fetchCollectionsInCollectionList:(PHCollectionList *)collectionList
    options:(nullable PHFetchOptions __unused *)options {
  self.operatingThreads = [self.operatingThreads setByAddingObject:[NSThread currentThread]];
  PTNCollectionsFetchResult *result;
  @synchronized (self.collectionListToAssetCollections) {
    result = self.collectionListToAssetCollections[collectionList.localIdentifier];
  }
  return result;
}

- (PTNAssetCollectionsFetchResult *)fetchAssetCollectionsWithType:(PHAssetCollectionType)type
    subtype:(PHAssetCollectionSubtype)subtype options:(nullable PHFetchOptions __unused *)options {
  self.operatingThreads = [self.operatingThreads setByAddingObject:[NSThread currentThread]];
  NSArray *albumType = @[@(type), @(subtype)];
  PTNAssetCollectionsFetchResult *result;
  @synchronized (self.typeToAssetCollections) {
    result = self.typeToAssetCollections[albumType];
  }
  return result;
}

- (PTNAssetsFetchResult *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                               options:(nullable PHFetchOptions __unused *)options {
  self.operatingThreads = [self.operatingThreads setByAddingObject:[NSThread currentThread]];
  return self.assetCollectionLocalIdentifierToAssets[assetCollection.localIdentifier];
}

- (PTNAssetsFetchResult *)fetchAssetsWithLocalIdentifiers:(NSArray<NSString *> *)identifiers
    options:(nullable PHFetchOptions __unused *)options {
  self.operatingThreads = [self.operatingThreads setByAddingObject:[NSThread currentThread]];
  id fetchResult;
  @synchronized (self.localIdentifierToAsset) {
    fetchResult = [identifiers.rac_sequence map:^(NSString *identifier) {
      return self.localIdentifierToAsset[identifier];
    }].array;
  }

  return fetchResult;
}

- (PTNAssetsFetchResult *)fetchAssetsWithMediaType:(PHAssetMediaType)mediaType
                                           options:(nullable PHFetchOptions __unused *)options {
  self.operatingThreads = [self.operatingThreads setByAddingObject:[NSThread currentThread]];
  id fetchResult;
  @synchronized (self.mediaTypeToAssets) {
    fetchResult = self.mediaTypeToAssets[@(mediaType)];
  }

  return fetchResult;
}

- (nullable PTNAssetsFetchResult *)fetchKeyAssetsInAssetCollection:
    (PHAssetCollection *)assetCollection options:(nullable PHFetchOptions __unused *)options {
  self.operatingThreads = [self.operatingThreads setByAddingObject:[NSThread currentThread]];
  PHAsset *keyAsset;

  @synchronized (self.assetCollectionLocalIdentifierToKeyAsset) {
    keyAsset = self.assetCollectionLocalIdentifierToKeyAsset[assetCollection.localIdentifier];
  }

  return (id)(keyAsset ? @[keyAsset] : @[]);
}

- (PHFetchResultChangeDetails *)changeDetailsFromFetchResult:(PHFetchResult *)fromResult
   toFetchResult:(PHFetchResult *)toResult
   changedObjects:(nullable NSArray<PHObject *> *)changedObjects {
  self.operatingThreads = [self.operatingThreads setByAddingObject:[NSThread currentThread]];
  return [self.changeDetailsMock changeDetailsFromFetchResult:fromResult toFetchResult:toResult
                                               changedObjects:changedObjects];
}

- (PHAssetCollection *)
    transientAssetCollectionWithAssetFetchResult:(PHFetchResult<PHAsset *> *)fetchResult
                                           title:(nullable NSString __unused *)title {
  self.operatingThreads = [self.operatingThreads setByAddingObject:[NSThread currentThread]];
  id assetCollection;
  @synchronized (self.mediaTypeToAssets) {
    assetCollection = self.mediaTypeToAssets[fetchResult];
  }

  return assetCollection;
}

- (NSArray<PHAssetResource *> *)assetResourcesForAsset:(PHAsset *)asset {
  self.operatingThreads = [self.operatingThreads setByAddingObject:[NSThread currentThread]];

  NSArray<PHAssetResource *> *resources;
  @synchronized (self.assetLocalIdentifierToResources) {
    resources = self.assetLocalIdentifierToResources[asset.localIdentifier];
  }
  return resources;
}

@end

NS_ASSUME_NONNULL_END
