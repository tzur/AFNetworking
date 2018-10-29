// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAssetManager.h"

#import <LTKit/LTProgress.h>
#import <LTKit/LTRandomAccessCollection.h>
#import <map>

#import "NSError+Photons.h"
#import "NSURL+PhotoKit.h"
#import "PTNAVAssetFetchOptions+PhotoKit.h"
#import "PTNAlbumChangeset+PhotoKit.h"
#import "PTNAudiovisualAsset.h"
#import "PTNAuthorizationManager.h"
#import "PTNAuthorizationStatus.h"
#import "PTNImageDataAsset.h"
#import "PTNImageFetchOptions+PhotoKit.h"
#import "PTNImageMetadata.h"
#import "PTNImageResizer.h"
#import "PTNPhotoKitAlbum.h"
#import "PTNPhotoKitAssetResourceManager.h"
#import "PTNPhotoKitAuthorizationManager.h"
#import "PTNPhotoKitAuthorizer.h"
#import "PTNPhotoKitChangeManager.h"
#import "PTNPhotoKitDeferringImageManager.h"
#import "PTNPhotoKitFetcher.h"
#import "PTNPhotoKitImageAsset.h"
#import "PTNPhotoKitImageManager.h"
#import "PTNPhotoKitObserver.h"
#import "PTNResizingStrategy.h"
#import "PTNSignalCache.h"
#import "PTNStaticImageAsset.h"
#import "PhotoKit+Photons.h"
#import "RACSignal+Photons.h"
#import "RACStream+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitAssetManager ()

/// Observer for PhotoKit changes.
@property (readonly, nonatomic) id<PTNPhotoKitObserver> observer;

/// Fetcher adapter for PhotoKit.
@property (readonly, nonatomic) id<PTNPhotoKitFetcher> fetcher;

/// Image manager used to request images.
@property (readonly, nonatomic) id<PTNPhotoKitImageManager> imageManager;

/// Asset resource manager used to fetch resources.
@property (readonly, nonatomic) id<PTNPhotoKitAssetResourceManager> assetResourceManager;

/// Change manager used to request changes in the PhotoKit library.
@property (readonly, nonatomic) id<PTNPhotoKitChangeManager> changeManager;

/// Cache from \c NSURL album urls to their \c RACSignal objects.
@property (readonly, nonatomic) PTNSignalCache *albumSignalCache;

/// Manager of authorization status.
@property (readonly, nonatomic) id<PTNAuthorizationManager> authorizationManager;

/// Cold signal containing the latest <tt>_Nullable PHAssetCollection</tt> containing the "My Photo
/// Stream" album. Used to workaround a bug where fetching assets in "My Photo Stream" by identifier
/// doesn't return them.
@property (readonly, nonatomic) RACSignal *myPhotoStreamAlbum;

/// Used in descriptor fetch signals. PhotoKit serializes access to asset/album so we can serialize
/// these requests as well and save some resources by lowering the number of threads used when
/// multiple requests are made simultaneously.
@property (readonly, nonatomic) RACScheduler *fetchScheduler;

/// Used to resize images not resized by PhotoKit.
@property (readonly, nonatomic) PTNImageResizer *imageResizer;

@end

@implementation PTNPhotoKitAssetManager

- (instancetype)initWithFetcher:(id<PTNPhotoKitFetcher>)fetcher
                       observer:(id<PTNPhotoKitObserver>)observer
                   imageManager:(id<PTNPhotoKitImageManager>)imageManager
           assetResourceManager:(id<PTNPhotoKitAssetResourceManager>)assetResourceManager
           authorizationManager:(id<PTNAuthorizationManager>)authorizationManager
                  changeManager:(id<PTNPhotoKitChangeManager>)changeManager
                   imageResizer:(PTNImageResizer *)imageResizer {
  if (self = [super init]) {
    _fetcher = fetcher;
    _observer = observer;
    _imageManager = imageManager;
    _assetResourceManager = assetResourceManager;
    _authorizationManager = authorizationManager;
    _changeManager = changeManager;
    _imageResizer = imageResizer;

    _fetchScheduler = [RACScheduler scheduler];
    _albumSignalCache = [[PTNSignalCache alloc] init];
    _myPhotoStreamAlbum = [self fetchMyPhotoStreamAlbum];
  }
  return self;
}

- (RACSignal *)fetchMyPhotoStreamAlbum {
  id<PTNPhotoKitFetcher> fetcher = self.fetcher;
  return [[[[RACSignal
    defer:^RACSignal *{
      return [RACSignal return:[fetcher
                                fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream
                                options:nil]];
    }]
    takeUntil:self.rac_willDeallocSignal]
    ptn_replayLastLazily]
    map:^PHAssetCollection * _Nullable(PTNAssetCollectionsFetchResult *fetchResult) {
      // My Photo Stream always return one collection.
      if (fetchResult.count > 1) {
        LogWarning(@"Expected my photo stream album to contain only a single collection, but it "
                   "contains %lu collections", (unsigned long)fetchResult.count);
      }
      return fetchResult.firstObject;
    }];
}

