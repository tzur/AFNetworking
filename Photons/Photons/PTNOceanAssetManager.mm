// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAssetManager.h"

#import <AVFoundation/AVPlayerItem.h>
#import <LTKit/LTProgress.h>
#import <LTKit/LTRandomAccessCollection.h>
#import <LTKit/LTUTICache.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSURL+Query.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "NSError+Photons.h"
#import "NSErrorCodes+Photons.h"
#import "NSURL+Ocean.h"
#import "PTNAVAssetFetchOptions.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNCacheInfo.h"
#import "PTNCacheProxy.h"
#import "PTNDataBackedImageAsset.h"
#import "PTNDateProvider.h"
#import "PTNFileBackedAVAsset.h"
#import "PTNImageFetchOptions.h"
#import "PTNOceanAlbumDescriptor.h"
#import "PTNOceanAssetDescriptor.h"
#import "PTNOceanAssetSearchResponse.h"
#import "PTNOceanClient.h"
#import "PTNOceanEnums.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"
#import "RACSignal+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNOceanAssetManager ()

/// Ocean client used to communicate with Ocean servers.
@property (readonly, nonatomic) PTNOceanClient *client;

/// Used for initial time reference for the maximum ages of the cached objects.
@property (readonly, nonatomic) PTNDateProvider *dateProvider;

@end

@implementation PTNOceanAssetManager

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithClient:[[PTNOceanClient alloc] init]
                 dateProvider:[[PTNDateProvider alloc] init]];
}

- (instancetype)initWithClient:(PTNOceanClient *)client
                  dateProvider:(PTNDateProvider *)dateProvider {
  if (self = [super init]) {
    _dateProvider = dateProvider;
    _client = client;
  }
  return self;
}

#pragma mark -
#pragma mark Album Fetching
#pragma mark -

/// Max age, in seconds, of cached \c PTNAlbum objects.
static const NSTimeInterval kAlbumMaxAge = 300;

static PTNOceanSearchParameters * _Nullable PTNAlbumURLToSearchParameters(NSURL *url) {
  if (![url.ptn_oceanURLType isEqual:$(PTNOceanURLTypeAlbum)]) {
    return nil;
  }

  if (!url.ptn_oceanAssetType || !url.ptn_oceanAssetSource || !url.ptn_oceanSearchPhrase ||
      !url.ptn_oceanPageNumber) {
    return nil;
  }

  return [[PTNOceanSearchParameters alloc]
          initWithType:url.ptn_oceanAssetType source:url.ptn_oceanAssetSource
          phrase:url.ptn_oceanSearchPhrase page:[url.ptn_oceanPageNumber unsignedIntegerValue]];
}

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  auto _Nullable parameters = PTNAlbumURLToSearchParameters(url);
  if (!parameters) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [[[self.client searchWithParameters:parameters]
      map:^PTNAlbumChangeset *(PTNOceanAssetSearchResponse *response) {
        auto _Nullable nextAlbumURL = response.page < response.pagesCount ?
            [url lt_URLByReplacingQueryItemsWithName:kPTNOceanURLQueryItemPageKey
                                           withValue:[@(response.page + 1) stringValue]] : nil;
        auto album = [[PTNAlbum alloc] initWithURL:url subalbums:@[] assets:response.results
                                      nextAlbumURL:nextAlbumURL];
        auto cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:kAlbumMaxAge
                                                 responseTime:[self.dateProvider date]
                                                    entityTag:nil];
        auto cacheProxy = [[PTNCacheProxy<PTNAlbum> alloc] initWithUnderlyingObject:album
                                                                          cacheInfo:cacheInfo];
        return [PTNAlbumChangeset changesetWithAfterAlbum:cacheProxy];
      }]
      catch:^RACSignal *(NSError *error) {
        return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAlbumNotFound url:url
                                          underlyingError:error]];
      }];
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

/// Max age, in seconds, of cached \c PTNOceanAssetDescriptor and \c PTNDataBackedImageAsset
/// objects.
static const NSTimeInterval kAssetMaxAge = 86400;

