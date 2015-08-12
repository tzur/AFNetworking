// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAssetManager.h"

#import "NSError+Photons.h"
#import "NSURL+PhotoKit.h"
#import "PTNAlbumChangeset+PhotoKit.h"
#import "PTNImageFetchOptions+PhotoKit.h"
#import "PTNPhotoKitAlbum.h"
#import "PTNPhotoKitAlbumType.h"
#import "PTNPhotoKitFetcher.h"
#import "PTNPhotoKitImageManager.h"
#import "PTNPhotoKitObserver.h"
#import "PTNProgress.h"
#import "PhotoKit+Photons.h"
#import "RACSignal+Photons.h"
#import "RACStream+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitAssetManager ()

/// Observer for PhotoKit changes.
@property (strong, nonatomic) id<PTNPhotoKitObserver> observer;

/// Fetcher adapter for PhotoKit.
@property (strong, nonatomic) id<PTNPhotoKitFetcher> fetcher;

/// Image manager used to request images.
@property (strong, nonatomic) PHImageManager *imageManager;

/// Dictionary from \c NSURL album urls to their \c RACSignal objects.
@property (strong, nonatomic) NSMutableDictionary *albumSignals;

/// Queue for accessing the album signals cache in a readers/writers fashion.
@property (strong, nonatomic) dispatch_queue_t albumSignalsQueue;

@end

@implementation PTNPhotoKitAssetManager

- (instancetype)init {
  return nil;
}

- (instancetype)initWithFetcher:(id<PTNPhotoKitFetcher>)fetcher
                       observer:(id<PTNPhotoKitObserver>)observer
                   imageManager:(id<PTNPhotoKitImageManager>)imageManager {
  if (self = [super init]) {
    self.fetcher = fetcher;
    self.observer = observer;
    self.imageManager = imageManager;

    self.albumSignals = [NSMutableDictionary dictionary];
    self.albumSignalsQueue = dispatch_queue_create("com.lightricks.Photons.PhotoKit.AlbumSignals",
                                                   DISPATCH_QUEUE_CONCURRENT);
  }
  return self;
}