- (instancetype)initWithAuthorizationManager:(id<PTNAuthorizationManager>)authorizationManager {
  id<PTNPhotoKitFetcher> fetcher = [[PTNPhotoKitFetcher alloc] init];
  id<PTNPhotoKitObserver> observer =
      [[PTNPhotoKitObserver alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
  id<PTNPhotoKitImageManager> imageManager =
      [[PTNPhotoKitDeferringImageManager alloc] initWithAuthorizationManager:authorizationManager];
  id<PTNPhotoKitAssetResourceManager> assetResourceManager =
      [PHAssetResourceManager defaultManager];
  id<PTNPhotoKitChangeManager> changeManager = [[PTNPhotoKitChangeManager alloc] init];
  PTNImageResizer *imageResizer = [[PTNImageResizer alloc] init];
  return [self initWithFetcher:fetcher observer:observer imageManager:imageManager
          assetResourceManager:assetResourceManager authorizationManager:authorizationManager
                 changeManager:changeManager imageResizer:imageResizer];
}

- (instancetype)init {
  PTNPhotoKitAuthorizer *authorizer = [[PTNPhotoKitAuthorizer alloc] init];
  PTNPhotoKitAuthorizationManager *authorizationManager =
      [[PTNPhotoKitAuthorizationManager alloc] initWithPhotoKitAuthorizer:authorizer];

  return [self initWithAuthorizationManager:authorizationManager];
}

#pragma mark -
#pragma mark Album fetching
#pragma mark -

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  if (![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbum)] &&
      ![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbumType)] &&
      ![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)] &&
      ![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMediaAlbumType)]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  RACSignal *existingSignal = self.albumSignalCache[url];
  if (existingSignal) {
    return [existingSignal scanWithStart:nil
                         reduceWithIndex:^id(id __unused running, PTNAlbumChangeset *next,
                                             NSUInteger index) {
      // Strip previous changes for new subscribers on first value sent.
      if (!index) {
        return [PTNAlbumChangeset changesetWithAfterAlbum:next.afterAlbum];
      } else {
        return next;
      }
    }];
  }

  // Returns an initial (PHFetchResult, PTNAlbumChangeset) tuple from PhotoKit.
  @weakify(self);
  RACSignal *initialChangeset = [[[[self fetchFetchResultWithURL:url]
      tryMap:^id(PHFetchResult *fetchResult, NSError *__autoreleasing *errorPtr) {
        @strongify(self);
        if (!self) {
          return nil;
        }
        // A fetched empty album is an error, unless it's specifically UserAlbums meta album.
        // This is so since a fetch result is all collections that match the fetch request, and so
        // an empty album will be returned as a fetch result with a single album, but when User
        // Albums is requested, if there are no user albums the result will be empty and it won't
        // be an error.
        if (![self isCollectionsFetchResult:fetchResult validForURL:url]) {
          if (errorPtr) {
            *errorPtr = [NSError lt_errorWithCode:PTNErrorCodeAlbumNotFound url:url];
          }
          return nil;
        } else if ([self shouldFlattenAlbum:url]) {
          PHFetchResult *assets = [self.fetcher fetchAssetsInAssetCollection:fetchResult.firstObject
                                                                     options:nil];
          PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithURL:url
                                                         photoKitFetchResult:assets];
          return RACTuplePack(assets, changeset);
        } else if ([url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)]) {
          PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithURL:url
                                                         photoKitFetchResult:fetchResult];
          return RACTuplePack(fetchResult, changeset);
        } else {
          LTAssert(NO, @"Fetched URL of invalid type: %@", url.ptn_photoKitURLType);
        }
      }]
      doError:^(NSError __unused *error) {
        @strongify(self);
        [self.albumSignalCache removeSignalForURL:url];
      }]
      replayLazily];

  // Handle smart album collection differently, since they do not recieve \c PHChange notifications
  // from PhotoKit.
  RACSignal *nextChangeset;
  if ([self shouldObserveChangesRecursively:url]) {
    nextChangeset = [self nextChangesetForSmartAlbumCollectionWithURL:url
                                                  andInitialChangeset:initialChangeset];
  } else {
    nextChangeset = [self nextChangesetForRegularAlbumWithURL:url
                                          andInitialChangeset:initialChangeset];
  }

  // Returns the latest \c PTNAlbumChangeset that is produced from the fetch results.
  RACSignal *changeset = [[[[[RACSignal
      concat:@[initialChangeset, nextChangeset]]
      reduceEach:(id)^(PHFetchResult __unused *fetchResult, PTNAlbumChangeset *changeset) {
        return changeset;
      }]
      distinctUntilChanged]
      subscribeOn:self.fetchScheduler]
      ptn_replayLastLazily];

  self.albumSignalCache[url] = changeset;

  return changeset;
}

- (BOOL)isCollectionsFetchResult:(PHFetchResult *)fetchResult validForURL:(NSURL *)url {
  if (fetchResult.count) {
    return YES;
  }

  // Fetching a fetch result does not err, so in order to validate it we check the number of objects
  // in the result. A fetch result doesn't return actual assets, but rather collections of assets,
  // so even a fetch of an empty album should have one item in the fetch result - an empty
  // collection. The only cases where a fetch result can be empty without indicating some failure is
  // when fetching the user albums when there are none, or fetching smart albums with a subalbum
  // filter, which removes empty subalbums from the fetch.
  return [url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)] &&
      ([url.ptn_photoKitAlbumType isEqual:@(PHAssetCollectionTypeAlbum)] ||
       url.ptn_photoKitAlbumSubalbums);
}

