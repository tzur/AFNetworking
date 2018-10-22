// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRFakeAppStoreLocaleProvider.h"

#import "BZRAppStoreLocaleCache.h"
#import "BZRProductsProvider.h"
#import "BZRStoreKitMetadataFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRFakeAppStoreLocaleProvider

@synthesize appStoreLocale = _appStoreLocale;
@synthesize localeFetchedFromProductList = _localeFetchedFromProductList;

- (instancetype)init {
  return [super initWithCache:OCMClassMock([BZRAppStoreLocaleCache class])
          productsProvider:OCMProtocolMock(@protocol(BZRProductsProvider))
          metadataFetcher:OCMClassMock([BZRStoreKitMetadataFetcher class])
          currentApplicationBundleID:@"foo"];
}

@end

NS_ASSUME_NONNULL_END