static PTNOceanAssetFetchParameters * _Nullable PTNAssetURLToAssetFetchParameters(NSURL *url) {
  if (![url.ptn_oceanURLType isEqual:$(PTNOceanURLTypeAsset)]) {
    return nil;
  }

  if (!url.ptn_oceanAssetType || !url.ptn_oceanAssetSource || !url.ptn_oceanAssetIdentifier) {
    return nil;
  }

  return [[PTNOceanAssetFetchParameters alloc]
          initWithType:url.ptn_oceanAssetType source:url.ptn_oceanAssetSource
          identifier:url.ptn_oceanAssetIdentifier];
}

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  if (!url.ptn_oceanURLType) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }
  switch (url.ptn_oceanURLType.value) {
    case PTNOceanURLTypeAlbum: {
      auto albumDescriptor = [[PTNOceanAlbumDescriptor alloc] initWithAlbumURL:url];
      auto cacheInfo = [[PTNCacheInfo alloc]
                        initWithMaxAge:[NSDate distantFuture].timeIntervalSince1970
                        responseTime:[self.dateProvider date] entityTag:nil];
      auto cacheProxy = [[PTNCacheProxy alloc] initWithUnderlyingObject:albumDescriptor
                                                              cacheInfo:cacheInfo];
      return [RACSignal return:cacheProxy];
    }
    case PTNOceanURLTypeAsset: {
      auto _Nullable parameters = PTNAssetURLToAssetFetchParameters(url);
      if (!parameters) {
        return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
      }

      return [[[self.client fetchAssetDescriptorWithParameters:parameters]
          map:^PTNCacheProxy *(PTNOceanAssetDescriptor *descriptor) {
            auto cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:kAssetMaxAge
                                                     responseTime:[self.dateProvider date]
                                                        entityTag:nil];
            return [[PTNCacheProxy alloc] initWithUnderlyingObject:descriptor cacheInfo:cacheInfo];
          }]
          catch:^RACSignal *(NSError *error) {
            return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed url:url
                                              underlyingError:error]];
          }];
    }
  }
}

#pragma mark -
#pragma mark Image fetching
#pragma mark -

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                options:(PTNImageFetchOptions *)options {
  if (![descriptor isKindOfClass:[PTNOceanAssetDescriptor class]]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }
  auto assetDescriptor = (PTNOceanAssetDescriptor *)descriptor;

  if (!assetDescriptor.images.count) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }
  return [[self fetchImageContentWithDescriptor:assetDescriptor resizingStrategy:resizingStrategy
                                        options:options]
      catch:^RACSignal *(NSError *error) {
        return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                      url:descriptor.ptn_identifier
                                          underlyingError:error]];
      }];
}

- (RACSignal *)fetchImageContentWithDescriptor:(PTNOceanAssetDescriptor *)descriptor
                              resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                       options:(PTNImageFetchOptions *)options {
  NSArray<PTNOceanImageAssetInfo *> *imagesOrderedBySize =
      [descriptor.images sortedArrayUsingComparator:
       ^NSComparisonResult(PTNOceanImageAssetInfo *lhs, PTNOceanImageAssetInfo *rhs) {
        return [@(rhs.width * rhs.height) compare:@(lhs.width * lhs.height)];
      }];

  auto imageIndex = [self imageIndexForImageInfos:imagesOrderedBySize
                                 resizingStrategy:resizingStrategy];
  auto thumbnailIndex = imagesOrderedBySize.count - 1;

  auto imageSignal = [self fetchImageWithURL:imagesOrderedBySize[imageIndex].url
                            resizingStrategy:resizingStrategy];

  if (imageIndex == thumbnailIndex) {
    return imageSignal;
  }
  auto thumbnailSignal = [self fetchImageWithURL:imagesOrderedBySize[thumbnailIndex].url
                                resizingStrategy:resizingStrategy];

  switch (options.deliveryMode) {
    case PTNImageDeliveryModeFast:
      return thumbnailSignal;
    case PTNImageDeliveryModeHighQuality:
      return imageSignal;
    case PTNImageDeliveryModeOpportunistic:
      return [thumbnailSignal takeUntilReplacement:imageSignal];
  }
}