- (RACSignal *)nextChangesetForRegularAlbumWithURL:(NSURL *)url
                               andInitialChangeset:(RACSignal *)initialChangeset {
  // Returns consecutive (PHFetchResult, PTNAlbumChangeset) tuple on each notification.
  @weakify(self);
  return [initialChangeset
      flattenMap:^RACSignal *(RACTuple *tuple) {
        @strongify(self);
        return [[self.observer.photoLibraryChanged
            takeUntil:self.rac_willDeallocSignal]
            scanWithStart:tuple reduce:^RACTuple *(RACTuple *previous, PHChange *change) {
              PHFetchResult *fetchResult = previous.first;
              PTNAlbumChangeset *changeset = previous.second;

              PHFetchResultChangeDetails *details =
                  [change changeDetailsForFetchResult:fetchResult];
              if (details) {
                PTNAlbumChangeset *newChangeset = [PTNAlbumChangeset changesetWithURL:url
                                                                photoKitChangeDetails:details];
                return RACTuplePack(details.fetchResultAfterChanges, newChangeset);
              } else {
                return RACTuplePack(fetchResult, changeset);
              }
            }];
      }];
}

- (RACSignal *)nextChangesetForSmartAlbumCollectionWithURL:(NSURL *)url
                                       andInitialChangeset:(RACSignal *)initialChangeset {
  // Track changes on each subalbum. For each change fetch the smart album collection
  // again, and send proper change details with the changed smart album.
  auto fetcher = self.fetcher;
  @weakify(self);
  return [initialChangeset flattenMap:^RACSignal *(RACTuple *values) {
    @strongify(self);
    if (!self) {
      return nil;
    }
    PHFetchResult *initialFetchResult = values.first;
    return [[[[[self recursiveUpdatesForSmartAlbums]
      flattenMap:^RACSignal *(PHAssetCollection *updatedCollection) {
        @strongify(self);
        if (!self) {
          return nil;
        }
        return [RACSignal combineLatest:@[
          [self fetchFetchResultWithURL:url],
          [RACSignal return:updatedCollection]
        ]];
      }]
      combinePreviousWithStart:RACTuplePack(initialFetchResult, nil)
      reduce:^RACTuple *(RACTuple *previous, RACTuple *current) {
        return RACTuplePack(previous.first, current.first, current.second);
      }]
      filter:^BOOL(RACTuple *values) {
        RACTupleUnpack(PHFetchResult *previousFetch, PHFetchResult *currentFetch,
                       PHAssetCollection *updatedCollection) = values;
        return [previousFetch containsObject:updatedCollection] ||
            [currentFetch containsObject:updatedCollection];
      }]
      reduceEach:(id)^RACTuple *(PHFetchResult *previousFetch, PHFetchResult *currentFetch,
                                 PHAssetCollection *) {
        PHFetchResultChangeDetails *changeDetails =
            [fetcher changeDetailsFromFetchResult:previousFetch toFetchResult:currentFetch
                                   changedObjects:nil];
        PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithURL:url
                                                     photoKitChangeDetails:changeDetails];

        return RACTuplePack(currentFetch, changeset);
      }];
    }];
}

- (RACSignal *)recursiveUpdatesForSmartAlbums {
  return [[self fetchFetchResultWithURL:[NSURL ptn_photoKitSmartAlbums]]
      flattenMap:^(PHFetchResult *fetchResult) {
        NSMutableArray *signals = [NSMutableArray array];

        for (PHAssetCollection *collection in fetchResult) {
          NSURL *subalbumURL = [NSURL ptn_photoKitAlbumURLWithCollection:collection];

          RACSignal *signal = [[[self fetchAlbumWithURL:subalbumURL] skip:1] mapReplace:collection];
          [signals addObject:signal];
        }

        return [RACSignal merge:signals];
    }];
}

- (BOOL)shouldFlattenAlbum:(NSURL *)url {
  return [url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbum)] ||
      [url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbumType)] ||
      [url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMediaAlbumType)];
}

- (BOOL)shouldObserveChangesRecursively:(NSURL *)url {
  return [url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)] &&
      [url.ptn_photoKitAlbumType isEqual:@(PHAssetCollectionTypeSmartAlbum)];
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  if (![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAsset)] &&
      ![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbum)] &&
      ![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbumType)] &&
      ![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMediaAlbumType)]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [RACSignal defer:^{
    RACSignal *initialObject = [[[self fetchFetchResultWithURL:url]
      tryMap:^id(PHFetchResult *fetchResult, NSError *__autoreleasing *errorPtr) {
        if (!fetchResult.count) {
          if (errorPtr) {
            *errorPtr = [NSError lt_errorWithCode:PTNErrorCodeAssetNotFound url:url];
          }
        }
        return fetchResult.firstObject;
      }]
      replayLazily];

    RACSignal *changedObjects = [initialObject
        flattenMap:^RACSignal *(PHObject *object) {
          return [self.observer.photoLibraryChanged scanWithStart:object
              reduce:^PHObject *(PHObject *next, PHChange *change) {
                PHObject * _Nullable after =
                    [change changeDetailsForObject:next].objectAfterChanges;
                return after ?: next;
              }];
        }];

    // The operator ptn_identicallyDistinctUntilChanged is required because PHFetchResult objects
    // are equal if they back the same asset, even if the asset has changed. This makes sure that
    // only new fetch results are provided, but avoid sending the same fetch result over and over
    // again.
    return [[[RACSignal
        concat:@[initialObject, changedObjects]]
        ptn_identicallyDistinctUntilChanged]
        subscribeOn:self.fetchScheduler];
  }];
}

#pragma mark -
#pragma mark Object fetching
#pragma mark -

