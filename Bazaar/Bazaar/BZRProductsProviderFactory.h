// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRStoreKitFacade;

@protocol BZRProductsProvider;

/// Factory used to create \c BZRProductsProvider objects.
@interface BZRProductsProviderFactory : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c productsListJSONFilePath is used to load products information with, and with
/// \c fileManager, used to read product list file.
- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                                     fileManager:(NSFileManager *)fileManager;

/// Creates a new instance of a concrete class implementing \c BZRProductsProvider with the given
/// \c storeKitFacade.
- (id<BZRProductsProvider>)productsProviderWithStoreKitFacade:(BZRStoreKitFacade *)storeKitFacade;

@end

NS_ASSUME_NONNULL_END
