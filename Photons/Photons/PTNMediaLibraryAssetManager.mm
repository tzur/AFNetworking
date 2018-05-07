// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNMediaLibraryAssetManager.h"

#import <AVFoundation/AVFoundation.h>
#import <LTKit/LTPath.h>
#import <LTKit/LTRandomAccessCollection.h>
#import <LTKit/NSArray+Functional.h>
#import <MediaPlayer/MediaPlayer.h>

#import "MPMediaItem+Photons.h"
#import "NSError+Photons.h"
#import "NSErrorCodes+Photons.h"
#import "NSURL+MediaLibrary.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNAudiovisualAsset.h"
#import "PTNAuthorizationStatus.h"
#import "PTNDescriptor.h"
#import "PTNFileBackedAVAsset.h"
#import "PTNMediaLibraryAuthorizationManager.h"
#import "PTNMediaLibraryAuthorizer.h"
#import "PTNMediaLibraryCollectionDescriptor.h"
#import "PTNMediaQueryProvider.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"
#import "PTNStaticImageAsset.h"
#import "RACSignal+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNMediaLibraryAssetManager ()

/// Query factory.
@property (readonly, nonatomic) id<PTNMediaQueryProvider> queryProvider;

/// Notifies about Media Library changes.
@property (readonly, nonatomic) RACSignal *changesSignal;

/// Manager of authorization status.
@property (readonly, nonatomic) id<PTNAuthorizationManager> authorizationManager;

@end

@implementation PTNMediaLibraryAssetManager

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithQueryProvider:[[PTNMediaQueryProvider alloc] init]];
}

- (instancetype)initWithQueryProvider:(id<PTNMediaQueryProvider>)queryProvider {
  auto authorizer = [[PTNMediaLibraryAuthorizer alloc] init];
  auto authorizationManager = [[PTNMediaLibraryAuthorizationManager alloc]
                               initWithAuthorizer:authorizer];
  return [self initWithQueryProvider:queryProvider authorizationManager:authorizationManager];
}

- (instancetype)initWithQueryProvider:(id<PTNMediaQueryProvider>)queryProvider
                 authorizationManager:(id<PTNAuthorizationManager>)authorizationManager {
  if (self = [super init]) {
    _queryProvider = queryProvider;
    _authorizationManager = authorizationManager;
    _changesSignal = [[[self changesNotificationSignal]
        takeUntil:self.rac_willDeallocSignal]
        ptn_replayLastLazily];
  }
  return self;
}

- (RACSignal *)changesNotificationSignal {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[MPMediaLibrary defaultMediaLibrary] beginGeneratingLibraryChangeNotifications];

    auto changes = [[[NSNotificationCenter defaultCenter]
                    rac_addObserverForName:MPMediaLibraryDidChangeNotification object:nil]
                    mapReplace:[RACUnit defaultUnit]];
    [changes subscribe:subscriber];

    return [RACDisposable disposableWithBlock:^{
      [[MPMediaLibrary defaultMediaLibrary] endGeneratingLibraryChangeNotifications];
    }];
  }];
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  if (url.ptn_mediaLibraryURLType != PTNMediaLibraryURLTypeAsset &&
      url.ptn_mediaLibraryURLType != PTNMediaLibraryURLTypeAlbum) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [RACSignal defer:^RACSignal *{
    if (self.authorizationManager.authorizationStatus.value != PTNAuthorizationStatusAuthorized) {
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeNotAuthorized url:url]];
    }

    return [[[[[self.changesSignal
        startWith:[RACUnit defaultUnit]]
        mapReplace:[self fetchMediaEntityDescriptorWithURL:url]]
        switchToLatest]
        distinctUntilChanged]
        subscribeOn:[RACScheduler scheduler]];
  }];
}

- (RACSignal *)fetchMediaEntityDescriptorWithURL:(NSURL *)url {
  switch (url.ptn_mediaLibraryURLType) {
    case PTNMediaLibraryURLTypeAsset:
      return [self fetchItemDescriptorWithURL:url];
    case PTNMediaLibraryURLTypeAlbum:
      return [self fetchCollectionDescriptorWithURL:url];
    default:
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }
}