- (RACSignal *)fetchFetchResultWithURL:(NSURL *)url {
  if (![self urlContainsFetchInfo:url]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    if (![self.authorizationManager.authorizationStatus
          isEqual:$(PTNAuthorizationStatusAuthorized)]) {
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeNotAuthorized url:url]];
    }

    switch (url.ptn_photoKitURLType.value) {
      case PTNPhotoKitURLTypeAsset:
        return [self fetchAssetWithIdentifier:url.ptn_photoKitAssetIdentifier];
      case PTNPhotoKitURLTypeAlbum:
        return [self fetchAlbumWithIdentifier:url.ptn_photoKitAlbumIdentifier];
      case PTNPhotoKitURLTypeAlbumType:
        return [self fetchAlbumWithType:url.ptn_photoKitAlbumType
                                subtype:url.ptn_photoKitAlbumSubtype
                                options:url.ptn_photoKitAlbumFetchOptions];
      case PTNPhotoKitURLTypeMetaAlbumType:
        return [self fetchMetaAlbumWithType:url.ptn_photoKitAlbumType
                                    subtype:url.ptn_photoKitAlbumSubtype
                                  subalbums:url.ptn_photoKitAlbumSubalbums
                                    options:url.ptn_photoKitAlbumFetchOptions];
      case PTNPhotoKitURLTypeMediaAlbumType:
        return [self fetchAlbumWithMediaType:url.ptn_photoKitMediaAlbumMediaType
                                     options:url.ptn_photoKitAlbumFetchOptions];
    }
  }];
}

- (BOOL)urlContainsFetchInfo:(NSURL *)url {
  PTNPhotoKitURLType * _Nullable type = url.ptn_photoKitURLType;
  if (!type) {
    return NO;
  }

  switch (type.value) {
    case PTNPhotoKitURLTypeAsset:
      return url.ptn_photoKitAssetIdentifier != nil;
    case PTNPhotoKitURLTypeAlbum:
      return url.ptn_photoKitAlbumIdentifier != nil;;
    case PTNPhotoKitURLTypeAlbumType:
      return url.ptn_photoKitAlbumType != nil && url.ptn_photoKitAlbumSubtype != nil;
    case PTNPhotoKitURLTypeMetaAlbumType:
      return url.ptn_photoKitAlbumType != nil && url.ptn_photoKitAlbumSubtype != nil;
    case PTNPhotoKitURLTypeMediaAlbumType:
      return url.ptn_photoKitMediaAlbumMediaType != PHAssetMediaTypeUnknown;
  }
}

- (RACSignal *)fetchAssetForDescriptor:(id<PTNDescriptor>)descriptor {
  return [RACSignal defer:^RACSignal *{
    if (![self.authorizationManager.authorizationStatus
          isEqual:$(PTNAuthorizationStatusAuthorized)]) {
      return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeNotAuthorized
                                    associatedDescriptor:descriptor]];
    }

    if ([descriptor isKindOfClass:[PHAsset class]]) {
      return [RACSignal return:descriptor];
    } else if ([descriptor isKindOfClass:[PHAssetCollection class]]) {
      return [[self fetchKeyAssetForAssetCollection:(PHAssetCollection *)descriptor]
          subscribeOn:self.fetchScheduler];
    } else {
      LTAssert(NO, @"Invalid descriptor given: %@", descriptor);
    }
  }];
}

- (RACSignal *)fetchAssetWithIdentifier:(NSString *)identifier {
  PTNAssetsFetchResult *fetchResult =
      [self.fetcher fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];

  if (fetchResult.count) {
    return [RACSignal return:fetchResult];
  }

  // If the asset was not found, we search it directly in the "My Photo Stream" album. This is a
  // workaround to a bug in PhotoKit where fetching assets by local identifiers with
  // \c fetchAssetsWithLocalIdentifiers:options: doesn't return assets in the "My Photo Stream"
  // album.
  //
  // @see rdar://33824204
  return [self.myPhotoStreamAlbum
      map:^PTNAssetsFetchResult *(PHAssetCollection * _Nullable assetCollection) {
        if (!assetCollection) {
          return fetchResult;
        }

        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"localIdentifier == %@",
                                  identifier];
        return [self.fetcher fetchAssetsInAssetCollection:assetCollection options:fetchOptions];
      }];
}

- (RACSignal *)fetchKeyAssetForAssetCollection:(PHAssetCollection *)assetCollection {
  PTNAssetsFetchResult *fetchResult =
      [self.fetcher fetchKeyAssetsInAssetCollection:assetCollection options:nil];
  if (!fetchResult.firstObject) {
    NSURL *url = [NSURL ptn_photoKitAlbumURLWithCollection:assetCollection];
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeKeyAssetsNotFound url:url]];
  } else {
    return [RACSignal return:fetchResult.firstObject];
  }
}

#pragma mark -
#pragma mark Album types
#pragma mark -

- (RACSignal *)fetchAlbumWithType:(NSNumber *)type subtype:(NSNumber *)subtype
                          options:(PHFetchOptions * _Nullable)options {
  return [RACSignal return:[self fetchResultsWithCollectionType:type collectionSubtype:subtype
                                                        options:options]];
}

