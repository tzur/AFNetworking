// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZROnDemandContentFetcher.h"

#import <Fiber/FBROnDemandResource.h>
#import <Fiber/NSBundle+OnDemandResources.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "BZRProduct.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZROnDemandContentFetcher ()

/// Bundle used to access On Demand Resources.
@property (readonly, nonatomic) NSBundle *bundle;

/// Dictionary used to hold \c id<FBROnDemandResource> in order to avoid the resources purging
/// while still in use.
@property (readonly, nonatomic) NSMutableDictionary<NSString *, id<FBROnDemandResource>>
    *inUseResources;

/// Manager used to read the checksum file.
@property (readonly, nonatomic) NSFileManager *fileManager;

@end

@implementation BZROnDemandContentFetcher

+ (Class)expectedParametersClass {
  return [BZROnDemandContentFetcherParameters class];
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithBundle:[NSBundle mainBundle] fileManager:[NSFileManager defaultManager]];
}

- (instancetype)initWithBundle:(NSBundle *)bundle fileManager:(NSFileManager *)fileManager {
  if (self = [super init]) {
    _bundle = bundle;
    _fileManager = fileManager;
    _inUseResources = [NSMutableDictionary dictionary];
  }

  return self;
}

#pragma mark -
#pragma mark BZREventEmitter
#pragma mark -

- (RACSignal<BZREvent *> *)eventsSignal {
  return [RACSignal empty];
}

#pragma mark -
#pragma mark BZRProductContentFetcher
#pragma mark -

- (RACSignal<BZRContentFetchingProgress *> *)fetchProductContent:(BZRProduct *)product {
  Class expectedParametersClass = [[self class] expectedParametersClass];
  if (![product.contentFetcherParameters isKindOfClass:expectedParametersClass]) {
    auto error = [NSError lt_errorWithCode:BZRErrorCodeInvalidContentFetcherParameters
                               description:@"The provided parameters class must be: %@",
                               expectedParametersClass];
    return [RACSignal error:error];
  }

  NSSet<NSString *> *tags =
      ((BZROnDemandContentFetcherParameters *)product.contentFetcherParameters).tags;

  @weakify(self)
  return [[[[self.bundle fbr_beginAccessToResourcesWithTags:tags]
      try:^BOOL(LTProgress<id<FBROnDemandResource>> *progress, NSError * __autoreleasing *error) {
        @strongify(self)
        return !progress.result || [self isDownloadedContent:progress.result.bundle
                                              matchesProduct:product error:error];
      }]
      doNext:^(LTProgress<id<FBROnDemandResource>> *progress) {
        @strongify(self)
        if (!self) {
          return;
        }

        if (progress.result) {
          @synchronized(self) {
            self.inUseResources[product.identifier] = progress.result;
          }
        }
      }]
      map:^BZRContentFetchingProgress *(LTProgress<id<FBROnDemandResource>> *progress) {
        if (!progress.result) {
          return [[LTProgress alloc] initWithProgress:progress.progress];
        }

        return [[LTProgress alloc] initWithResult:progress.result.bundle];
      }];
}

- (RACSignal<NSBundle *> *)contentBundleForProduct:(BZRProduct *)product {
  if (![product.contentFetcherParameters isKindOfClass:[[self class] expectedParametersClass]]) {
    return [RACSignal return:nil];
  }

  NSSet<NSString *> *tags =
      ((BZROnDemandContentFetcherParameters *)product.contentFetcherParameters).tags;
  @weakify(self)
  return [[[[[[self.bundle fbr_conditionallyBeginAccessToResourcesWithTags:tags]
      filter:^BOOL(id<FBROnDemandResource> _Nullable resource) {
        @strongify(self)
        return resource && [self isDownloadedContent:resource.bundle matchesProduct:product
                                               error:NULL];
      }]
      doNext:^(id<FBROnDemandResource> resource) {
        @strongify(self)
        if (!self) {
          return;
        }

        @synchronized(self) {
          self.inUseResources[product.identifier] = resource;
        }
      }]
      map:^NSBundle *(id<FBROnDemandResource> resource) {
        return resource.bundle;
      }]
      concat:[RACSignal return:nil]]
      take:1];
}

- (BOOL)isDownloadedContent:(NSBundle *)contentBundle matchesProduct:(BZRProduct *)product
                      error:(NSError * __autoreleasing *)error {
  NSString * _Nullable contentChecksum =
      [self checksumFromContentFileForProduct:product contentBundle:contentBundle error:error];
  if (!contentChecksum) {
    return NO;
  }

  NSString *productChecksum =
      ((BZROnDemandContentFetcherParameters *)product.contentFetcherParameters).checksum;
  if (![contentChecksum isEqualToString:productChecksum]) {
    if (error) {
      *error = [NSError lt_errorWithCode:BZRErrorCodeFetchedContentMismatch
                             description:@"A version mismatch was found between the product %@ and "
                                          "its downloaded content. Product checksum: %@, "
                                          "downloaded content checksum: %@", product.identifier,
                                          productChecksum, contentChecksum];
    }
    return NO;
  }

  return YES;
}

- (nullable NSString *)checksumFromContentFileForProduct:(BZRProduct *)product
                                           contentBundle:(NSBundle *)contentBundle
                                                   error:(NSError * __autoreleasing *)error {
  auto _Nullable checksumFilePath =
      [self checksumFilePathForProduct:product contentBundle:contentBundle error:error];
  if (!checksumFilePath) {
    return nil;
  }

  return [self checksumFromFileAtPath:checksumFilePath error:error];
}

- (nullable NSString *)checksumFilePathForProduct:(BZRProduct *)product
                                    contentBundle:(NSBundle *)contentBundle
                                            error:(NSError * __autoreleasing *)error {
  auto _Nullable checksumFilePath = [contentBundle pathForResource:product.identifier
                                                            ofType:@"checksum"];
  if (!checksumFilePath && error) {
    *error = [NSError lt_errorWithCode:BZRErrorCodeFetchedContentMismatch
                           description:@"Content checksum file %@.checksum was not found",
                                        product.identifier];
  }

  return checksumFilePath;
}

- (nullable NSString *)checksumFromFileAtPath:(NSString *)path
                                        error:(NSError * __autoreleasing *)error {
  NSError *underlyingError;
  NSData * _Nullable data =
      [self.fileManager lt_dataWithContentsOfFile:path options:0 error:&underlyingError];
  if (!data && error) {
    *error = [NSError lt_errorWithCode:BZRErrorCodeFetchedContentMismatch
                       underlyingError:underlyingError
                           description:@"Failed to read the content checksum file %@", path];
  }

  return data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
}

@end

#pragma mark -
#pragma mark BZROnDemandContentFetcherParameters
#pragma mark -

@implementation BZROnDemandContentFetcherParameters

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
    @instanceKeypath(BZROnDemandContentFetcherParameters, tags): @"tags",
    @instanceKeypath(BZROnDemandContentFetcherParameters, checksum): @"checksum"
  }];
}

+ (NSValueTransformer *)tagsJSONTransformer {
  return [MTLValueTransformer
          reversibleTransformerWithForwardBlock:^NSSet<NSString *> *(NSArray<NSString *> *tags) {
            return [NSSet setWithArray:tags];
          }
          reverseBlock:^NSArray<NSString *> *(NSSet<NSString *> *tags) {
            return [tags allObjects];
          }];
}

@end

NS_ASSUME_NONNULL_END
