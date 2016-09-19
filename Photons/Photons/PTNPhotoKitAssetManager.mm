// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAssetManager.h"

#import <LTKit/LTRandomAccessCollection.h>

#import "NSError+Photons.h"
#import "NSURL+PhotoKit.h"
#import "PTNAlbumChangeset+PhotoKit.h"
#import "PTNAuthorizationManager.h"
#import "PTNAuthorizationStatus.h"
#import "PTNImageFetchOptions+PhotoKit.h"
#import "PTNImageMetadata.h"
#import "PTNPhotoKitAlbum.h"
#import "PTNPhotoKitAuthorizationManager.h"
#import "PTNPhotoKitAuthorizer.h"
#import "PTNPhotoKitChangeManager.h"
#import "PTNPhotoKitFetcher.h"
#import "PTNPhotoKitImageAsset.h"
#import "PTNPhotoKitImageManager.h"
#import "PTNPhotoKitObserver.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"
#import "PTNSignalCache.h"
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
@property (readonly, nonatomic) PHImageManager *imageManager;

/// Change manager used to request changes in the PhotoKit library.
@property (readonly, nonatomic) id<PTNPhotoKitChangeManager> changeManager;

/// Cache from \c NSURL album urls to their \c RACSignal objects.
@property (readonly, nonatomic) PTNSignalCache *albumSignalCache;

/// Manager of authorization status.
@property (readonly, nonatomic) id<PTNAuthorizationManager> authorizationManager;

@end

@implementation PTNPhotoKitAssetManager

- (instancetype)initWithFetcher:(id<PTNPhotoKitFetcher>)fetcher
                       observer:(id<PTNPhotoKitObserver>)observer
                   imageManager:(id<PTNPhotoKitImageManager>)imageManager
           authorizationManager:(id<PTNAuthorizationManager>)authorizationManager
                  changeManager:(id<PTNPhotoKitChangeManager>)changeManager {
  if (self = [super init]) {
    _fetcher = fetcher;
    _observer = observer;
    _imageManager = imageManager;
    _authorizationManager = authorizationManager;
    _changeManager = changeManager;

    _albumSignalCache = [[PTNSignalCache alloc] init];
  }
  return self;
}