- (RACSignal *)fetchMetaAlbumWithType:(NSNumber *)type subtype:(NSNumber *)subtype
                            subalbums:(nullable NSArray<NSNumber *> *)subalbums
                              options:(PHFetchOptions * _Nullable)options {
  PTNAssetCollectionsFetchResult *fetchResults = [self fetchResultsWithCollectionType:type
                                                                    collectionSubtype:subtype
                                                                              options:options];
  if (!subalbums) {
    return [RACSignal return:fetchResults];
  }

  NSMutableArray *albums = [NSMutableArray array];
  NSOrderedSet *subtypes = [NSOrderedSet orderedSetWithArray:subalbums];

  for (PHAssetCollection *assetCollection in fetchResults) {
    if ([subtypes containsObject:@(assetCollection.assetCollectionSubtype)]) {
      PHFetchResult *fetchResult = [self.fetcher fetchAssetsInAssetCollection:assetCollection
                                                                      options:nil];
      if (fetchResult.count) {
        [albums addObject:assetCollection];
      }
    }
  }

  [albums sortUsingComparator:^NSComparisonResult(PHAssetCollection *firstCollection,
                                                  PHAssetCollection *secondCollection) {
    NSUInteger firstSubtypeIndex =
        [subtypes indexOfObject:@(firstCollection.assetCollectionSubtype)];
    NSUInteger secondSubtypeIndex =
        [subtypes indexOfObject:@(secondCollection.assetCollectionSubtype)];
    return [@(firstSubtypeIndex) compare:@(secondSubtypeIndex)];
  }];

  // The title of this \c PHCollectionList is never accessed since the returned \c PHFetchResult has
  // no title property, and the \c PHCollectionList created here is never returned as is.
  // \c PHObject objects are returned when performing \c -fetchAsset:, but such an operation isn't
  // supported on URLs of type \c PTNPhotoKitURLTypeMetaAlbumType.
  PHCollectionList *collectionList = [self.fetcher transientCollectionListWithCollections:albums
                                                                                    title:@""];
  return [RACSignal return:[self.fetcher fetchCollectionsInCollectionList:collectionList
                                                                  options:nil]];
}

- (PTNAssetCollectionsFetchResult *)fetchResultsWithCollectionType:(NSNumber *)collectionType
    collectionSubtype:(NSNumber *)collectionSubtype options:(PHFetchOptions * _Nullable)options {
  PHAssetCollectionType type = (PHAssetCollectionType)collectionType.unsignedIntegerValue;
  PHAssetCollectionSubtype subtype =
      (PHAssetCollectionSubtype)collectionSubtype.unsignedIntegerValue;
  return [self.fetcher fetchAssetCollectionsWithType:type subtype:subtype options:options];
}

- (RACSignal *)fetchAlbumWithIdentifier:(NSString *)identifier {
  PTNCollectionsFetchResult *assetCollections =
      [self.fetcher fetchAssetCollectionsWithLocalIdentifiers:@[identifier] options:nil];
  return [RACSignal return:assetCollections];
}

- (RACSignal *)fetchAlbumWithMediaType:(PHAssetMediaType)mediaType
                               options:(PHFetchOptions * _Nullable)options {
  PHFetchResult<PHAsset *> * fetchResult = [self.fetcher fetchAssetsWithMediaType:mediaType
                                                                          options:options];
  PHAssetCollection *collection =
      [self.fetcher transientAssetCollectionWithAssetFetchResult:fetchResult title:nil];
  return [RACSignal return:@[collection]];
}

#pragma mark -
#pragma mark Image fetching
#pragma mark -

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                options:(PTNImageFetchOptions *)options {
  if (![descriptor isKindOfClass:[PHAsset class]] &&
      ![descriptor isKindOfClass:[PHAssetCollection class]]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }

  return [[self fetchAssetForDescriptor:descriptor]
      flattenMap:^(PHAsset *asset) {
        if (options.includeMetadata &&
            ![descriptor.descriptorTraits containsObject:kPTNDescriptorTraitAudiovisualKey]) {
          return [self imageAssetForPhotoKitAssetWithMetadata:asset
                                             resizingStrategy:resizingStrategy];
        }

        return [self imageAssetForPhotoKitAsset:asset resizingStrategy:resizingStrategy
                                        options:[options photoKitOptions]];
      }];
}

- (RACSignal *)imageAssetForPhotoKitAssetWithMetadata:(PHAsset *)asset
                                     resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    PHContentEditingInputRequestOptions *options =
        [[PHContentEditingInputRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double value, BOOL *) {
      LTProgress *progress = [[LTProgress alloc] initWithProgress:value];
      [subscriber sendNext:progress];
    };

    void (^completionHandler)(PHContentEditingInput * _Nullable contentEditingInput,
                              NSDictionary *info) =
        ^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary *info) {
      if (!contentEditingInput.fullSizeImageURL) {
        NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                      url:asset.ptn_identifier
                                          underlyingError:info[PHContentEditingInputErrorKey]];
        [subscriber sendError:wrappedError];
        return;
      }

      NSError *error;
      PTNImageMetadata *metadata = [[PTNImageMetadata alloc]
                                    initWithImageURL:contentEditingInput.fullSizeImageURL
                                    error:&error];
      if (error) {
        NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                      url:asset.ptn_identifier
                                          underlyingError:error];
        [subscriber sendError:wrappedError];
        return;
      }

      [[[self.imageResizer resizeImageAtURL:contentEditingInput.fullSizeImageURL
                           resizingStrategy:resizingStrategy]
        map:^LTProgress<PTNStaticImageAsset *> *(UIImage *image) {
          auto asset = [[PTNStaticImageAsset alloc] initWithImage:image imageMetadata:metadata];
          return [[LTProgress alloc] initWithResult:asset];
      }] subscribe:subscriber];
    };

    PHContentEditingInputRequestID requestID =
        [asset requestContentEditingInputWithOptions:options completionHandler:completionHandler];

    return [RACDisposable disposableWithBlock:^{
      [asset cancelContentEditingInputRequest:requestID];
    }];
  }];
}

