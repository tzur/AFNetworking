// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "PTNOceanClient.h"

#import <AFNetworking/AFNetworking.h>
#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPResponse.h>
#import <Fiber/RACSignal+Fiber.h>
#import <LTKit/LTUTICache.h>

#import "NSErrorCodes+Photons.h"
#import "PTNImageAsset.h"
#import "PTNOceanAssetDescriptor.h"
#import "PTNOceanAssetSearchResponse.h"
#import "PTNOceanEnums.h"
#import "RACSignal+Mantle.h"
#import "RACSignal+Photons.h"

NS_ASSUME_NONNULL_BEGIN

/// Adding attributes related to remote server endpoint.
@interface PTNOceanAssetType (RemoteAddress)

/// Path of the endpoint URL associated for this type, returns \c nil if no endpoint path is
/// associated with the type.
- (nullable NSString *)endpointPath;

@end

@implementation PTNOceanAssetType (RemoteAddress)

- (nullable NSString *)endpointPath {
  switch (self.value) {
    case PTNOceanAssetTypePhoto:
      return @"image";
    case PTNOceanAssetTypeVideo:
      return @"video";
  }
  return nil;
}

@end

@implementation PTNOceanSearchParameters

- (instancetype)initWithType:(PTNOceanAssetType *)type source:(PTNOceanAssetSource *)source
                      phrase:(NSString *)phrase page:(NSUInteger)page {
  if (self = [super init]) {
    _type = type;
    _source = source;
    _phrase = phrase;
    _page = page;
  }
  return self;
}

@end

@implementation PTNOceanAssetFetchParameters

- (instancetype)initWithType:(PTNOceanAssetType *)type source:(PTNOceanAssetSource *)source
                  identifier:(NSString *)identifier {
  if (self = [super init]) {
    _type = type;
    _source = source;
    _identifier = identifier;
  }
  return self;
}

@end

@interface PTNOceanClient ()

/// HTTP Client for sending GET requests to the server.
@property (readonly, nonatomic) FBRHTTPClient *client;

/// Session manager used for downloading files to disk from Ocean.
@property (readonly, nonatomic) AFHTTPSessionManager *sessionManager;

@end

@implementation PTNOceanClient

/// Ocean base endpoint.
static NSString * const kBaseEndpoint = @"https://ocean.lightricks.com";

static NSString * _Nullable PTNEndpointPathForAssetSearch(PTNOceanSearchParameters *parameters) {
  NSString * _Nullable endpointPath = parameters.type.endpointPath;
  if (!endpointPath) {
    return nil;
  }
  return [@[kBaseEndpoint, endpointPath, @"search"] componentsJoinedByString:@"/"];
}

static NSString *PTNEndpointPathForAssetFetch(PTNOceanAssetFetchParameters *parameters) {
  NSString * _Nullable endpointPath = parameters.type.endpointPath;
  if (!endpointPath) {
    return nil;
  }

  return [@[kBaseEndpoint, endpointPath,  @"asset", parameters.identifier]
          componentsJoinedByString:@"/"];
}

static FBRHTTPRequestParameters *PTNOceanBaseRequestParameters() {
  return @{
    @"idfv": [UIDevice currentDevice].identifierForVendor.UUIDString,
    @"bundle": [NSBundle mainBundle].bundleIdentifier ?: @"Unknown"
  };
}

static FBRHTTPRequestParameters *
    PTNRequestParametersForAssetSearch(PTNOceanSearchParameters *parameters) {
  return [@{
    @"phrase": parameters.phrase,
    @"page": [@(parameters.page) stringValue],
    @"source_id": parameters.source.identifier,
  } mtl_dictionaryByAddingEntriesFromDictionary:PTNOceanBaseRequestParameters()];
}

static FBRHTTPRequestParameters *
    PTNRequestParametersForAssetFetch(PTNOceanAssetFetchParameters *parameters) {
  return [@{
    @"source_id": parameters.source.identifier,
  } mtl_dictionaryByAddingEntriesFromDictionary:PTNOceanBaseRequestParameters()];
}

- (instancetype)init {
  auto configuration = [NSURLSessionConfiguration
      backgroundSessionConfigurationWithIdentifier:@"com.lightricks.photons.ocean"];
  auto sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];

  return [self initWithClient:[FBRHTTPClient client] sessionManager:sessionManager];
}

- (instancetype)initWithClient:(FBRHTTPClient *)client
                sessionManager:(AFHTTPSessionManager *)sessionManager {
  if (self = [super init]) {
    _client = client;
    _sessionManager = sessionManager;
  }
  return self;
}