- (RACSignal *)fetchItemDescriptorWithURL:(NSURL *)url {
  return [[self fetchQueryForURL:url]
      tryMap:^MPMediaItem *(id<PTNMediaQuery> query, NSError *__autoreleasing *errorPtr) {
        if (errorPtr) {
          *errorPtr = [NSError lt_errorWithCode:PTNErrorCodeInvalidAssetType url:url];
        }
        return query.items.firstObject;
      }];
}

- (RACSignal *)fetchCollectionDescriptorWithURL:(NSURL *)url {
  return [[self fetchQueryForURL:url]
      tryMap:^PTNMediaLibraryCollectionDescriptor *(id<PTNMediaQuery> query,
                                                    NSError *__autoreleasing *errorPtr) {
        if (errorPtr) {
          *errorPtr = [NSError lt_errorWithCode:PTNErrorCodeInvalidAssetType url:url];
        }
        return [[PTNMediaLibraryCollectionDescriptor alloc]
                initWithCollection:query.collections.firstObject url:url];
      }];
}

- (RACSignal *)fetchQueryForURL:(NSURL *)url {
  auto _Nullable query = [url ptn_mediaLibraryQueryWithProvider:self.queryProvider];
  if (!query) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidAssetType url:url]];
  }

  return [RACSignal return:query];
}

#pragma mark -
#pragma mark Album fetching
#pragma mark -

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  if (url.ptn_mediaLibraryURLType != PTNMediaLibraryURLTypeAlbum) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [RACSignal defer:^RACSignal *{
    if (self.authorizationManager.authorizationStatus.value != PTNAuthorizationStatusAuthorized) {
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeNotAuthorized url:url]];
    }

    return [[[[[self.changesSignal
        startWith:[RACUnit defaultUnit]]
        mapReplace:[self fetchAlbumChangeSetWithURL:url]]
        switchToLatest]
        distinctUntilChanged]
        subscribeOn:[RACScheduler scheduler]];
  }];
}

- (RACSignal *)fetchAlbumChangeSetWithURL:(NSURL *)url {
  return [RACSignal defer:^RACSignal *{
    auto _Nullable query = [url ptn_mediaLibraryQueryWithProvider:self.queryProvider];
    if (!query) {
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidAssetType url:url]];
    }

    auto _Nullable descriptors = [self descriptorsFromQuery:query];
    if (!descriptors) {
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidAssetType url:url]];
    }

    auto album = (url.ptn_mediaLibraryURLType == PTNMediaLibraryURLTypeAsset) ?
        [[PTNAlbum alloc] initWithURL:url subalbums:@[] assets:descriptors] :
        [[PTNAlbum alloc] initWithURL:url subalbums:descriptors assets:@[]];
    return [RACSignal return:[PTNAlbumChangeset changesetWithAfterAlbum:album]];
  }];
}

- (nullable NSArray<id<PTNDescriptor>> *)descriptorsFromQuery:(id<PTNMediaQuery>)query {
  // If the query fetches a array of music albums, e.g. a query obtained by
  // +ptn_mediaLibraryAlbumSongsByMusicAlbum url, return an array of collection descriptors where
  // each is describing a music album.
  if ([[self class] isQueryForMusicMediaTypeByMusicAlbums:query] ||
      [[self class] isQueryForArtistPersistentIDByMusicAlbums:query]) {
    return [query.collections lt_map:^id<PTNDescriptor>(MPMediaItemCollection *collection) {
      auto item = collection.representativeItem;
      auto url = [NSURL ptn_mediaLibraryAlbumMusicAlbumSongsWithItem:item];
      return [[PTNMediaLibraryCollectionDescriptor alloc] initWithCollection:collection url:url];
    }];
  }

  // If a query fetches an array of artist songs, e.g. query obtained by
  // +ptn_mediaLibraryAlbumSongsByArtist:, return array of collection desciptors where each is
  // describing artist's song.
  if ([[self class] isQueryForMusicMediaTypeByArtists:query]) {
    return [query.collections lt_map:^id<PTNDescriptor>(MPMediaItemCollection *collection) {
      auto item = collection.representativeItem;
      auto url = [NSURL ptn_mediaLibraryAlbumArtistSongsWithItem:item];
      return [[PTNMediaLibraryCollectionDescriptor alloc] initWithCollection:collection url:url];
    }];
  }

  // If query fetches a array of songs e.g. a query obtained by +ptn_mediaLibraryAlbumSongs URL,
  // return array of item descriptors.
  if ([[self class] isQueryForAlbumPersistentIDBySongs:query] ||
      [[self class] isQueryForArtistPersistentIDBySongs:query] ||
      [[self class] isQueryForMusicMediaTypeBySongs:query]) {
    // Although MPMediaQuery claims that the items property is NSArray, it returns
    // MPMediaEntityResultSetArray, a subclass of NSArray that contains a bunch of state, and
    // apparently points to mutable data that may change when the media library changes.
    return query.items ? [NSArray arrayWithArray:query.items] : nil;
  }

  return nil;
}