#pragma mark -
#pragma mark Album fetching
#pragma mark -

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  if (url.ptn_photoKitURLType != PTNPhotoKitURLTypeAlbum &&
      url.ptn_photoKitURLType != PTNPhotoKitURLTypeAlbumType) {
    return [RACSignal error:[NSError ptn_invalidURL:url]];
  }

  RACSignal *existingSignal = [self signalForURL:url];
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
  RACSignal *initialChangeset = [[[[[self fetchFetchResultWithURL:url]
      subscribeOn:[RACScheduler scheduler]]
      tryMap:^id(PHFetchResult *fetchResult, NSError *__autoreleasing *errorPtr) {
        if (!fetchResult.count) {
          *errorPtr = [NSError ptn_albumNotFound:url];
          return nil;
        } else if (url.ptn_photoKitURLType == PTNPhotoKitURLTypeAlbum) {
          PHFetchResult *assets = [self.fetcher fetchAssetsInAssetCollection:fetchResult.firstObject
                                                                     options:nil];
          PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithURL:url
                                                         photoKitFetchResult:assets];
          return RACTuplePack(assets, changeset);
        } else if (url.ptn_photoKitURLType == PTNPhotoKitURLTypeAlbumType) {
          PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithURL:url
                                                         photoKitFetchResult:fetchResult];
          return RACTuplePack(fetchResult, changeset);
        } else {
          // TODO:(yaron) assert here.
          __builtin_unreachable();
        }
      }]
      doError:^(NSError __unused *error) {
        [self removeSignalForURL:url];
      }]
      replayLazily];

  // Returns consecutive (PHFetchResult, PTNAlbumChangeset) tuple on each notification.
  // This works by scanning the input stream and producing a stream of streams that contain a single
  // tuple.
  RACSignal *nextChangeset = [[self.observer.photoLibraryChanged
      scanWithStart:initialChangeset reduce:^(RACSignal *previous, PHChange *change) {
        return [[[previous
            takeLast:1]
            reduceEach:^(PHFetchResult *fetchResult, PTNAlbumChangeset *changeset) {
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

  // Returns the latest \c PTNAlbumChangeset that is produced from the fetch results.
  RACSignal *changeset = [[[[RACSignal
      concat:@[initialChangeset, nextChangeset]]
      reduceEach:^(PHFetchResult __unused *fetchResult, PTNAlbumChangeset *changeset) {
        return changeset;
      }]
      distinctUntilChanged]
      ptn_replayLastLazily];

  [self setSignal:changeset forURL:url];

  return changeset;
}

#pragma mark -
#pragma mark Album signals cache
#pragma mark -

- (void)setSignal:(RACSignal *)signal forURL:(NSURL *)url {
  dispatch_barrier_sync(self.albumSignalsQueue, ^{
    self.albumSignals[url] = signal;
  });
}

- (void)removeSignalForURL:(NSURL *)url {
  dispatch_barrier_sync(self.albumSignalsQueue, ^{
    [self.albumSignals removeObjectForKey:url];
  });
}

- (RACSignal *)signalForURL:(NSURL *)url {
  __block RACSignal *signal;

  dispatch_sync(self.albumSignalsQueue, ^{
    signal = self.albumSignals[url];
  });

  return signal;
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

- (RACSignal *)fetchAssetWithURL:(NSURL *)url {
  if (url.ptn_photoKitURLType != PTNPhotoKitURLTypeAsset) {
    return [RACSignal error:[NSError ptn_invalidURL:url]];
  }

  RACSignal *initialFetchResult = [[[[self fetchFetchResultWithURL:url]
      subscribeOn:[RACScheduler scheduler]]
      tryMap:^id(PHFetchResult *fetchResult, NSError *__autoreleasing *errorPtr) {
        if (!fetchResult.count) {
          *errorPtr = [NSError ptn_assetNotFound:url];
        }
        return fetchResult.firstObject;
      }]
      replayLazily];

  RACSignal *nextFetchResults = [[self.observer.photoLibraryChanged
      scanWithStart:initialFetchResult reduce:^(RACSignal *previous, PHChange *change) {
        return [[[previous
            takeLast:1]
            flattenMap:^(PHAsset *asset) {
              PHObject *after = [change changeDetailsForObject:asset].objectAfterChanges;
              return [RACSignal return:after ?: asset];
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
      replayLast];
}

#pragma mark -
#pragma mark Object fetching
#pragma mark -

- (RACSignal *)fetchFetchResultWithURL:(NSURL *)url {
  switch (url.ptn_photoKitURLType) {
    case PTNPhotoKitURLTypeAsset:
      return [self fetchAssetWithIdentifier:url.ptn_photoKitAssetIdentifier];
    case PTNPhotoKitURLTypeAlbum:
      return [self fetchAlbumWithIdentifier:url.ptn_photoKitAlbumIdentifier];
    case PTNPhotoKitURLTypeAlbumType:
      return [self fetchAlbumWithType:url.ptn_photoKitAlbumType];
    default:
      return [RACSignal error:[NSError ptn_invalidURL:url]];
  }
}

- (RACSignal *)fetchObjectWithURL:(NSURL *)url {
  if (url.ptn_photoKitURLType != PTNPhotoKitURLTypeAsset &&
      url.ptn_photoKitURLType != PTNPhotoKitURLTypeAlbum) {
    return [RACSignal error:[NSError ptn_invalidURL:url]];
  }

  return [[self fetchFetchResultWithURL:url]
      tryMap:^PHObject *(PHFetchResult *fetchResult, NSError *__autoreleasing *errorPtr) {
        if (!fetchResult.count) {
          switch (url.ptn_photoKitURLType) {
            case PTNPhotoKitURLTypeAsset:
              *errorPtr = [NSError ptn_assetNotFound:url];
              return nil;
            case PTNPhotoKitURLTypeAlbum:
              *errorPtr = [NSError ptn_albumNotFound:url];
              return nil;
            default:
              // Should never happen, as this handles only assets and albums.
              return nil;
          }
        }
        
        return fetchResult.firstObject;
      }];
}

- (RACSignal *)fetchAssetForObject:(id<PTNObject>)object {
  if ([object isKindOfClass:[PHAsset class]]) {
    return [RACSignal return:object];
  } else if ([object isKindOfClass:[PHAssetCollection class]]) {
    return [[self fetchKeyAssetForAssetCollection:(PHAssetCollection *)object]
        subscribeOn:[RACScheduler scheduler]];
  } else {
    return [RACSignal error:[NSError ptn_invalidObject:object]];
  }
}

- (RACSignal *)fetchAlbumWithType:(PTNPhotoKitAlbumType *)type {
  return [RACSignal defer:^{
    PHFetchResult *assetCollections =
        [self.fetcher fetchAssetCollectionsWithType:type.type subtype:type.subtype options:nil];
    return [RACSignal return:assetCollections];
  }];
}

- (RACSignal *)fetchAlbumWithIdentifier:(NSString *)identifier {
  return [RACSignal defer:^{
    PHFetchResult *assetCollections =
        [self.fetcher fetchAssetCollectionsWithLocalIdentifiers:@[identifier] options:nil];
    return [RACSignal return:assetCollections];
  }];
}

- (RACSignal *)fetchAssetWithIdentifier:(NSString *)identifier {
  return [RACSignal defer:^{
    PHFetchResult *fetchResult =
        [self.fetcher fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    return [RACSignal return:fetchResult];
  }];
}

- (RACSignal *)fetchKeyAssetForAssetCollection:(PHAssetCollection *)assetCollection {
  return [RACSignal defer:^{
    PHFetchResult *fetchResult =
        [self.fetcher fetchKeyAssetsInAssetCollection:assetCollection options:nil];
    if (!fetchResult.firstObject) {
      NSURL *url = [NSURL ptn_photoKitAlbumURLWithCollection:assetCollection];
      return [RACSignal error:[NSError ptn_keyAssetsNotFound:url]];
    } else {
      return [RACSignal return:fetchResult.firstObject];
    }
  }];
}

#pragma mark -
#pragma mark Image fetching
#pragma mark -

- (RACSignal *)fetchImageWithURL:(NSURL *)url
                      targetSize:(CGSize)targetSize
                     contentMode:(PTNImageContentMode)contentMode
                         options:(PTNImageFetchOptions *)options {
  if (url.ptn_photoKitURLType != PTNPhotoKitURLTypeAsset &&
      url.ptn_photoKitURLType != PTNPhotoKitURLTypeAlbum) {
    return [RACSignal error:[NSError ptn_invalidURL:url]];
  }

  return [[self fetchObjectWithURL:url] flattenMap:^(id<PTNObject> object) {
    return [self fetchImageWithObject:object
                           targetSize:targetSize
                          contentMode:contentMode
                              options:options];
  }];
}

- (RACSignal *)fetchImageWithObject:(id<PTNObject>)object
                         targetSize:(CGSize)targetSize
                        contentMode:(PTNImageContentMode)contentMode
                            options:(PTNImageFetchOptions *)options {
  return [[self fetchAssetForObject:object] flattenMap:^(PHAsset *asset) {
    return [self fetchContentForAsset:asset
                           targetSize:targetSize
                          contentMode:[self photoKitContentModeForContentMode:contentMode]
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

- (RACSignal *)fetchContentForAsset:(PHAsset *)asset
                         targetSize:(CGSize)targetSize
                        contentMode:(PHImageContentMode)contentMode
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
    BOOL requestingOriginalSize = targetSize.width == asset.pixelWidth &&
        targetSize.height == asset.pixelHeight;
    CGSize requestedSize = requestingOriginalSize ? PHImageManagerMaximumSize : targetSize;

    void (^resultHandler)(UIImage *result, NSDictionary *info) = ^(UIImage *result,
                                                                   NSDictionary *info) {
      if (!result || info[PHImageErrorKey]) {
        NSError *wrappedError = [NSError ptn_assetLoadingFailed:asset.ptn_identifier
                                                underlyingError:info[PHImageErrorKey]];
        [subscriber sendError:wrappedError];
      } else {
        PTNProgress *progress = [[PTNProgress alloc] initWithResult:result];
        [subscriber sendNext:progress];
      }

      if (![info[PHImageResultIsDegradedKey] boolValue]) {
        [subscriber sendCompleted];
      }
    };

    PHImageRequestID requestID = [self.imageManager requestImageForAsset:asset
                                                              targetSize:requestedSize
                                                             contentMode:contentMode options:options
                                                           resultHandler:resultHandler];

    return [RACDisposable disposableWithBlock:^{
      [self.imageManager cancelImageRequest:requestID];
    }];
  }];
}

@end

NS_ASSUME_NONNULL_END