- (instancetype)initWithAuthorizationManager:(id<PTNAuthorizationManager>)authorizationManager {
  id<PTNPhotoKitFetcher> fetcher = [[PTNPhotoKitFetcher alloc] init];
  id<PTNPhotoKitObserver> observer =
      [[PTNPhotoKitObserver alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
  id<PTNPhotoKitImageManager> imageManager = [PHCachingImageManager defaultManager];
  id<PTNPhotoKitChangeManager> changeManager = [[PTNPhotoKitChangeManager alloc] init];
  
  return [self initWithFetcher:fetcher observer:observer imageManager:imageManager
          authorizationManager:authorizationManager changeManager:changeManager];
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
      ![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)]) {
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
  RACSignal *initialChangeset = [[[[self fetchFetchResultWithURL:url]
      tryMap:^id(PHFetchResult *fetchResult, NSError *__autoreleasing *errorPtr) {
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
      subscribeOn:RACScheduler.scheduler]
      ptn_replayLastLazily];

  self.albumSignalCache[url] = changeset;

  return changeset;
}

- (BOOL)isCollectionsFetchResult:(PHFetchResult *)fetchResult validForURL:(NSURL *)url {
  if (fetchResult.count) {
    return YES;
  }

  if (![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)]) {
    return NO;
  }

  return [url.ptn_photoKitMetaAlbumType isEqual:$(PTNPhotoKitMetaAlbumTypeUserAlbums)] ||
      [url.ptn_photoKitMetaAlbumType isEqual:$(PTNPhotoKitMetaAlbumTypePhotosAppSmartAlbums)];
}

- (RACSignal *)nextChangesetForRegularAlbumWithURL:(NSURL *)url
                               andInitialChangeset:(RACSignal *)initialChangeset {
  // Returns consecutive (PHFetchResult, PTNAlbumChangeset) tuple on each notification.
  // This works by scanning the input stream and producing a stream of streams that contain a single
  // tuple.
  return [[self.observer.photoLibraryChanged
        scanWithStart:initialChangeset reduce:(id)^(RACSignal *previous, PHChange *change) {
          return [[[previous
              takeLast:1]
              reduceEach:(id)^(PHFetchResult *fetchResult, PTNAlbumChangeset *changeset) {
                PHFetchResultChangeDetails *details =
                    [change changeDetailsForFetchResult:fetchResult];
                if (details) {
                  PTNAlbumChangeset *newChangeset = [PTNAlbumChangeset changesetWithURL:url
                                                                  photoKitChangeDetails:details];
                  return RACTuplePack(details.fetchResultAfterChanges, newChangeset);
                } else {
                  return RACTuplePack(fetchResult, changeset);
                }
              }]
              replayLazily];
        }]
        concat];
}

- (RACSignal *)nextChangesetForSmartAlbumCollectionWithURL:(NSURL *)url
                                       andInitialChangeset:(RACSignal *)initialChangeset {
  // Track changes on each subalbum. For each change fetch the smart album collection
  // again, and send proper change details with the changed smart album.
  return [initialChangeset flattenMap:^RACStream *(RACTuple *values) {
    PHFetchResult *initialFetchResult = values.first;
    return [[[[[self recursiveUpdatesForSmartAlbums]
      flattenMap:^RACStream *(PHAssetCollection *updatedCollection) {
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
            [self.fetcher changeDetailsFromFetchResult:previousFetch toFetchResult:currentFetch
                                        changedObjects:nil];
        PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithURL:url
                                                     photoKitChangeDetails:changeDetails];

        return RACTuplePack(currentFetch, changeset);
      }];
    }];
}

- (RACSignal *)recursiveUpdatesForSmartAlbums {
  NSURL *smartAlbumURL =
      [NSURL ptn_photoKitMetaAlbumWithType:$(PTNPhotoKitMetaAlbumTypeSmartAlbums)];
  return [[self fetchFetchResultWithURL:smartAlbumURL]
      flattenMap:^RACStream *(PHFetchResult *fetchResult) {
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
      [url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbumType)];
}

- (BOOL)shouldObserveChangesRecursively:(NSURL *)url {
  return [url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)] &&
      ([url.ptn_photoKitMetaAlbumType isEqual:$(PTNPhotoKitMetaAlbumTypeSmartAlbums)] ||
       [url.ptn_photoKitMetaAlbumType isEqual:$(PTNPhotoKitMetaAlbumTypePhotosAppSmartAlbums)]);
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  if (![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAsset)] &&
      ![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbum)] &&
      ![url.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbumType)]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [RACSignal defer:^{
    RACSignal *initialFetchResult = [[[self fetchFetchResultWithURL:url]
      tryMap:^id(PHFetchResult *fetchResult, NSError *__autoreleasing *errorPtr) {
        if (!fetchResult.count) {
          if (errorPtr) {
            *errorPtr = [NSError lt_errorWithCode:PTNErrorCodeAssetNotFound url:url];
          }
        }
        return fetchResult.firstObject;
      }]
      replayLazily];

    RACSignal *nextFetchResults = [[self.observer.photoLibraryChanged
        scanWithStart:initialFetchResult reduce:^(RACSignal *previous, PHChange *change) {
          return [[[previous
              takeLast:1]
              map:^(PHAsset *asset) {
                PHObject *after = [change changeDetailsForObject:asset].objectAfterChanges;
                return after ?: asset;
              }]
              replayLazily];
        }]
        concat];

    // The operator ptn_identicallyDistinctUntilChanged is required because PHFetchResult objects are
    // equal if they back the same asset, even if the asset has changed. This makes sure that only new
    // fetch results are provided, but avoid sending the same fetch result over and over again.
    return [[[RACSignal
        concat:@[initialFetchResult, nextFetchResults]]
        ptn_identicallyDistinctUntilChanged]
        subscribeOn:RACScheduler.scheduler];
  }];
}

#pragma mark -
#pragma mark Object fetching
#pragma mark -

- (RACSignal *)fetchFetchResultWithURL:(NSURL *)url {
  if (![self urlContainsFetchInfo:url]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [RACSignal defer:^RACSignal *{
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
        return [self fetchAlbumWithType:url.ptn_photoKitAlbumType];
      case PTNPhotoKitURLTypeMetaAlbumType:
        return [self fetchMetaAlbumWithType:url.ptn_photoKitMetaAlbumType];
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
      return url.ptn_photoKitAlbumType != nil;
    case PTNPhotoKitURLTypeMetaAlbumType:
      return url.ptn_photoKitMetaAlbumType != nil;
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
          subscribeOn:[RACScheduler scheduler]];
    } else {
      LTAssert(NO, @"Invalid descriptor given: %@", descriptor);
    }
  }];
}

- (RACSignal *)fetchAssetWithIdentifier:(NSString *)identifier {
  PTNAssetsFetchResult *fetchResult =
      [self.fetcher fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
  return [RACSignal return:fetchResult];
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

- (RACSignal *)fetchAlbumWithType:(PTNPhotoKitAlbumType *)type {
  PTNCollectionsFetchResult *assetCollections;
  switch (type.value) {
    case PTNPhotoKitAlbumTypeCameraRoll:
      assetCollections =
          [self.fetcher fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
          subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
      break;
    default:
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL]];
  }

  return [RACSignal return:assetCollections];
}

- (RACSignal *)fetchMetaAlbumWithType:(PTNPhotoKitMetaAlbumType *)type {
  PTNCollectionsFetchResult *assetCollections;
  switch (type.value) {
    case PTNPhotoKitMetaAlbumTypeSmartAlbums:
      assetCollections = [self fetchSmartAlbums];
      break;
    case PTNPhotoKitMetaAlbumTypeUserAlbums:
      assetCollections = [self fetchUserAlbums];
      break;
    case PTNPhotoKitMetaAlbumTypePhotosAppSmartAlbums:
      assetCollections = [self fetchPhotosAppSmartAlbums:[self fetchSmartAlbums]];
      break;
    default:
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL]];
  }
  return [RACSignal return:assetCollections];
}

