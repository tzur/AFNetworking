// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRFallbackContentFetcher.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRCompositeContentFetcher.h"
#import "BZRProduct.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRFallbackContentFetcher ()

/// Fetcher used to route the content fetcher parameters to the appropriate fetcher.
@property (readonly, nonatomic) BZRCompositeContentFetcher *compositeContentFetcher;

@end

@implementation BZRFallbackContentFetcher

+ (Class)expectedParametersClass {
  return [BZRFallbackContentFetcherParameters class];
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCompositeContentFetcher:
    (BZRCompositeContentFetcher *)compositeContentFetcher {
  if (self = [super init]) {
    _compositeContentFetcher = compositeContentFetcher;
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
  if (![product.contentFetcherParameters isKindOfClass:[[self class] expectedParametersClass]]) {
    return [self invalidFetcherParametersErrorSignal:product];
  }

  NSArray<BZRContentFetcherParameters *> *fetchersParameters =
      ((BZRFallbackContentFetcherParameters *)product.contentFetcherParameters).fetchersParameters;
  if (!fetchersParameters.count) {
    return [self fetchersParametersIsEmptyErrorSignal:product];
  }

  __block NSUInteger fetcherParametersIndex = 0;
  RACSignal<BZRContentFetchingProgress *> *fetchSignal = [RACSignal defer:^{
    auto productWithContentFetcherParameters =
        [product modelByOverridingPropertyAtKeypath:@keypath(product, contentFetcherParameters)
                                          withValue:fetchersParameters[fetcherParametersIndex]];
    return [self.compositeContentFetcher fetchProductContent:productWithContentFetcherParameters];
  }];

  if (fetchersParameters.count == 1) {
    return fetchSignal;
  }

  return [[fetchSignal
      doError:^(NSError *) {
        fetcherParametersIndex++;
      }]
      retry:fetchersParameters.count - 1];
}

- (RACSignal *)invalidFetcherParametersErrorSignal:(BZRProduct *)product {
  auto errorDescription =
      [NSString stringWithFormat:@"Content fetcher of type %@ is expecting parameters of type "
       "%@, got product (%@) with parameters %@", [[self class] expectedParametersClass],
       [self class], product.identifier, product.contentFetcherParameters];
  auto error = [NSError lt_errorWithCode:BZRErrorCodeInvalidContentFetcherParameters
                             description:@"%@", errorDescription];
  return [RACSignal error:error];
}

- (RACSignal *)fetchersParametersIsEmptyErrorSignal:(BZRProduct *)product {
  auto errorDescription =
    [NSString stringWithFormat:@"Content fetcher of type %@ is expecting a non-empty fetchers "
     "parameters list, got product (%@) with parameters %@", [[self class] expectedParametersClass],
     product.identifier, product.contentFetcherParameters];
  auto error = [NSError lt_errorWithCode:BZRErrorCodeInvalidContentFetcherParameters
                             description:@"%@", errorDescription];
  return [RACSignal error:error];
}

- (RACSignal<NSBundle *> *)contentBundleForProduct:(BZRProduct *)product {
  if (![product.contentFetcherParameters isKindOfClass:[[self class] expectedParametersClass]]) {
    return [RACSignal return:nil];
  }

  NSArray<BZRContentFetcherParameters *> *fetchersParameters =
      ((BZRFallbackContentFetcherParameters *)product.contentFetcherParameters).fetchersParameters;
  if (!fetchersParameters.count) {
    return [self fetchersParametersIsEmptyErrorSignal:product];
  }

  auto contentBundleSignals =
      [fetchersParameters
       lt_map:^RACSignal<NSBundle *> *(BZRContentFetcherParameters *fetcherParameters) {
         return [RACSignal defer:^{
           auto productWithContentFetcherParameters =
               [product
                modelByOverridingPropertyAtKeypath:@keypath(product, contentFetcherParameters)
                withValue:fetcherParameters];
           return [self.compositeContentFetcher
                   contentBundleForProduct:productWithContentFetcherParameters];
        }];
      }];

  return [[[[RACSignal
      concat:contentBundleSignals]
      ignore:nil]
      concat:[RACSignal return:nil]]
      take:1];
}

@end

#pragma mark -
#pragma mark BZRFallbackContentFetcherParameters
#pragma mark -

@implementation BZRFallbackContentFetcherParameters

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
    @instanceKeypath(BZRFallbackContentFetcherParameters, fetchersParameters): @"fetchersParameters"
  }];
}

+ (NSValueTransformer *)fetchersParametersJSONTransformer {
  return [NSValueTransformer
          mtl_JSONArrayTransformerWithModelClass:[BZRContentFetcherParameters class]];
}

@end

NS_ASSUME_NONNULL_END
