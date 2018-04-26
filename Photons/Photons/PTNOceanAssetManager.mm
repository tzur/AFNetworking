// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAssetManager.h"

#import <AVFoundation/AVPlayerItem.h>
#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPResponse.h>
#import <Fiber/RACSignal+Fiber.h>
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
#import "PTNImageFetchOptions.h"
#import "PTNOceanAlbumDescriptor.h"
#import "PTNOceanAssetDescriptor.h"
#import "PTNOceanAssetSearchResponse.h"
#import "PTNOceanEnums.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"
#import "RACSignal+Mantle.h"
#import "RACSignal+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNOceanAssetManager ()

/// HTTP Client for sending GET requests to Ocean.
@property (readonly, nonatomic) FBRHTTPClient *client;

/// Used for initial time reference for the maximum ages of the cached objects.
@property (readonly, nonatomic) PTNDateProvider *dateProvider;

@end

@implementation PTNOceanAssetManager

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithClient:[FBRHTTPClient client] dateProvider:[[PTNDateProvider alloc] init]];
}

- (instancetype)initWithClient:(FBRHTTPClient *)client
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

/// Ocean base endpoint.
static NSString * const kBaseEndpoint = @"https://ocean.lightricks.com";

/// Max age, in seconds, of cached \c PTNAlbum objects.
static const NSTimeInterval kAlbumMaxAge = 300;

NSString * _Nullable PTNSearchEndpointFromType(PTNOceanAssetType *assetType) {
  static NSDictionary *assetTypeToEndpointPath = @{
    $(PTNOceanAssetTypePhoto): @"image",
    $(PTNOceanAssetTypeVideo): @"video"
  };

  NSString * _Nullable endpointPath = assetTypeToEndpointPath[assetType];
  if (!endpointPath) {
    return nil;
  }
  return [@[kBaseEndpoint, endpointPath, @"search"] componentsJoinedByString:@"/"];
}

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  if (![url.ptn_oceanURLType isEqual:$(PTNOceanURLTypeAlbum)]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  auto _Nullable assetType = url.ptn_oceanAssetType;
  if (!assetType) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  NSMutableDictionary<NSString *, NSObject *> *requestParameters =
      [[self oceanRequestParametersWithURL:url] mutableCopy];
  requestParameters[@"phrase"] = url.lt_queryDictionary[@"phrase"];
  requestParameters[@"page"] = url.lt_queryDictionary[@"page"];

  NSString * _Nullable endpoint = PTNSearchEndpointFromType(assetType);
  if (!endpoint) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidAssetType url:url]];
  }
  return [[[[[self.client GET:endpoint withParameters:requestParameters headers:nil]
      fbr_deserializeJSON]
      ptn_parseDictionaryWithClass:[PTNOceanAssetSearchResponse class]]
      map:^PTNAlbumChangeset *(PTNOceanAssetSearchResponse *response) {
        auto _Nullable nextAlbumURL = response.page < response.pagesCount ?
            [url lt_URLByReplacingQueryItemsWithName:@"page"
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

- (FBRHTTPRequestParameters *)oceanRequestParametersWithURL:(NSURL *)url {
  return @{
    @"source_id": url.lt_queryDictionary[@"source"],
    @"idfv": [UIDevice currentDevice].identifierForVendor.UUIDString
  };
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

/// Max age, in seconds, of cached \c PTNOceanAssetDescriptor and \c PTNDataBackedImageAsset
/// objects.
static const NSTimeInterval kAssetMaxAge = 86400;

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
      auto _Nullable assetType = url.ptn_oceanAssetType;
      if (!assetType) {
        return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
      }

      if (![assetType isEqual:$(PTNOceanAssetTypePhoto)]) {
        return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidAssetType url:url]];
      }

      NSString *urlString = [@[kBaseEndpoint, @"asset", url.lt_queryDictionary[@"id"]]
          componentsJoinedByString:@"/"];
      auto requestParameters = [self oceanRequestParametersWithURL:url];

      return [[[[[self.client GET:urlString withParameters:requestParameters headers:nil]
          fbr_deserializeJSON]
          ptn_parseDictionaryWithClass:[PTNOceanAssetDescriptor class]]
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
        return [@(lhs.width * lhs.height) compare:@(rhs.width * rhs.height)];
      }];

  auto imageIndex = [self imageIndexForImageInfos:imagesOrderedBySize
                                 resizingStrategy:resizingStrategy];
  NSUInteger thumbnailIndex = 0;

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

/// Returns the image info from \c images matching \c resizing strategy. \c images must be sorted
/// ascending by pixel count.
- (NSUInteger)imageIndexForImageInfos:(NSArray<PTNOceanImageAssetInfo *> *)images
                     resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  for (NSUInteger i = 0; i < images.count; ++i) {
    CGSize size = CGSizeMake(images[i].width, images[i].height);
    if ([resizingStrategy inputSizeBoundedBySize:size]) {
      return i;
    }
  }
  return images.count - 1;
}

- (RACSignal *)fetchImageWithURL:(NSURL *)url
                resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  if (!url.absoluteString) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }
  return [[self.client GET:url.absoluteString withParameters:nil headers:nil]
      map:^PTNProgress<id<PTNImageAsset>> *(LTProgress<FBRHTTPResponse *> *progress) {
        if (!progress.result) {
          return [[PTNProgress alloc] initWithProgress:@(progress.progress)];
        }
        static LTUTICache *utiCache = [LTUTICache sharedCache];
        auto _Nullable uti = progress.result.metadata.MIMEType ?
            [utiCache preferredUTIForMIMEType:progress.result.metadata.MIMEType] : nil;
        auto result = [[PTNDataBackedImageAsset alloc]
                       initWithData:progress.result.content uniformTypeIdentifier:uti
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
