// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZROnDemandContentFetcher.h"

#import <Fiber/FBROnDemandResource.h>
#import <Fiber/NSBundle+OnDemandResources.h>

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

@end

#pragma mark -
#pragma mark BZROnDemandContentFetcher
#pragma mark -

@implementation BZROnDemandContentFetcher

- (instancetype)init {
  return [self initWithBundle:[NSBundle mainBundle]];
}

- (instancetype)initWithBundle:(NSBundle *)bundle {
  if (self = [super init]) {
    _bundle = bundle;
    _inUseResources = [NSMutableDictionary dictionary];
  }

  return self;
}

- (RACSignal *)fetchProductContent:(BZRProduct *)product {
  if (![product.contentFetcherParameters
        isKindOfClass:[BZROnDemandContentFetcherParameters class]]) {
    NSError *error = [NSError lt_errorWithCode:BZRErrorCodeInvalidContentFetcherParameters
                                   description:@"The provided parameters class must be: %@",
                                               [BZROnDemandContentFetcherParameters class]];
    return [RACSignal error:error];
  }

  NSSet<NSString *> *tags =
      ((BZROnDemandContentFetcherParameters *)product.contentFetcherParameters).tags;

  @weakify(self)
  return [[self.bundle fbr_beginAccessToResourcesWithTags:tags]
      map:^LTProgress<NSBundle *> *(LTProgress<id<FBROnDemandResource>> *progress) {
        @strongify(self)
        if (!progress.result) {
          return [[LTProgress alloc] initWithProgress:progress.progress];
        }

        @synchronized(self) {
          self.inUseResources[product.identifier] = progress.result;
        }
        return [[LTProgress alloc] initWithResult:progress.result.bundle];
      }];
}

- (RACSignal *)contentBundleForProduct:(BZRProduct *)product {
  if (![product.contentFetcherParameters
        isKindOfClass:[BZROnDemandContentFetcherParameters class]]) {
    LogError(@"The provided parameters class must be: %@",
             [BZROnDemandContentFetcherParameters class]);
    return nil;
  }

  NSSet<NSString *> *tags =
      ((BZROnDemandContentFetcherParameters *)product.contentFetcherParameters).tags;
  @weakify(self)
  return [[self.bundle fbr_conditionallyBeginAccessToResourcesWithTags:tags]
      map:^NSBundle * _Nullable(id<FBROnDemandResource> _Nullable resource) {
        @strongify(self)
        if (resource) {
          @synchronized(self) {
            self.inUseResources[product.identifier] = resource;
          }
        }
        return resource.bundle;
      }];
}

+ (Class)expectedParametersClass {
  return [BZROnDemandContentFetcherParameters class];
}

@end

#pragma mark -
#pragma mark BZROnDemandContentFetcherParameters
#pragma mark -

@implementation BZROnDemandContentFetcherParameters

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
    @instanceKeypath(BZROnDemandContentFetcherParameters, tags): @"tags"
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