- (PHImageContentMode)photoKitContentModeForContentMode:(PTNImageContentMode)contentMode {
  switch (contentMode) {
    case PTNImageContentModeAspectFill:
      return PHImageContentModeAspectFill;
    case PTNImageContentModeAspectFit:
      return PHImageContentModeAspectFit;
  }
}

- (RACSignal *)imageAssetForPhotoKitAsset:(PHAsset *)asset
                         resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                  options:(PHImageRequestOptions *)options {
  return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    options.progressHandler = ^(double value, NSError *error,
                                BOOL __unused *stop, NSDictionary __unused *info) {
      if (!error) {
        LTProgress *progress = [[LTProgress alloc] initWithProgress:value];
        [subscriber sendNext:progress];
      }
    };

    // Technically, this shouldn't matter, but PHImageManager returns a nil image for front camera
    // images that were taken with burst mode with no error, unless PHImageManagerMaximumSize is
    // specified.
    CGSize targetSize = [resizingStrategy
                         sizeForInputSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight)];
    BOOL requestingOriginalSize = targetSize.width == asset.pixelWidth &&
        targetSize.height == asset.pixelHeight;
    CGSize requestedSize = requestingOriginalSize ? PHImageManagerMaximumSize : targetSize;

    void (^resultHandler)(UIImage *result, NSDictionary *info) = ^(UIImage *result,
                                                                   NSDictionary *info) {
      if (!result || info[PHImageErrorKey]) {
        NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                      url:asset.ptn_identifier
                                          underlyingError:info[PHImageErrorKey]];
        [subscriber sendError:wrappedError];
      } else {
        PTNPhotoKitImageAsset *imageAsset = [[PTNPhotoKitImageAsset alloc] initWithImage:result
                                                                                   asset:asset];
        LTProgress *progress = [[LTProgress alloc] initWithResult:imageAsset];
        [subscriber sendNext:progress];
      }

      if (![info[PHImageResultIsDegradedKey] boolValue] ||
          options.deliveryMode == PHImageRequestOptionsDeliveryModeFastFormat) {
        [subscriber sendCompleted];
      }
    };

    PHImageContentMode contentMode =
        [self photoKitContentModeForContentMode:resizingStrategy.contentMode];
    PHImageRequestID requestID = [self.imageManager requestImageForAsset:asset
                                                              targetSize:requestedSize
                                                             contentMode:contentMode options:options
                                                           resultHandler:resultHandler];

    return [RACDisposable disposableWithBlock:^{
      [self.imageManager cancelImageRequest:requestID];
    }];
  }];
}

#pragma mark -
#pragma mark AVAsset fetching
#pragma mark -

- (RACSignal *)fetchAVAssetWithDescriptor:(id<PTNDescriptor>)descriptor
                                  options:(PTNAVAssetFetchOptions *)options {
  if (![descriptor isKindOfClass:[PHAsset class]]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }

  /// Although \c descriptor can only be a \c PHAsset, call to \c fetchAssetForDescriptor for its
  /// authorization check.
  return [[self fetchAssetForDescriptor:descriptor]
      flattenMap:^(PHAsset *asset) {
        if ([asset.descriptorTraits containsObject:kPTNDescriptorTraitLivePhotoKey]) {
          return [self videoAssetForLivePhotoAsset:asset];
        }

        return [self videoAssetForPhotoKitAsset:asset options:[options photoKitOptions]];
      }];
}

- (RACSignal *)videoAssetForLivePhotoAsset:(PHAsset *)asset {
  return [[self fetchAVAssetForLivePhotoAsset:asset]
          map:^LTProgress<AVPlayerItem *> *(LTProgress<AVAsset *> *progress) {
            return [progress map:^PTNAudiovisualAsset *(AVAsset *avasset) {
              return [[PTNAudiovisualAsset alloc] initWithAVAsset:avasset];
            }];
          }];
}

- (RACSignal *)videoAssetForPhotoKitAsset:(PHAsset *)asset
                                  options:(PHVideoRequestOptions *)options {
  return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    options.progressHandler = ^(double value, NSError *error, BOOL *, NSDictionary *) {
      if (!error) {
        LTProgress *progress = [[LTProgress alloc] initWithProgress:value];
        [subscriber sendNext:progress];
      }
    };

    void (^resultHandler)(AVAsset *result, AVAudioMix *audioMix, NSDictionary *info) =
       ^(AVAsset *result, AVAudioMix *, NSDictionary *info) {
      if (!result || info[PHImageErrorKey]) {
        NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                      url:asset.ptn_identifier
                                          underlyingError:info[PHImageErrorKey]];
        [subscriber sendError:wrappedError];
      } else {
        PTNAudiovisualAsset *videoAsset = [[PTNAudiovisualAsset alloc] initWithAVAsset:result];
        LTProgress *progress = [[LTProgress alloc] initWithResult:videoAsset];
        [subscriber sendNext:progress];
        [subscriber sendCompleted];
      }
    };

    PHImageRequestID requestID = [self.imageManager requestAVAssetForVideo:asset options:options
                                                             resultHandler:resultHandler];

    return [RACDisposable disposableWithBlock:^{
      [self.imageManager cancelImageRequest:requestID];
    }];
  }];
}

#pragma mark -
#pragma mark Image data fetching
#pragma mark -

- (RACSignal *)fetchImageDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  if (![descriptor isKindOfClass:[PHAsset class]]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }

  return [[self fetchAssetForDescriptor:descriptor]
      flattenMap:^(PHAsset *asset) {
        return [self imageDataForPhotoKitAsset:asset];
      }];
}