+ (BOOL)isQueryForAlbumPersistentIDBySongs:(id<PTNMediaQuery>)query {
  return [self query:query hasPredicateWithProperty:MPMediaItemPropertyAlbumPersistentID
               value:nil grouping:nil];
}

+ (BOOL)isQueryForArtistPersistentIDBySongs:(id<PTNMediaQuery>)query {
  return [self query:query hasPredicateWithProperty:MPMediaItemPropertyArtistPersistentID
               value:nil grouping:nil];
}

+ (BOOL)isQueryForMusicMediaTypeBySongs:(id<PTNMediaQuery>)query {
  return [self query:query hasPredicateWithProperty:MPMediaItemPropertyMediaType
               value:@(MPMediaTypeMusic) grouping:@(MPMediaGroupingTitle)];
}

+ (BOOL)isQueryForMusicMediaTypeByMusicAlbums:(id<PTNMediaQuery>)query {
  return [self query:query hasPredicateWithProperty:MPMediaItemPropertyMediaType
               value:@(MPMediaTypeMusic) grouping:@(MPMediaGroupingAlbum)];
}

+ (BOOL)isQueryForArtistPersistentIDByMusicAlbums:(id<PTNMediaQuery>)query {
  return [self query:query hasPredicateWithProperty:MPMediaItemPropertyArtistPersistentID
               value:nil grouping:@(MPMediaGroupingAlbum)];
}

+ (BOOL)isQueryForMusicMediaTypeByArtists:(id<PTNMediaQuery>)query {
  return [self query:query hasPredicateWithProperty:MPMediaItemPropertyMediaType
               value:@(MPMediaTypeMusic) grouping:@(MPMediaGroupingArtist)];
}

+ (BOOL)query:(id<PTNMediaQuery>)query hasPredicateWithProperty:(NSString *)property
        value:(nullable NSNumber *)value grouping:(nullable NSNumber *)grouping {
  if (grouping && query.groupingType != (MPMediaGrouping)grouping.integerValue) {
    return NO;
  }

  for (MPMediaPropertyPredicate *predicate in query.filterPredicates) {
    if ([predicate.property isEqualToString:property]) {
      return (!value || (value && [value isEqual:predicate.value]));
    }
  }

  return NO;
}

#pragma mark -
#pragma mark Image fetching
#pragma mark -

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                options:(__unused PTNImageFetchOptions *)options {
  if (![descriptor isKindOfClass:[MPMediaItem class]] &&
      ![descriptor isKindOfClass:[PTNMediaLibraryCollectionDescriptor class]]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidDescriptor]];
  }

  return [[RACSignal
      defer:^RACSignal *{
        if (self.authorizationManager.authorizationStatus.value !=
            PTNAuthorizationStatusAuthorized) {
          return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]];
        }
        return [self fetchImageWithDescriptor:descriptor resizingStrategy:resizingStrategy];
      }]
      subscribeOn:[RACScheduler scheduler]];
}

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  auto _Nullable item = [self itemForDescriptor:descriptor];
  if (!item) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetNotFound]];
  }

  if (!item.artwork) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeKeyAssetsNotFound]];
  }

  auto size = [resizingStrategy sizeForInputSize:item.artwork.bounds.size];
  auto image = [item.artwork imageWithSize:size];
  auto imageAsset = [[PTNStaticImageAsset alloc] initWithImage:image];

  return [RACSignal return:[[PTNProgress alloc] initWithResult:imageAsset]];
}