- (PTNCollectionsFetchResult *)fetchUserAlbums {
  return [self.fetcher fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                             subtype:PHAssetCollectionSubtypeAny options:nil];
}

- (PTNCollectionsFetchResult *)fetchSmartAlbums {
  return [self.fetcher fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                             subtype:PHAssetCollectionSubtypeAny options:nil];
}

- (PTNCollectionsFetchResult *)fetchPhotosAppSmartAlbums:(PHFetchResult *)smartAlbums {
  NSMutableArray *albums = [NSMutableArray array];
  NSOrderedSet *photosAppSubtypes = [[self class] photosAppSubtypes];

  for (PHAssetCollection *assetCollection in smartAlbums) {
    if ([photosAppSubtypes containsObject:@(assetCollection.assetCollectionSubtype)]) {
      PHFetchResult *fetchResult = [self.fetcher fetchAssetsInAssetCollection:assetCollection
                                                                      options:nil];
      if (fetchResult.count) {
        [albums addObject:assetCollection];
      }
    }
  }

  [albums sortUsingComparator:^NSComparisonResult(PHAssetCollection *firstCollection,
                                                  PHAssetCollection *secondCollection) {
    NSUInteger firstSubtypeIndex = [photosAppSubtypes
                                    indexOfObject:@(firstCollection.assetCollectionSubtype)];
    NSUInteger secondSubtypeIndex = [photosAppSubtypes
                                     indexOfObject:@(secondCollection.assetCollectionSubtype)];
    return [@(firstSubtypeIndex) compare:@(secondSubtypeIndex)];
  }];

  // The title of this \c PHCollectionList is never accessed since the returned \c PHFetchResult has
  // no title property, and the \c PHCollectionList created here is never returned as is.
  // \c PHObject objects are returned when performing \c -fetchAsset:, but such an operation isn't
  // supported on URLs of type \c PTNPhotoKitURLTypeMetaAlbumType.
  PHCollectionList *collectionList = [self.fetcher transientCollectionListWithCollections:albums
                                                                                    title:@""];
  return [self.fetcher fetchCollectionsInCollectionList:collectionList options:nil];
}

+ (NSOrderedSet *)photosAppSubtypes {
  static NSOrderedSet *subtypes;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    subtypes = [NSOrderedSet orderedSetWithArray:@[
      @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
      @(PHAssetCollectionSubtypeSmartAlbumFavorites),
      @(PHAssetCollectionSubtypeSmartAlbumGeneric),
      @(PHAssetCollectionSubtypeSmartAlbumPanoramas),
      @(PHAssetCollectionSubtypeSmartAlbumVideos),
      @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos),
      @(PHAssetCollectionSubtypeSmartAlbumTimelapses),
      @(PHAssetCollectionSubtypeSmartAlbumBursts)
    ]];
  });

  return subtypes;
}

- (RACSignal *)fetchAlbumWithIdentifier:(NSString *)identifier {
  PTNCollectionsFetchResult *assetCollections =
      [self.fetcher fetchAssetCollectionsWithLocalIdentifiers:@[identifier] options:nil];
  return [RACSignal return:assetCollections];
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
        return [self imageAssetForPhotoKitAsset:asset resizingStrategy:resizingStrategy
                                        options:[options photoKitOptions]];
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
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    options.progressHandler = ^(double value, NSError *error,
                                BOOL __unused *stop, NSDictionary __unused *info) {
      if (!error) {
        PTNProgress *progress = [[PTNProgress alloc] initWithProgress:@(value)];
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
        PTNProgress *progress = [[PTNProgress alloc] initWithResult:imageAsset];
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
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
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
