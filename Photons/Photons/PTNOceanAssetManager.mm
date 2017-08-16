// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAssetManager.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPResponse.h>
#import <Fiber/RACSignal+Fiber.h>
#import <LTKit/LTProgress.h>
#import <LTKit/LTRandomAccessCollection.h>
#import <LTKit/NSURL+Query.h>

#import "NSError+Photons.h"
#import "NSErrorCodes+Photons.h"
#import "NSURL+Ocean.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNDataBackedImageAsset.h"
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

@end

@implementation PTNOceanAssetManager

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithClient:[FBRHTTPClient client]];
}

- (instancetype)initWithClient:(FBRHTTPClient *)client {
  if (self = [super init]) {
    _client = client;
  }
  return self;
}

#pragma mark -
#pragma mark Album Fetching
#pragma mark -

/// Ocean base endpoint.
static NSString * const kBaseEndpoint = @"https://ocean.lightricks.com/";

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  if (![url.ptn_oceanURLType isEqual:$(PTNOceanURLTypeAlbum)]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }
  NSMutableDictionary<NSString *, NSObject *> *requestParameters =
      [[self oceanRequestParametersWithURL:url] mutableCopy];
  requestParameters[@"phrase"] = url.lt_queryDictionary[@"phrase"];

  return [[[[[self.client GET:[kBaseEndpoint stringByAppendingString:@"search"]
               withParameters:requestParameters headers:nil]
      fbr_deserializeJSON]
      ptn_parseDictionaryWithClass:[PTNOceanAssetSearchResponse class]]
      map:^PTNAlbumChangeset *(PTNOceanAssetSearchResponse *response) {
        auto album = [[PTNAlbum alloc] initWithURL:url subalbums:@[] assets:response.results];
        return [PTNAlbumChangeset changesetWithAfterAlbum:album];
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

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  if (!url.ptn_oceanURLType) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }
  switch (url.ptn_oceanURLType.value) {
    case PTNOceanURLTypeAlbum:
      return [RACSignal return:[[PTNOceanAlbumDescriptor alloc] initWithAlbumURL:url]];
    case PTNOceanURLTypeAsset: {
      NSString *urlString = [@[kBaseEndpoint, @"asset/", url.lt_queryDictionary[@"id"]]
          componentsJoinedByString:@""];
      auto requestParameters = [self oceanRequestParametersWithURL:url];

      return [[[[self.client GET:urlString withParameters:requestParameters headers:nil]
          fbr_deserializeJSON]
          ptn_parseDictionaryWithClass:[PTNOceanAssetDescriptor class]]
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

  if (![assetDescriptor.type isEqual:$(PTNOceanAssetTypePhoto)]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidAssetType
                                                  url:descriptor.ptn_identifier]];
  }
  if (!assetDescriptor.sizes.count) {
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
  std::vector<CGSize> sizes(descriptor.sizes.count);

  for (NSUInteger i = 0; i < sizes.size(); ++i) {
    sizes[i] = CGSizeMake(descriptor.sizes[i].width, descriptor.sizes[i].height);
  }
  auto imageIndex = [self imageIndexForSizes:sizes resizingStrategy:resizingStrategy];
  auto thumbnailIndex = [self thumbnailIndexForSizes:sizes];

  auto imageSignal = [self fetchImageWithURL:descriptor.sizes[imageIndex].url
                            resizingStrategy:resizingStrategy];

  if (imageIndex == thumbnailIndex) {
    return imageSignal;
  }
  auto thumbnailSignal = [self fetchImageWithURL:descriptor.sizes[thumbnailIndex].url
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

- (NSUInteger)imageIndexForSizes:(const std::vector<CGSize> &)sizes
                resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  std::vector<CGFloat> distances(sizes.size());
  std::transform(sizes.cbegin(), sizes.cend(), distances.begin(), [&](CGSize size) {
    CGSize outputSize = [resizingStrategy sizeForInputSize:size];
    return std::hypot(outputSize.width - size.width, outputSize.height - size.height);
  });
  return std::distance(distances.cbegin(), std::min_element(distances.cbegin(), distances.cend()));
}

- (NSUInteger)thumbnailIndexForSizes:(const std::vector<CGSize> &)sizes {
  auto iterator = std::min_element(sizes.cbegin(), sizes.cend(), [](CGSize lhs, CGSize rhs) {
    return lhs.width <= rhs.width && lhs.height <= rhs.height;
  });
  return std::distance(sizes.cbegin(), iterator);
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
        auto result = [[PTNDataBackedImageAsset alloc] initWithData:progress.result.content
                                                   resizingStrategy:resizingStrategy];
        return [[PTNProgress alloc] initWithResult:result];
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
  return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnsupportedOperation
                                associatedDescriptor:descriptor]];
}

@end

NS_ASSUME_NONNULL_END
