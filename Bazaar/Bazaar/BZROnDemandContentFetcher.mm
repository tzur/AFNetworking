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

@implementation BZROnDemandContentFetcher

+ (Class)expectedParametersClass {
  return [BZROnDemandContentFetcherParameters class];
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

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

#pragma mark -
#pragma mark BZREventEmitter
#pragma mark -

- (RACSignal *)eventsSignal {
  return [RACSignal empty];
}

#pragma mark -
#pragma mark BZRProductContentFetcher
#pragma mark -

- (RACSignal *)fetchProductContent:(BZRProduct *)product {
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
  if (![product.contentFetcherParameters isKindOfClass:[[self class] expectedParametersClass]]) {
    return [RACSignal return:nil];
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
