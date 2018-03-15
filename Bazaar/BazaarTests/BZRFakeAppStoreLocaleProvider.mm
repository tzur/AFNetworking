// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRFakeAppStoreLocaleProvider.h"

#import "BZRProductsProvider.h"
#import "BZRStoreKitMetadataFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRFakeAppStoreLocaleProvider

@synthesize appStoreLocale = _appStoreLocale;

- (instancetype)init {
  return [super initWithProductsProvider:OCMProtocolMock(@protocol(BZRProductsProvider))
                         metadataFetcher:OCMClassMock(BZRStoreKitMetadataFetcher.class)];
}

@end

NS_ASSUME_NONNULL_END
