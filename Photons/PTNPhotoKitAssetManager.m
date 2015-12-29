// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAssetManager.h"

#import "NSError+Photons.h"
#import "NSURL+PhotoKit.h"
#import "PTNAlbumChangeset+PhotoKit.h"
#import "PTNImageContainer.h"
#import "PTNImageFetchOptions+PhotoKit.h"
#import "PTNImageMetadata.h"
#import "PTNPhotoKitAlbum.h"
#import "PTNPhotoKitAlbumType.h"
#import "PTNPhotoKitFetcher.h"
#import "PTNPhotoKitImageManager.h"
#import "PTNPhotoKitObserver.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"
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
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
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
  RACSignal *initialChangeset = [[[[self fetchFetchResultWithURL:url]
      tryMap:^id(PHFetchResult *fetchResult, NSError *__autoreleasing *errorPtr) {
        if (!fetchResult.count) {
          if (errorPtr) {
            *errorPtr = [NSError lt_errorWithCode:PTNErrorCodeAlbumNotFound url:url];
          }
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
          LTAssert(NO, @"Fetched URL of invalid type: %lu", (unsigned long)url.ptn_photoKitURLType);
        }
      }]
      doError:^(NSError __unused *error) {
        [self removeSignalForURL:url];
      }]
      replayLazily];

  // Handle smart album collection differently, since they do not recieve \c PHChange notifications
  // from PhotoKit.
  RACSignal *nextChangeset;
  if (url.ptn_photoKitURLType == PTNPhotoKitURLTypeAlbumType &&
      url.ptn_photoKitAlbumType.type == PHAssetCollectionTypeSmartAlbum) {
    nextChangeset = [self nextChangesetForSmartAlbumCollectionWithURL:url
                                                  andInitialChangeset:initialChangeset];
  } else {
    nextChangeset = [self nextChangesetForRegularAlbumWithURL:url
                                          andInitialChangeset:initialChangeset];
  }

  // Returns the latest \c PTNAlbumChangeset that is produced from the fetch results.
  RACSignal *changeset = [[[[[RACSignal
      concat:@[initialChangeset, nextChangeset]]
      reduceEach:^(PHFetchResult __unused *fetchResult, PTNAlbumChangeset *changeset) {
        return changeset;
      }]
      distinctUntilChanged]
      ptn_replayLastLazily]
      subscribeOn:RACScheduler.scheduler];

  [self setSignal:changeset forURL:url];

  return changeset;
}

- (RACSignal *)nextChangesetForRegularAlbumWithURL:(NSURL *)url
                               andInitialChangeset:(RACSignal *)initialChangeset {
  // Returns consecutive (PHFetchResult, PTNAlbumChangeset) tuple on each notification.
  // This works by scanning the input stream and producing a stream of streams that contain a single
  // tuple.
  return [[self.observer.photoLibraryChanged
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
}

- (RACSignal *)nextChangesetForSmartAlbumCollectionWithURL:(NSURL *)url
                                       andInitialChangeset:(RACSignal *)initialChangeset {
   return [[initialChangeset reduceEach:^(PHFetchResult *initialFetchResult,
                                          PTNAlbumChangeset __unused *changeset) {
     NSMutableArray *signals = [NSMutableArray array];

     // Track changes on each subalbum. For each change fetch the smart album collection
     // again, and send proper change details with the changed smart album. Assumption is that the
     // list of albums doesn't change (since it's a smart album fetch result).
     for (PHAssetCollection *collection in initialFetchResult) {
       NSURL *subalbumURL = [NSURL ptn_photoKitAlbumURLWithCollection:collection];

       RACSignal *signal = [[[[self fetchAlbumWithURL:subalbumURL]
           skip:1]
           flattenMap:^RACStream *(id __unused value) {
             return [self fetchFetchResultWithURL:url];
           }] map:^id(PHFetchResult *newFetchResult) {
             NSUInteger index = [newFetchResult indexOfObject:collection];
             NSArray *changedObjects = index != NSNotFound ? @[newFetchResult[index]] : nil;

             PHFetchResultChangeDetails *changeDetails =
                 [self.fetcher changeDetailsFromFetchResult:initialFetchResult
                                              toFetchResult:newFetchResult
                                             changedObjects:changedObjects];
             PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithURL:url
                                                          photoKitChangeDetails:changeDetails];

             return RACTuplePack(newFetchResult, changeset);
           }];

       [signals addObject:signal];
     }
     
     return [RACSignal merge:signals];
   }] flatten];
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
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

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
  return [[[[RACSignal
      concat:@[initialFetchResult, nextFetchResults]]
      ptn_identicallyDistinctUntilChanged]
      replayLast]
      subscribeOn:RACScheduler.scheduler];
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
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }
}

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  if (url.ptn_photoKitURLType != PTNPhotoKitURLTypeAsset &&
      url.ptn_photoKitURLType != PTNPhotoKitURLTypeAlbum) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [[self fetchFetchResultWithURL:url]
      tryMap:^PHObject *(PHFetchResult *fetchResult, NSError *__autoreleasing *errorPtr) {
        if (!fetchResult.count) {
          switch (url.ptn_photoKitURLType) {
            case PTNPhotoKitURLTypeAsset:
              if (errorPtr) {
                *errorPtr = [NSError lt_errorWithCode:PTNErrorCodeAssetNotFound url:url];
              }
              return nil;
            case PTNPhotoKitURLTypeAlbum:
              if (errorPtr) {
                *errorPtr = [NSError lt_errorWithCode:PTNErrorCodeAlbumNotFound url:url];
              }
              return nil;
            default:
              // Should never happen, as this handles only assets and albums.
              return nil;
          }
        }
        
        return fetchResult.firstObject;
      }];
}

