// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentMultiProvider.h"

#import "BZRLocalContentProvider.h"
#import "BZRProduct.h"
#import "BZRProductContentMultiProviderParameters.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductContentMultiProvider ()

/// Object used to contain several types of content providers, allowing multiple ways to fetch
/// content.
@property (readonly, nonatomic) NSDictionary<NSString *, id<BZRProductContentProvider>> *
    contentProviders;

@end

@implementation BZRProductContentMultiProvider

- (instancetype)init {
  BZRLocalContentProvider *localContentProvider =
      [[BZRLocalContentProvider alloc] initWithFileManager:[NSFileManager defaultManager]];

  return [self initWithContentProviders:@{
    NSStringFromClass([localContentProvider class]): localContentProvider
  }];
}

- (instancetype)initWithContentProviders:
    (NSDictionary<NSString *, id<BZRProductContentProvider>> *)contentProviders {
  if (self = [super init]) {
    _contentProviders = [contentProviders copy];
  }
  return self;
}

- (RACSignal *)fetchContentForProduct:(BZRProduct *)product {
  LTParameterAssert([product.contentProviderParameters
                     isKindOfClass:[BZRProductContentMultiProvider expectedParametersClass]],
                    @"The product's contentProviderParameters must be of class %@, got %@",
                    [BZRProductContentMultiProvider expectedParametersClass],
                    [product.contentProviderParameters class]);
  BZRProductContentMultiProviderParameters *contentProviderParameters =
    (BZRProductContentMultiProviderParameters *)product.contentProviderParameters;
  
  RACSignal *contentProviderSignal =
      [[self contentProviderFromName:contentProviderParameters.contentProviderName] replayLast];

  RACSignal *contentProviderParametersSignal = [self productForUnderlyingContentProvider:product
      parametersForContentProvider:contentProviderParameters.parametersForContentProvider];

  return [[[RACSignal zip:@[contentProviderSignal, contentProviderParametersSignal]]
      tryMap:^RACTuple *(RACTuple *tuple, NSError **error) {
        RACTupleUnpack(id<BZRProductContentProvider> contentProvider,
                       BZRProduct *productForUnderlyingContentProvider) = tuple;
        if (![productForUnderlyingContentProvider.contentProviderParameters
              isKindOfClass:[contentProvider expectedParametersClass]]) {
          *error = [NSError
                    lt_errorWithCode:BZErrorCodeUnexpectedUnderlyingContentProviderParametersClass];
          return nil;
        }
        return tuple;
      }]
      flattenMap:^RACStream *(RACTuple *tuple) {
        RACTupleUnpack(id<BZRProductContentProvider> contentProvider,
                       BZRProduct *productForUnderlyingContentProvider) = tuple;
        return [contentProvider fetchContentForProduct:productForUnderlyingContentProvider];
  }];
}

- (RACSignal *)contentProviderFromName:(NSString *)contentProviderName {
  @weakify(self);
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    id<BZRProductContentProvider> contentProvider = self.contentProviders[contentProviderName];
    if (!contentProvider) {
      NSError *error;
      NSString *errorDescription = [NSString stringWithFormat:@"Content provider with name %@ "
                                    "is not registered.", contentProviderName];
      error = [NSError lt_errorWithCode:BZErrorCodeProductContentProviderNotRegistered
                            description:errorDescription];
      [subscriber sendError:error];
    } else {
      [subscriber sendNext:contentProvider];
      [subscriber sendCompleted];
    }
    return nil;
  }];
}

- (RACSignal *)productForUnderlyingContentProvider:(BZRProduct *)product
    parametersForContentProvider:(BZRContentProviderParameters *)parametersForContentProvider {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSError *error;
    BZRProduct *productForUnderlyingContentProvider =
        [product productWithContentProviderParameters:parametersForContentProvider error:&error];
    if (!productForUnderlyingContentProvider || error) {
      NSError *invalidParametersError =
          [NSError lt_errorWithCode:BZErrorCodeInvalidUnderlyingContentProviderParameters
          underlyingError:error];
      [subscriber sendError:invalidParametersError];
    } else {
      [subscriber sendNext:productForUnderlyingContentProvider];
      [subscriber sendCompleted];
    }
    return nil;
  }];
}

+ (Class)expectedParametersClass {
  return [BZRProductContentMultiProviderParameters class];
}

@end

NS_ASSUME_NONNULL_END