- (RACSignal *)imageDataForPhotoKitAsset:(PHAsset *)asset {
  return [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    auto _Nullable resource = [self photoAssetResourceForAsset:asset];
    if (!resource) {
      [subscriber sendError:[NSError ptn_errorWithCode:PTNErrorCodeInvalidAssetType
                                  associatedDescriptor:asset
                                           description:@"Asset doesn't contain a photo resource"]];
      return nil;
    }

    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double value) {
      LTProgress *progress = [[LTProgress alloc] initWithProgress:value];
      [subscriber sendNext:progress];
    };

    auto mutableData = [NSMutableData data];
    auto dataReceivedHandler = ^(NSData *data) {
      [mutableData appendData:data];
    };

    auto completionHandler = ^(NSError * _Nullable error) {
      if (error) {
        NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                      url:asset.ptn_identifier
                                          underlyingError:error];
        [subscriber sendError:wrappedError];
        return;
      }

      // Avoid copying the data to spare memory and runtime.
      id<PTNImageDataAsset> dataAsset = [[PTNImageDataAsset alloc]
                                         initWithData:mutableData
                                         uniformTypeIdentifier:resource.uniformTypeIdentifier];
      [subscriber sendNext:[[LTProgress alloc] initWithResult:dataAsset]];
      [subscriber sendCompleted];
    };

    auto requestID = [self.assetResourceManager requestDataForAssetResource:resource
                                                                    options:options
                                                        dataReceivedHandler:dataReceivedHandler
                                                          completionHandler:completionHandler];

    return [RACDisposable disposableWithBlock:^{
      [self.assetResourceManager cancelDataRequest:requestID];
    }];
  }] subscribeOn:[RACScheduler scheduler]];
}

- (nullable PHAssetResource *)photoAssetResourceForAsset:(PHAsset *)asset {
  auto resources = [self.fetcher assetResourcesForAsset:asset];

  auto typeToResource = std::map<PHAssetResourceType, PHAssetResource *>();
  for (PHAssetResource *resource in resources) {
    typeToResource[resource.type] = resource;
  }

  // PhotoKit prefers full size resources over others, and otherwise uses the first returned
  // resource. This reflects in the data that PHImageManager returns for an asset, and we prefer to
  // mock that logic.
  static const std::vector<PHAssetResourceType> kTypePriorities{
    PHAssetResourceTypeFullSizePhoto,
    PHAssetResourceTypePhoto,
    PHAssetResourceTypeAlternatePhoto
  };

  for (const auto &type : kTypePriorities) {
    if (typeToResource.find(type) != typeToResource.end()) {
      return typeToResource[type];
    }
  }
  return nil;
}

#pragma mark -
#pragma mark AV preview fetching
#pragma mark -

- (RACSignal *)fetchAVAssetForLivePhotoAsset:(PHAsset *)asset {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    auto options = [[PHLivePhotoRequestOptions alloc] init];
    // In order to fetch the video of the Live Photo, only high quality format must be used.
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double value, NSError *error, BOOL *, NSDictionary *) {
      if (!error) {
        LTProgress *progress = [[LTProgress alloc] initWithProgress:value];
        [subscriber sendNext:progress];
      }
    };

    auto resultHandler = ^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
      if (!livePhoto || info[PHImageErrorKey]) {
        NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                      url:asset.ptn_identifier
                                          underlyingError:info[PHImageErrorKey]];
        [subscriber sendError:wrappedError];
      } else {
        AVAsset * _Nullable avasset = [livePhoto valueForKey:@"videoAsset"];
        // Since we use an undocumented API here, it's better to make sure the asset exist.
        if (!avasset) {
          [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                      url:asset.ptn_identifier]];
          LogError(@"Live photo asset does not contain a video asset");
        } else {
          [subscriber sendNext:[LTProgress progressWithResult:nn(avasset)]];
          [subscriber sendCompleted];
        }
      }
    };

    auto targetSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    auto requestID = [self.imageManager requestLivePhotoForAsset:asset
                                                      targetSize:targetSize
                                                     contentMode:PHImageContentModeDefault
                                                         options:options
                                                   resultHandler:resultHandler];
    return [RACDisposable disposableWithBlock:^{
      [self.imageManager cancelImageRequest:requestID];
    }];
  }];
}

- (RACSignal *)fetchAVPreviewWithDescriptor:(id<PTNDescriptor>)descriptor
                                    options:(PTNAVAssetFetchOptions *)options {
  if (![descriptor isKindOfClass:[PHAsset class]]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }

  /// Although \c descriptor can only be a \c PHAsset, call to \c fetchAssetForDescriptor for its
  /// authorization check.
  return [[self fetchAssetForDescriptor:descriptor]
          flattenMap:^(PHAsset *asset) {
            if ([asset.descriptorTraits containsObject:kPTNDescriptorTraitLivePhotoKey]) {
              return [self playerItemForLivePhotoAsset:asset];
            }

            return [self videoPreviewForPhotoKitAsset:asset options:[options photoKitOptions]];
          }];

}

- (RACSignal *)playerItemForLivePhotoAsset:(PHAsset *)asset {
  return [[self fetchAVAssetForLivePhotoAsset:asset]
    map:^LTProgress<AVPlayerItem *> *(LTProgress<AVAsset *> *progress) {
      return [progress map:^AVPlayerItem *(AVAsset *avasset) {
        return [[AVPlayerItem alloc] initWithAsset:avasset];
      }];
    }];
}