- (RACSignal *)fetchAssetForDescriptor:(id<PTNDescriptor>)descriptor {
  if ([descriptor isKindOfClass:[PHAsset class]]) {
    return [RACSignal return:descriptor];
  } else if ([descriptor isKindOfClass:[PHAssetCollection class]]) {
    return [self fetchKeyAssetForAssetCollection:(PHAssetCollection *)descriptor];
  } else {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }
}

- (RACSignal *)fetchAlbumWithType:(PTNPhotoKitAlbumType *)type {
  return [RACSignal defer:^{
    PTNAssetCollectionsFetchResult *assetCollections =
        [self.fetcher fetchAssetCollectionsWithType:type.type subtype:type.subtype options:nil];
    return [RACSignal return:assetCollections];
  }];
}

- (RACSignal *)fetchAlbumWithIdentifier:(NSString *)identifier {
  return [RACSignal defer:^{
    PTNAssetCollectionsFetchResult *assetCollections =
        [self.fetcher fetchAssetCollectionsWithLocalIdentifiers:@[identifier] options:nil];
    return [RACSignal return:assetCollections];
  }];
}

- (RACSignal *)fetchAssetWithIdentifier:(NSString *)identifier {
  return [RACSignal defer:^{
    PTNAssetsFetchResult *fetchResult =
        [self.fetcher fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    return [RACSignal return:fetchResult];
  }];
}

- (RACSignal *)fetchKeyAssetForAssetCollection:(PHAssetCollection *)assetCollection {
  return [RACSignal defer:^{
    PTNAssetsFetchResult *fetchResult =
        [self.fetcher fetchKeyAssetsInAssetCollection:assetCollection options:nil];
    if (!fetchResult.firstObject) {
      NSURL *url = [NSURL ptn_photoKitAlbumURLWithCollection:assetCollection];
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeKeyAssetsNotFound url:url]];
    } else {
      return [RACSignal return:fetchResult.firstObject];
    }
  }];
}

#pragma mark -
#pragma mark Image fetching
#pragma mark -

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                options:(PTNImageFetchOptions *)options {
  return [[[self fetchAssetForDescriptor:descriptor]
      flattenMap:^(PHAsset *asset) {
        RACSignal *assetContent = [self fetchContentForAsset:asset resizingStrategy:resizingStrategy
                                                     options:[options photoKitOptions]];
        if (!options.fetchMetadata) {
          return assetContent;
        }

        RACSignal *assetContentReplayed = [assetContent ptn_replayLastLazily];

        RACSignal *progressOnly = [assetContentReplayed
            filter:^BOOL(PTNProgress *progress) {
              return progress.progress != nil;
            }];

        RACSignal *resultWithMetadata = [[assetContentReplayed
            filter:^BOOL(PTNProgress *progress) {
              return progress.result != nil;
            }]
            flattenMap:^(PTNProgress<PTNImageContainer *> *progress) {
              return [self attachMetadataOfAsset:asset toImage:progress.result.image];
            }];

        return [progressOnly concat:resultWithMetadata];
      }]
      subscribeOn:RACScheduler.scheduler];
}

- (PHImageContentMode)photoKitContentModeForContentMode:(PTNImageContentMode)contentMode {
  switch (contentMode) {
    case PTNImageContentModeAspectFill:
      return PHImageContentModeAspectFill;
    case PTNImageContentModeAspectFit:
      return PHImageContentModeAspectFit;
  }
}

- (RACSignal *)attachMetadataOfAsset:(PHAsset *)asset toImage:(UIImage *)image {
  return [[self fetchMetadataForAsset:asset options:nil]
      map:^id(PTNImageMetadata *metadata) {
        PTNImageContainer *imageContainer = [[PTNImageContainer alloc]
                                             initWithImage:image metadata:metadata];
        return [[PTNProgress alloc] initWithResult:imageContainer];
      }];
}

- (RACSignal *)fetchContentForAsset:(PHAsset *)asset
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
        PTNImageContainer *imageContainer = [[PTNImageContainer alloc] initWithImage:result];
        PTNProgress *progress = [[PTNProgress alloc] initWithResult:imageContainer];
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

- (RACSignal *)fetchMetadataForAsset:(PHAsset *)asset
                             options:(nullable PHContentEditingInputRequestOptions *)options {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    void (^completionHandler)(PHContentEditingInput *contentEditingInput, NSDictionary *info) =
        ^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
          // \c PHContentEditingInputResultIsInCloudKey is always \c YES, even if photo has already
          /// been downloaded. Check the \c fullSizeImageURL instead.
          if (!contentEditingInput.fullSizeImageURL || info[PHContentEditingInputErrorKey]) {
            NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetMetadataLoadingFailed
                                                          url:asset.ptn_identifier
                                              underlyingError:info[PHContentEditingInputErrorKey]];
            [subscriber sendError:wrappedError];
            return;
          }

          NSError *metadataError;
          PTNImageMetadata *metadata = [[PTNImageMetadata alloc]
                                        initWithImageURL:contentEditingInput.fullSizeImageURL
                                        error:&metadataError];
          if (metadataError) {
            NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetMetadataLoadingFailed
                                                          url:asset.ptn_identifier
                                              underlyingError:metadataError];
            [subscriber sendError:wrappedError];
            return;
          }

          [subscriber sendNext:metadata];
          [subscriber sendCompleted];
        };

    PHContentEditingInputRequestID requestID =
        [asset requestContentEditingInputWithOptions:options completionHandler:completionHandler];

    return [RACDisposable disposableWithBlock:^{
      [asset cancelContentEditingInputRequest:requestID];
    }];
  }];
}

@end

NS_ASSUME_NONNULL_END