- (NSUInteger)imageIndexForImageInfos:(NSArray<PTNOceanImageAssetInfo *> *)images
                     resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  NSUInteger index = NSNotFound;
  CGFloat minDistance = CGFLOAT_MAX;

  for (NSUInteger i = 0; i < images.count; ++i) {
    CGSize size = CGSizeMake(images[i].width, images[i].height);
    CGSize outputSize = [resizingStrategy sizeForInputSize:size];
    CGFloat distance = std::hypot(outputSize.width - size.width, outputSize.height - size.height);

    // Using strict inequality will ensure that in scenarios where there are more than one
    // size candidates, the one which has the biggest pixel count is preferred.
    if (distance < minDistance) {
      minDistance = distance;
      index = i;
    }
  }
  return index;
}

- (RACSignal *)fetchImageWithURL:(NSURL *)url
                resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  if (!url.absoluteString) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [[self.client downloadDataWithURL:url]
      map:^PTNProgress<id<PTNImageAsset>> *
          (PTNProgress<RACTwoTuple<NSData *, NSString *> *> *progress) {
        if (!progress.result) {
          return [PTNProgress progressWithProgress:progress.progress];
        }

        RACTupleUnpack(NSData *data, NSString * _Nullable uti) = progress.result;

        auto result = [[PTNDataBackedImageAsset alloc] initWithData:data uniformTypeIdentifier:uti
                                                   resizingStrategy:resizingStrategy];
        auto cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:kAssetMaxAge
                                                 responseTime:[self.dateProvider date]
                                                    entityTag:nil];
        auto cacheProxy = [[PTNCacheProxy alloc] initWithUnderlyingObject:result
                                                                cacheInfo:cacheInfo];
        return [[PTNProgress alloc] initWithResult:cacheProxy];
      }];
}

#pragma mark -
#pragma mark AVAsset fetching
#pragma mark -

- (RACSignal *)fetchAVAssetWithDescriptor:(id<PTNDescriptor>)descriptor
                                  options:(PTNAVAssetFetchOptions __unused *)options {
  return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnsupportedOperation
                                associatedDescriptor:descriptor]];
}

#pragma mark -
#pragma mark Image data fetching
#pragma mark -

- (RACSignal *)fetchImageDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  return [self fetchImageWithDescriptor:descriptor resizingStrategy:[PTNResizingStrategy identity]
                                options:[PTNImageFetchOptions
                                         optionsWithDeliveryMode:PTNImageDeliveryModeHighQuality
                                         resizeMode:PTNImageResizeModeExact
                                         includeMetadata:YES]];
}

#pragma mark -
#pragma mark AV Preview fetching
#pragma mark -

- (RACSignal<PTNProgress<AVPlayerItem *> *> *)
    fetchAVPreviewWithDescriptor:(id<PTNDescriptor>)descriptor
                         options:(PTNAVAssetFetchOptions *)options {
  if (![descriptor isKindOfClass:[PTNOceanAssetDescriptor class]]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }
  auto assetDescriptor = (PTNOceanAssetDescriptor *)descriptor;

  if (![assetDescriptor.type isEqual:$(PTNOceanAssetTypeVideo)]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidAssetType
                                                  url:descriptor.ptn_identifier]];
  }
  if (!assetDescriptor.videos.count) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }
  auto videoAssetInfo = [self videoAssetInfoForDescriptor:assetDescriptor options:options];
  AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoAssetInfo.streamURL];
  return [RACSignal return:[[PTNProgress alloc] initWithResult:playerItem]];
}

