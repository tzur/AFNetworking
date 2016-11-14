// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsProviderFactory.h"

#import "BZRCachedProductsProvider.h"
#import "BZRLocalProductsProvider.h"
#import "BZRProductsWithPriceInfoProvider.h"
#import "BZRProductsWithVariantsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductsProviderFactory ()

/// \c productsListJSONFilePath is used to load products information with.
@property (readonly, nonatomic) LTPath *productsListJSONFilePath;

/// File manager used to read product list file.
@property (readonly, nonatomic) NSFileManager *fileManager;

@end

@implementation BZRProductsProviderFactory

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                                     fileManager:(NSFileManager *)fileManager {
  if (self = [super init]) {
    _productsListJSONFilePath = productsListJSONFilePath;
    _fileManager = fileManager;
  }
  return self;
}

- (id<BZRProductsProvider>)productsProviderWithStoreKitFacade:(BZRStoreKitFacade *)storeKitFacade {
  BZRLocalProductsProvider *localProductsProvider =
      [[BZRLocalProductsProvider alloc] initWithPath:self.productsListJSONFilePath
                                         fileManager:self.fileManager];
  BZRProductsWithVariantsProvider *productsWithVariantsProvider =
      [[BZRProductsWithVariantsProvider alloc] initWithUnderlyingProvider:localProductsProvider];
  BZRProductsWithPriceInfoProvider *productsWithPriceInfoProvider =
      [[BZRProductsWithPriceInfoProvider alloc]
       initWithUnderlyingProvider:productsWithVariantsProvider storeKitFacade:storeKitFacade];
  return [[BZRCachedProductsProvider alloc]
          initWithUnderlyingProvider:productsWithPriceInfoProvider];
}

@end

NS_ASSUME_NONNULL_END
