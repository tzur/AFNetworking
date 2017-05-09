// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentMultiFetcher.h"

#import "BZRLocalContentFetcher.h"
#import "BZRProduct.h"
#import "BZRProductContentMultiFetcherParameters.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductContentMultiFetcher ()

/// Object used to contain several types of contentfetchers, allowing multiple ways to fetch
/// content.
@property (readonly, nonatomic) NSDictionary<NSString *, id<BZRProductContentFetcher>> *
    contentFetchers;

@end

@implementation BZRProductContentMultiFetcher

- (instancetype)init {
  BZRLocalContentFetcher *localContentFetcher =
      [[BZRLocalContentFetcher alloc] initWithFileManager:[NSFileManager defaultManager]];

  return [self initWithContentFetchers:@{
    NSStringFromClass([localContentFetcher class]): localContentFetcher
  }];
}

- (instancetype)initWithContentFetchers:
    (NSDictionary<NSString *, id<BZRProductContentFetcher>> *)contentFetchers {
  if (self = [super init]) {
    _contentFetchers = [contentFetchers copy];
  }
  return self;
}

- (RACSignal *)fetchContentForProduct:(BZRProduct *)product {
  if (![product.contentFetcherParameters
        isKindOfClass:[BZRProductContentMultiFetcher expectedParametersClass]]) {
    return [RACSignal error:
            [NSError lt_errorWithCode:BZRErrorCodeUnexpectedContentFetcherParametersClass]];
  }

  BZRProductContentMultiFetcherParameters *contentFetcherParameters =
    (BZRProductContentMultiFetcherParameters *)product.contentFetcherParameters;

  RACSignal *contentFetcherSignal =
      [[self contentFetcherFromName:contentFetcherParameters.contentFetcherName] replayLast];

  RACSignal *contentFetcherParametersSignal = [self productForUnderlyingContentFetcher:product
      parametersForContentFetcher:contentFetcherParameters.parametersForContentFetcher];

  return [[[RACSignal zip:@[contentFetcherSignal, contentFetcherParametersSignal]]
      tryMap:^RACTuple *(RACTuple *tuple, NSError **error) {
        RACTupleUnpack(id<BZRProductContentFetcher> contentFetcher,
                       BZRProduct *productForUnderlyingContentFetcher) = tuple;
        if (![productForUnderlyingContentFetcher.contentFetcherParameters
              isKindOfClass:[[contentFetcher class] expectedParametersClass]]) {
          if (error) {
            *error = [NSError lt_errorWithCode:BZRErrorCodeUnexpectedContentFetcherParametersClass];
          }
          return nil;
        }
        return tuple;
      }]
      flattenMap:^RACStream *(RACTuple *tuple) {
        RACTupleUnpack(id<BZRProductContentFetcher> contentFetcher,
                       BZRProduct *productForUnderlyingContentFetcher) = tuple;
        return [contentFetcher fetchContentForProduct:productForUnderlyingContentFetcher];
  }];
}

- (RACSignal *)contentFetcherFromName:(NSString *)contentFetcherName {
  @weakify(self);
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    id<BZRProductContentFetcher> contentFetcher = self.contentFetchers[contentFetcherName];
    if (!contentFetcher) {
      NSError *error;
      error = [NSError lt_errorWithCode:BZRErrorCodeProductContentFetcherNotRegistered
                            description:@"Contentfetcher with name %@ is not registered.",
               contentFetcherName];
      [subscriber sendError:error];
    } else {
      [subscriber sendNext:contentFetcher];
      [subscriber sendCompleted];
    }
    return nil;
  }];
}

- (RACSignal *)productForUnderlyingContentFetcher:(BZRProduct *)product
    parametersForContentFetcher:(BZRContentFetcherParameters *)parametersForContentFetcher {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSError *error;
    BZRProduct *productForUnderlyingContentFetcher =
        [product productWithContentFetcherParameters:parametersForContentFetcher error:&error];
    if (!productForUnderlyingContentFetcher || error) {
      NSError *invalidParametersError =
          [NSError lt_errorWithCode:BZRErrorCodeInvalidContentFetcherParameters
                    underlyingError:error];
      [subscriber sendError:invalidParametersError];
    } else {
      [subscriber sendNext:productForUnderlyingContentFetcher];
      [subscriber sendCompleted];
    }
    return nil;
  }];
}

+ (Class)expectedParametersClass {
  return [BZRProductContentMultiFetcherParameters class];
}

@end

NS_ASSUME_NONNULL_END