- (MPMediaItem * _Nullable)itemForDescriptor:(id<PTNDescriptor>)descriptor {
  if ([descriptor isKindOfClass:[MPMediaItem class]]) {
    return ((MPMediaItem *)descriptor);
  } else if ([descriptor isKindOfClass:[PTNMediaLibraryCollectionDescriptor class]]){
    return ((PTNMediaLibraryCollectionDescriptor *)descriptor).collection.representativeItem;
  } else {
    LTParameterAssert(NO, @"%@ is not of a supported type", descriptor);
  }
}

#pragma mark -
#pragma mark AVAsset fetching
#pragma mark -

- (RACSignal *)fetchAVAssetWithDescriptor:(id<PTNDescriptor>)descriptor
                                  options:(PTNAVAssetFetchOptions __unused *)options {
  if (![descriptor isKindOfClass:[MPMediaItem class]]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidDescriptor]];
  }

  return [[self fetchAssetURLWithDescriptor:descriptor] map:^PTNProgress *(NSURL *url) {
    auto asset = [AVURLAsset URLAssetWithURL:url options:nil];
    auto result = [[PTNAudiovisualAsset alloc] initWithAVAsset:asset];
    return [[PTNProgress alloc] initWithResult:result];
  }];
}

- (RACSignal *)fetchAssetURLWithDescriptor:(id<PTNDescriptor>)descriptor {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    if (self.authorizationManager.authorizationStatus.value != PTNAuthorizationStatusAuthorized) {
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]];
    }

    auto item = (MPMediaItem *)descriptor;
    if (!item.assetURL) {
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                    url:item.ptn_identifier]];
    }

    return [RACSignal return:item.assetURL];
  }];
}

#pragma mark -
#pragma mark Image data fetching
#pragma mark -

- (RACSignal *)fetchImageDataWithDescriptor:(__unused id<PTNDescriptor>)descriptor {
  return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeUnsupportedOperation]];
}

#pragma mark -
#pragma mark AV Preview fetching
#pragma mark -

- (RACSignal *)fetchAVPreviewWithDescriptor:(id<PTNDescriptor>)descriptor
                                    options:(PTNAVAssetFetchOptions __unused *)options {
  if (![descriptor isKindOfClass:[MPMediaItem class]]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidDescriptor]];
  }

  return [[self fetchAssetURLWithDescriptor:descriptor] map:^PTNProgress *(NSURL *url) {
    auto playerItem = [AVPlayerItem playerItemWithURL:url];
    return [[PTNProgress alloc] initWithResult:playerItem];
  }];
}

#pragma mark -
#pragma mark AV data fetching
#pragma mark -

- (RACSignal<PTNProgress<id<PTNAVDataAsset>> *>*)
    fetchAVDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  if (![descriptor isKindOfClass:[MPMediaItem class]]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidDescriptor]];
  }

  return [[self fetchAssetURLWithDescriptor:descriptor]
    tryMap:^PTNProgress<id<PTNAVDataAsset>> * _Nullable(NSURL *url,
                                                        NSError *__autoreleasing *error) {
      auto _Nullable path = [LTPath pathWithFileURL:url];
      if (!path) {
        if (error) {
          auto description = [NSString stringWithFormat:@"URL %@ provided by the system for "
                              "descriptor %@ is not a valid file URL", url, descriptor];
          *error = [NSError ptn_errorWithCode:PTNErrorCodeInvalidURL associatedDescriptor:descriptor
                                  description:description];
        }
        return nil;
      }
      auto asset = [[PTNFileBackedAVAsset alloc] initWithFilePath:path];
      return [[PTNProgress alloc] initWithResult:asset];
  }];
}

@end

NS_ASSUME_NONNULL_END