/// Returns a comparator that compares video assets by how close their pixel count is to a given
/// resolution.
NSComparator comparatorByDistanceToPixelCount(NSInteger pixelCount) {
  return ^NSComparisonResult(PTNOceanVideoAssetInfo *lhs, PTNOceanVideoAssetInfo *rhs) {
    NSInteger rhsPixels = rhs.width * rhs.height;
    NSInteger lhsPixels = lhs.width * lhs.height;
    return [@(std::llabs(pixelCount - rhsPixels)) compare:@(std::llabs(pixelCount - lhsPixels))];
  };
}

- (PTNOceanVideoAssetInfo *)videoAssetInfoForDescriptor:(PTNOceanAssetDescriptor *)descriptor
                                                options:(PTNAVAssetFetchOptions *)options {
  // This strategy is derived from PhotoKit's documentation for \c PHVideoRequestOptionsDeliveryMode
  // which states that fast returns 360p video, medium returns 720p and auto is like medium.
  static auto comparatorForDeliveryMode = @{
    @(PTNAVAssetDeliveryModeAutomatic) : comparatorByDistanceToPixelCount(720 * 1280),
    @(PTNAVAssetDeliveryModeHighQualityFormat) :
      comparatorByDistanceToPixelCount(NSIntegerMax),
    @(PTNAVAssetDeliveryModeMediumQualityFormat) : comparatorByDistanceToPixelCount(720 * 1280),
    @(PTNAVAssetDeliveryModeFastFormat) : comparatorByDistanceToPixelCount(360 * 640)
  };

  NSComparator comparator = comparatorForDeliveryMode[@(options.deliveryMode)];

  return [[descriptor.videos sortedArrayUsingComparator:comparator] lastObject];
}

#pragma mark -
#pragma mark AV data fetching
#pragma mark -

- (RACSignal<PTNProgress<id<PTNAVDataAsset>> *>*)
    fetchAVDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  if (![descriptor isKindOfClass:[PTNOceanAssetDescriptor class]]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }
  auto assetDescriptor = (PTNOceanAssetDescriptor *)descriptor;

  if (![assetDescriptor.type isEqual:$(PTNOceanAssetTypeVideo)]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidAssetType
                                                  url:descriptor.ptn_identifier]];
  }
  if (!assetDescriptor.videos.count) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }

  auto largestVideo = [assetDescriptor.videos lt_max:^BOOL(PTNOceanVideoAssetInfo *a,
                                                           PTNOceanVideoAssetInfo *b) {
    return a.height * a.width < b.height * b.width;
  }];

  return [[self.client downloadFileWithURL:largestVideo.url]
          map:^PTNProgress<id<PTNAVDataAsset>> *(PTNProgress<LTPath *> *progress) {
            if (!progress.result) {
              return [PTNProgress progressWithProgress:progress.progress];
            }

            auto asset = [[PTNFileBackedAVAsset alloc] initWithFilePath:progress.result];
            return [[PTNProgress alloc] initWithResult:asset];
          }];
}

#pragma mark -
#pragma mark Caching
#pragma mark -

- (RACSignal *)validateAlbumWithURL:(NSURL __unused *)url
                          entityTag:(nullable NSString __unused *)entityTag {
  return [RACSignal return:@NO];
}

- (RACSignal *)validateDescriptorWithURL:(NSURL __unused *)url
                               entityTag:(nullable NSString __unused *)entityTag {
  return [RACSignal return:@NO];
}

- (RACSignal *)validateImageWithDescriptor:(__unused id<PTNDescriptor>)descriptor
                          resizingStrategy:(__unused id<PTNResizingStrategy>)resizingStrategy
                                   options:(PTNImageFetchOptions __unused *)options
                                 entityTag:(nullable NSString __unused *)entityTag {
  return [RACSignal return:@NO];
}

- (nullable NSURL *)canonicalURLForDescriptor:(__unused id<PTNDescriptor>)descriptor
                             resizingStrategy:(__unused id<PTNResizingStrategy>)resizingStrategy
                                      options:(PTNImageFetchOptions __unused *)options {
  return nil;
}

@end

NS_ASSUME_NONNULL_END