- (RACSignal *)videoPreviewForPhotoKitAsset:(PHAsset *)asset
                                    options:(PHVideoRequestOptions *)options {
  return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    options.progressHandler = ^(double value, NSError *error, BOOL *, NSDictionary *) {
      if (!error) {
        LTProgress *progress = [[LTProgress alloc] initWithProgress:value];
        [subscriber sendNext:progress];
      }
    };

    auto resultHandler = ^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
      if (!playerItem || info[PHImageErrorKey]) {
        NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                      url:asset.ptn_identifier
                                          underlyingError:info[PHImageErrorKey]];
        [subscriber sendError:wrappedError];
      } else {
        LTProgress *progress = [[LTProgress alloc] initWithResult:playerItem];
        [subscriber sendNext:progress];
        [subscriber sendCompleted];
      }
    };

    PHImageRequestID requestID = [self.imageManager requestPlayerItemForVideo:asset options:options
                                                                resultHandler:resultHandler];

    return [RACDisposable disposableWithBlock:^{
      [self.imageManager cancelImageRequest:requestID];
    }];
  }];
}

#pragma mark -
#pragma mark AV data fetching
#pragma mark -

- (RACSignal<LTProgress<id<PTNAVDataAsset>> *>*)
    fetchAVDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnsupportedOperation
                                associatedDescriptor:descriptor]];
}

#pragma mark -
#pragma mark Delete assets
#pragma mark -

- (RACSignal *)deleteDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors {
  NSMutableArray *assets = [NSMutableArray array];
  NSMutableArray *assetCollections = [NSMutableArray array];
  NSMutableArray *collectionLists = [NSMutableArray array];

  for (id<PTNDescriptor> descriptor in descriptors) {
    if ([descriptor isKindOfClass:[PHAsset class]]) {
      [assets addObject:descriptor];
    } else if ([descriptor isKindOfClass:[PHAssetCollection class]]) {
      [assetCollections addObject:descriptor];
    } else if ([descriptor isKindOfClass:[PHCollectionList class]]) {
      [collectionLists addObject:descriptor];
    } else {
      return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                    associatedDescriptor:descriptor]];
    }
  }

  return [[self performChanges:^{
    if (assets.count > 0) {
      [self.changeManager deleteAssets:assets];
    }
    if (assetCollections.count > 0) {
      [self.changeManager deleteAssetCollections:assetCollections];
    }
    if (collectionLists.count > 0) {
      [self.changeManager deleteCollectionLists:collectionLists];
    }
  }] ptn_wrapErrorWithError:[NSError ptn_errorWithCode:PTNErrorCodeAssetDeletionFailed
                                 associatedDescriptors:descriptors]];
}

#pragma mark -
#pragma mark Remove from album
#pragma mark -

- (RACSignal *)removeDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors
                       fromAlbum:(id<PTNAlbumDescriptor>)albumDescriptor {
  if ((![albumDescriptor isKindOfClass:[PHAssetCollection class]] &&
      ![albumDescriptor isKindOfClass:[PHCollectionList class]]) ||
      !(albumDescriptor.albumDescriptorCapabilities & PTNAlbumDescriptorCapabilityRemoveContent)) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:albumDescriptor]];
  }

  NSDictionary<Class, Class> *allowedContentForClass = [[self class] allowedContentForClass];
  for (id<PTNDescriptor> descriptor in descriptors) {
    if (![descriptor isKindOfClass:allowedContentForClass[[albumDescriptor class]]]) {
      return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeAssetRemovalFromAlbumFailed
                                    associatedDescriptor:descriptor]];
    }
  }

  return [[self performChanges:^{
    if ([albumDescriptor isKindOfClass:[PHAssetCollection class]]) {
      [self.changeManager removeAssets:descriptors
                   fromAssetCollection:(PHAssetCollection *)albumDescriptor];
    } else {
      [self.changeManager removeCollections:descriptors
                         fromCollectionList:(PHCollectionList *)albumDescriptor];
    }
  }] catch:^RACSignal *(NSError *error) {
    NSArray *allDescriptors = [@[albumDescriptor] arrayByAddingObjectsFromArray:descriptors];
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeAssetRemovalFromAlbumFailed
                                 associatedDescriptors:allDescriptors underlyingError:error]];
  }];
}

+ (NSDictionary<Class, Class> *)allowedContentForClass {
  static NSDictionary<Class, Class> *allowedContentClass;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    allowedContentClass = @{
      [PHAssetCollection class]: [PHAsset class],
      [PHCollectionList class]: [PHAssetCollection class]
    };
  });

  return allowedContentClass;
}

#pragma mark -
#pragma mark Favorite
#pragma mark -

- (RACSignal *)favoriteDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors
                          favorite:(BOOL)favorite {
  for (id<PTNDescriptor> descriptor in descriptors) {
    if (![descriptor isKindOfClass:[PHAsset class]] ||
        !(((PHAsset *)descriptor).assetDescriptorCapabilities &
        PTNAssetDescriptorCapabilityFavorite)) {
      return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                    associatedDescriptor:descriptor]];
    }
  }

  return [self performChanges:^{
    for (id<PTNDescriptor> descriptor in descriptors) {
      [self.changeManager favoriteAsset:(PHAsset *)descriptor favorite:favorite];
    }
  }];
}

#pragma mark -
#pragma mark Changes
#pragma mark -

- (RACSignal *)performChanges:(LTVoidBlock)changeBlock {
  return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    [self.changeManager performChanges:changeBlock
                     completionHandler:^(BOOL success, NSError * _Nullable error) {
      if (!success) {
         [subscriber sendError:error];
         return;
      }

      [subscriber sendCompleted];
    }];

    return nil;
  }];
}

@end

NS_ASSUME_NONNULL_END
