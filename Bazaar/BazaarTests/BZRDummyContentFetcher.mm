// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRDummyContentFetcher.h"

#import "BZRProduct.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRDummyContentFetcher
#pragma mark -

@implementation BZRDummyContentFetcher

@synthesize eventsSignal = _eventsSignal;

- (RACSignal *)fetchProductContent:(BZRProduct * __unused)product {
  return [RACSignal empty];
}

+ (Class)expectedParametersClass {
  return [BZRDummyContentFetcherParameters class];
}

- (RACSignal *)contentBundleForProduct:(BZRProduct * __unused)product {
  return [RACSignal return:nil];
}

@end

#pragma mark -
#pragma mark BZRDummyContentFetcherParameters
#pragma mark -

@implementation BZRDummyContentFetcherParameters

@synthesize type = _type;

- (instancetype)initWithValue:(NSString *)value {
  if (self = [super init]) {
    _value = [value copy];
    _type = NSStringFromClass([BZRDummyContentFetcher class]);
  }
  return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRDummyContentFetcherParameters, value): @"value"
  };
}

@end

NS_ASSUME_NONNULL_END