- (RACSignal<PTNOceanAssetSearchResponse *> *)
    searchWithParameters:(PTNOceanSearchParameters *)parameters {
  NSString * _Nullable endpoint = PTNEndpointPathForAssetSearch(parameters);
  if (!endpoint) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidAssetType
        description:@"Invalid asset type %@ given", parameters.type]];
  }

  auto requestParameters = PTNRequestParametersForAssetSearch(parameters);

  return [[[[self.client GET:endpoint withParameters:requestParameters headers:nil]
      fbr_deserializeJSON]
      ptn_parseDictionaryWithClass:[PTNOceanAssetSearchResponse class]]
      ptn_wrapErrorWithError:[NSError lt_errorWithCode:PTNErrorCodeRemoteFetchFailed]];
}

- (RACSignal<PTNOceanAssetDescriptor *> *)
    fetchAssetDescriptorWithParameters:(PTNOceanAssetFetchParameters *)parameters {
  NSString *endpoint = PTNEndpointPathForAssetFetch(parameters);
  auto requestParameters = PTNRequestParametersForAssetFetch(parameters);

  return [[[[self.client GET:endpoint withParameters:requestParameters headers:nil]
      fbr_deserializeJSON]
      ptn_parseDictionaryWithClass:[PTNOceanAssetDescriptor class]]
      ptn_wrapErrorWithError:[NSError lt_errorWithCode:PTNErrorCodeRemoteFetchFailed]];
}

- (RACSignal<PTNProgress<RACTwoTuple<NSData *, NSString *> *> *> *)
    downloadDataWithURL:(NSURL *)url {
  return [[[self.client GET:url.absoluteString withParameters:nil headers:nil]
      map:^PTNProgress<id<PTNImageAsset>> *(LTProgress<FBRHTTPResponse *> *progress) {
        if (!progress.result) {
          return [[PTNProgress alloc] initWithProgress:@(progress.progress)];
        }
        static LTUTICache *utiCache = [LTUTICache sharedCache];
        auto _Nullable uti = progress.result.metadata.MIMEType ?
            [utiCache preferredUTIForMIMEType:progress.result.metadata.MIMEType] : nil;

        return [[PTNProgress alloc] initWithResult:RACTuplePack(progress.result.content, uti)];
      }] ptn_wrapErrorWithError:[NSError lt_errorWithCode:PTNErrorCodeRemoteFetchFailed]];
}

- (RACSignal<PTNProgress<LTPath *> *> *)downloadFileWithURL:(NSURL *)url {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    auto request = [NSURLRequest requestWithURL:url];
    auto progresssBlock = ^(NSProgress *downloadProgress) {
      [subscriber sendNext:[[PTNProgress alloc]
                            initWithProgress:@(downloadProgress.fractionCompleted)]];
    };

    auto destinationBlock = ^NSURL *(NSURL * __unused targetPath, NSURLResponse *response) {
      auto _Nullable uti = response.MIMEType ?
          [LTUTICache.sharedCache preferredUTIForMIMEType:response.MIMEType] : nil;
      auto _Nullable extension = uti ?
          [LTUTICache.sharedCache preferredFileExtensionForUTI:uti] : nil;
      auto filePath = [LTPath temporaryPathWithExtension:(extension ?: @"")];

      return filePath.url;
    };

    auto completionBlock = ^(NSURLResponse * _Nullable response, NSURL * _Nullable fileURL,
                             NSError * _Nullable error) {
      if (!fileURL || !response) {
        [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeRemoteFetchFailed
                                        underlyingError:error]];
        return;
      }

      if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeRemoteFetchFailed
                                        underlyingError:error]];
        return;
      }

      NSUInteger statusCode = ((NSHTTPURLResponse *)nn(response)).statusCode;
      static auto acceptableStatusCodes = [NSIndexSet
                                           indexSetWithIndexesInRange:NSMakeRange(200, 100)];
      if (![acceptableStatusCodes containsIndex:statusCode]) {
        [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeRemoteFetchFailed
                                        underlyingError:error]];
        return;
      }

      auto _Nullable path = [LTPath pathWithFileURL:nn(fileURL)];
      [subscriber sendNext:[[PTNProgress alloc] initWithResult:nn(path)]];
      [subscriber sendCompleted];
    };

    auto task = [self.sessionManager downloadTaskWithRequest:request progress:progresssBlock
                                                 destination:destinationBlock
                                           completionHandler:completionBlock];
    [task resume];

    return [RACDisposable disposableWithBlock:^{
      [task cancel];
    }];
  }];
}

@end

NS_ASSUME_NONNULL_END
