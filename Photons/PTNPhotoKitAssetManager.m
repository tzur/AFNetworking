// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAssetManager.h"

#import "NSError+Photons.h"
#import "NSURL+PhotoKit.h"
#import "PTNPhotoKitAlbum.h"
#import "PTNPhotoKitAlbumType.h"
#import "PTNPhotoKitFetcher.h"
#import "PTNPhotoKitObserver.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitAssetManager ()

/// Observer for PhotoKit changes.
@property (strong, nonatomic) PTNPhotoKitObserver *observer;

/// Fetcher adapter for PhotoKit.
@property (strong, nonatomic) PTNPhotoKitFetcher *fetcher;

/// Dictionary from \c NSURL album urls to their \c RACSignal objects.
@property (strong, nonatomic) NSMutableDictionary *albumSignals;

@end

@implementation PTNPhotoKitAssetManager

- (instancetype)initWithFetcher:(PTNPhotoKitFetcher *)fetcher
                       observer:(PTNPhotoKitObserver *)observer {
  if (self = [super init]) {
    self.fetcher = fetcher;
    self.observer = observer;

    self.albumSignals = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark -
#pragma mark Operations
#pragma mark -

- (RACSignal *)albumWithURL:(NSURL *)url {
  if (self.albumSignals[url]) {
    return self.albumSignals[url];
  }

  // Returns initial PHFetchResult from PhotoKit.
  RACSignal *initialFetchResult = [[[[self fetchInitialAlbumWithURL:url]
      subscribeOn:[RACScheduler scheduler]]
      tryMap:^(PHFetchResult *fetchResult, NSError *__autoreleasing *errorPtr) {
        if (!fetchResult) {
          *errorPtr = [NSError ptn_albumNotFound:url];
        }
        return fetchResult;
      }]
      replayLazily];

  // Returns consecutive fetch results on each notification.
  // This works by scanning the input stream and producing a stream of streams that contain a single
  // value of PHFetchResult.
  RACSignal *nextFetchResults = [[[self.observer.photoLibraryChanged
      scanWithStart:initialFetchResult reduce:^(RACSignal *previous, PHChange *change) {
        return [[[previous
            takeLast:1]
            flattenMap:^(PHFetchResult *fetchResult) {
              PHFetchResult *after =
                  [change changeDetailsForFetchResult:fetchResult].fetchResultAfterChanges;
              return [RACSignal return:after ?: fetchResult];
            }]
            replayLazily];
      }]
      concat]
      distinctUntilChanged];

  // Returns the latest \c PhotoKitAlbum that is produced from the fetch results.
  self.albumSignals[url] = [[[RACSignal
      concat:@[initialFetchResult, nextFetchResults]]
      map:^id(PHFetchResult *fetchResult) {
        switch (url.ptn_photoKitURLType) {
          case PTNPhotoKitURLTypeAlbum:
            return [[PTNPhotoKitAlbum alloc] initWithAssets:fetchResult];
            break;
          case PTNPhotoKitURLTypeAlbumType:
            return [[PTNPhotoKitAlbum alloc] initWithAlbums:fetchResult];
            break;
          default:
            return nil;
        }
      }]
      replayLast];

  return self.albumSignals[url];
}

- (RACSignal *)fetchInitialAlbumWithURL:(NSURL *)url {
  switch (url.ptn_photoKitURLType) {
    case PTNPhotoKitURLTypeAlbum:
      return [self fetchAlbumWithIdentifier:url.ptn_photoKitAlbumIdentifier];
    case PTNPhotoKitURLTypeAlbumType:
      return [self fetchAlbumWithType:url.ptn_photoKitAlbumType];
    default:
      return [RACSignal error:[NSError ptn_invalidURL:url]];
  }
}

- (RACSignal *)fetchAlbumWithType:(PTNPhotoKitAlbumType *)type {
  return [RACSignal
      defer:^{
        PHFetchResult *assetCollections =
            [self.fetcher fetchAssetCollectionsWithType:type.type subtype:type.subtype options:nil];
        return [RACSignal return:assetCollections];
      }];
}

- (RACSignal *)fetchAlbumWithIdentifier:(NSString *)identifier {
  return [RACSignal
      defer:^{
        PHFetchResult *assetCollection =
            [self.fetcher fetchAssetCollectionsWithLocalIdentifiers:@[identifier] options:nil];
        PHFetchResult *fetchResult =
            [self.fetcher fetchAssetsInAssetCollection:assetCollection.firstObject options:nil];
        return [RACSignal return:fetchResult];
      }];
}

@end

NS_ASSUME_NONNULL_END
