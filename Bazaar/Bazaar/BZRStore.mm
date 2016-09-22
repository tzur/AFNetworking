// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStore.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRProduct+SKProduct.h"
#import "BZRProductContentManager.h"
#import "BZRProductContentProvider.h"
#import "BZRProductPriceInfo+SKProduct.h"
#import "BZRProductPriceInfo.h"
#import "BZRProductsProvider.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRStoreConfiguration.h"
#import "BZRStoreKitFacade.h"
#import "BZRStoreKitFacadeFactory.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

/// Maps product identifiers to products.
typedef NSDictionary<NSString *, BZRProduct *> BZRProductDictionary;

@interface BZRStore ()

/// Provider used to provide the list of products.
@property (readonly, nonatomic) id<BZRProductsProvider> productsProvider;

/// Manager used to manage products content directory.
@property (readonly, nonatomic) BZRProductContentManager *contentManager;

/// Provider used to provide products' content.
@property (readonly, nonatomic) BZRProductContentProvider *contentProvider;

/// Provider used to provide the latest \c BZRReceiptValidationStatus.
@property (readonly, nonatomic) BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

/// Provider used to provide list of products that were acquired via subsription.
@property (readonly, nonatomic) BZRAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;

/// Bundle used to check whether the receipt URL exists.
@property (readonly, nonatomic) NSBundle *applicationReceiptBundle;

/// Manager used to check if the receipt file exists.
@property (readonly, nonatomic) NSFileManager *fileManager;

/// Facade used to interact with Apple StoreKit.
@property (readonly, nonatomic) BZRStoreKitFacade *storeKitFacade;

/// Subject used to send errors with.
@property (readonly, nonatomic) RACSubject *errorsSubject;

/// The other end of \c completedTransactionsSignal used to send completed transactions.
@property (readonly, nonatomic) RACSubject *completedTransactionsSubject;

/// Dictionary that maps fetched product identifier to \c BZRProduct.
@property (strong, nonatomic, nullable) NSDictionary<NSString *, BZRProduct *> *productDictionary;

/// Set of products with downloaded content.
@property (strong, nonatomic) NSSet<NSString *> *downloadedContentProducts;

@end

@implementation BZRStore

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithConfiguration:(BZRStoreConfiguration *)configuration {
  if (self = [super init]) {
    _productsProvider = configuration.productsProvider;
    _contentManager = configuration.contentManager;
    _contentProvider = configuration.contentProvider;
    _validationStatusProvider = configuration.validationStatusProvider;
    _acquiredViaSubscriptionProvider = configuration.acquiredViaSubscriptionProvider;
    _applicationReceiptBundle = configuration.applicationReceiptBundle;
    _fileManager = configuration.fileManager;

    [self initializeCompletedTransactionsSignal];
    [self initializeErrorsSignal];
    [self initializeStoreKitFacade:configuration.storeKitFacadeFactory];
    [self fetchProductDictionary];
  }
  return self;
}

- (void)initializeCompletedTransactionsSignal {
  _completedTransactionsSubject = [RACSubject subject];
  _completedTransactionsSignal = [[[self.completedTransactionsSubject replay]
      takeUntil:[self rac_willDeallocSignal]]
      setNameWithFormat:@"%@ -finishedTransactionsSignal", self];
}

- (void)initializeErrorsSignal {
  _errorsSubject = [RACSubject subject];
  _errorsSignal = [[[RACSignal merge:@[
    [self.errorsSubject replay],
    self.validationStatusProvider.nonCriticalErrorsSignal,
    self.acquiredViaSubscriptionProvider.storageErrorsSignal
  ]]
  takeUntil:[self rac_willDeallocSignal]]
  setNameWithFormat:@"%@ -errorsSignal", self];
}

- (void)initializeStoreKitFacade:(BZRStoreKitFacadeFactory *)factory {
  RACSubject *unfinishedTransactionsSubject = [RACSubject subject];
  @weakify(self);
  [[[unfinishedTransactionsSubject
      flattenMap:^RACStream *(NSArray<SKPaymentTransaction *> *transactions) {
        return [transactions.rac_sequence signalWithScheduler:[RACScheduler immediateScheduler]];
      }]
      filter:^BOOL(SKPaymentTransaction *transaction) {
        return transaction.transactionState == SKPaymentTransactionStateFailed;
      }]
      subscribeNext:^(SKPaymentTransaction *transaction) {
        @strongify(self);
        [self.errorsSubject sendNext:
         [NSError bzr_errorWithCode:BZRErrorCodePurchaseFailed transaction:transaction]];
      }];

  [[[unfinishedTransactionsSubject
      flattenMap:^RACStream *(NSArray<SKPaymentTransaction *> *transactions) {
        return [transactions.rac_sequence signalWithScheduler:[RACScheduler immediateScheduler]];
      }]
      filter:^BOOL(SKPaymentTransaction *transaction) {
        return transaction.transactionState == SKPaymentTransactionStatePurchased;
      }]
      subscribeNext:^(SKPaymentTransaction *transaction) {
        @strongify(self);
        [self.completedTransactionsSubject sendNext:transaction];
      }];

  [unfinishedTransactionsSubject
      subscribeNext:^(NSArray <SKPaymentTransaction *> *transactions) {
        @strongify(self);
        NSArray <SKPaymentTransaction *> *purchasedTransactions =
            [transactions lt_filter:^BOOL(SKPaymentTransaction *transaction) {
              return transaction.transactionState == SKPaymentTransactionStatePurchased;
            }];
        if ([purchasedTransactions count]) {
          [self.validationStatusProvider fetchReceiptValidationStatus];
        }
      }];

  [[[unfinishedTransactionsSubject
      flattenMap:^RACStream *(NSArray<SKPaymentTransaction *> *transactions) {
        return [transactions.rac_sequence signalWithScheduler:[RACScheduler immediateScheduler]];
      }]
      filter:^BOOL(SKPaymentTransaction *transaction) {
        return transaction.transactionState == SKPaymentTransactionStatePurchased ||
            transaction.transactionState == SKPaymentTransactionStateFailed ||
            transaction.transactionState == SKPaymentTransactionStateRestored;
      }]
      subscribeNext:^(SKPaymentTransaction *transaction) {
        @strongify(self);
        [self.storeKitFacade finishTransaction:transaction];
      }];

  _storeKitFacade =
      [factory storeKitFacadeWithUnfinishedTransactionsSubject:unfinishedTransactionsSubject];
}

- (void)fetchProductDictionary {
  @weakify(self);
  RACSignal *fetchProductDictionarySignal = [[[self.productsProvider fetchProductList]
      map:^BZRProductDictionary *(NSArray<BZRProduct *> *productList) {
        return [NSDictionary dictionaryWithObjects:productList
                forKeys:[productList valueForKey:@instanceKeypath(BZRProduct, identifier)]];
      }]
      flattenMap:^RACStream *(BZRProductDictionary *productDictionary) {
        @strongify(self);
        NSSet *productSet = [NSSet setWithArray:[productDictionary allKeys]];
        return [[self.storeKitFacade fetchMetadataForProductsWithIdentifiers:productSet]
            map:^BZRProductDictionary *(SKProductsResponse *productsResponse) {
              return [self productDictionary:productDictionary
                      withPriceInfoAndProductFromProductsResponse:productsResponse];
            }];
      }];
  [fetchProductDictionarySignal subscribeNext:^(BZRProductDictionary *productDictionary) {
    @strongify(self);
    self.productDictionary = productDictionary;
    self.downloadedContentProducts =
        [self downloadedContentProductsWithDictionary:productDictionary];
  } error:^(NSError *error) {
    @strongify(self);
    NSError *fetchProductListError =
        [NSError lt_errorWithCode:BZRErrorCodeFetchingProductListFailed underlyingError:error];
    [self.errorsSubject sendNext:fetchProductListError];
  }];
}

- (BZRProductDictionary *)productDictionary:(BZRProductDictionary *)productDictionary
withPriceInfoAndProductFromProductsResponse:(SKProductsResponse *)productsResponse {
  return [productsResponse.products lt_reduce:^NSMutableDictionary<NSString *, BZRProduct *> *
          (NSMutableDictionary<NSString *, BZRProduct *> *value, SKProduct *product) {
    BZRProduct *bazaarProduct = productDictionary[product.productIdentifier];
    BZRProductPriceInfo *priceInfo = [BZRProductPriceInfo productPriceInfoWithSKProduct:product];
    value[product.productIdentifier] = [[bazaarProduct
        modelByOverridingProperty:@instanceKeypath(BZRProduct, priceInfo) withValue:priceInfo]
        modelByOverridingProperty:@instanceKeypath(BZRProduct, bzr_underlyingProduct)
                        withValue:product];
    return value;
  } initial:[@{} mutableCopy]];
}

- (NSSet<NSString *> *)downloadedContentProductsWithDictionary:
    (BZRProductDictionary *)productDictionary {
  return [NSSet setWithArray:[[productDictionary.allValues lt_filter:^BOOL(BZRProduct *product) {
    return !product.contentFetcherParameters ||
    [self pathToContentOfProduct:product.identifier];
  }] valueForKey:@instanceKeypath(BZRProduct, identifier)]];
}

#pragma mark -
#pragma mark BZRProductsInfoProvider
#pragma mark -

- (nullable LTPath *)pathToContentOfProduct:(NSString *)productIdentifier {
  return [self.contentManager pathToContentDirectoryOfProduct:productIdentifier];
}

- (NSSet<NSString *> *)purchasedProducts {
  NSArray<BZRReceiptInAppPurchaseInfo *> *inAppPurchases =
      self.validationStatusProvider.receiptValidationStatus.receipt.inAppPurchases;
  if (!inAppPurchases) {
    return [NSSet set];
  }
  return [NSSet setWithArray:
          [inAppPurchases valueForKey:@instanceKeypath(BZRReceiptInAppPurchaseInfo, productId)]];
}

- (NSSet<NSString *> *)acquiredViaSubscriptionProducts {
  return self.acquiredViaSubscriptionProvider.productsAcquiredViaSubscription;
}

- (NSSet<NSString *> *)acquiredProducts {
  return [self.purchasedProducts
          setByAddingObjectsFromSet:self.acquiredViaSubscriptionProducts];
}

- (NSSet<NSString *> *)allowedProducts {
  return [self isUserSubscribed] ? self.acquiredProducts : self.purchasedProducts;
}

- (nullable BZRReceiptSubscriptionInfo *)subscriptionInfo {
  return self.validationStatusProvider.receiptValidationStatus.receipt.subscription;
}

#pragma mark -
#pragma mark BZRProductsManager
#pragma mark -

- (RACSignal *)purchaseProduct:(NSString *)productIdentifier {
  @weakify(self);
  return [[[[self isProductClearedForSale:productIdentifier]
      tryMap:^id(NSNumber *isClearedForSale, NSError **error) {
        if (![isClearedForSale boolValue]) {
          if(error) {
            *error = [NSError lt_errorWithCode:BZRErrorCodeInvalidProductIdentifer];
          }
          return nil;
        }
        return isClearedForSale;
      }]
      then:^RACSignal *{
        @strongify(self);
        if ([self isUserSubscribed]) {
          [self.acquiredViaSubscriptionProvider
           addAcquiredViaSubscriptionProduct:productIdentifier];
          return [RACSignal empty];
        }
        return [self purchaseProductWithStoreKit:productIdentifier];
      }]
      setNameWithFormat:@"%@ -purchaseProduct", self];
}

- (RACSignal *)isProductClearedForSale:(NSString *)productIdentifier {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    return [RACSignal return:(self.productDictionary[productIdentifier] ? @YES : @NO)];
  }];
}

- (BOOL)isUserSubscribed {
  return [self subscriptionInfo] && ![self subscriptionInfo].isExpired;
}

- (RACSignal *)purchaseProductWithStoreKit:(NSString *)productIdentifier {
  SKProduct *product = self.productDictionary[productIdentifier].bzr_underlyingProduct;
  @weakify(self);
  return [[[[[self.storeKitFacade purchaseProduct:product]
      filter:^BOOL(SKPaymentTransaction *transaction) {
        return transaction.transactionState == SKPaymentTransactionStatePurchased;
      }]
      doNext:^(SKPaymentTransaction *transaction) {
        @strongify(self);
        [self.storeKitFacade finishTransaction:transaction];
      }]
      doError:^(NSError *error) {
        @strongify(self);
        [self.storeKitFacade finishTransaction:error.bzr_transaction];
      }]
      then:^RACSignal *{
        @strongify(self);
        return [[self.validationStatusProvider fetchReceiptValidationStatus] ignoreValues];
      }];
}

- (RACSignal *)fetchProductContent:(NSString *)productIdentifier {
  @weakify(self);
  return [[[self.contentProvider fetchProductContent:self.productDictionary[productIdentifier]]
      doCompleted:^ {
        @strongify(self);
        self.downloadedContentProducts =
            [self.downloadedContentProducts setByAddingObject:productIdentifier];
      }]
      setNameWithFormat:@"%@ -fetchProductContent", self];
}

- (RACSignal *)deleteProductContent:(NSString *)productIdentifier {
  @weakify(self);
  return [[[self.contentManager deleteContentDirectoryOfProduct:productIdentifier]
      doCompleted:^ {
        @strongify(self);
        NSMutableSet *mutableDownloadedContentProducts =
            [self.downloadedContentProducts mutableCopy];
        [mutableDownloadedContentProducts removeObject:productIdentifier];
        self.downloadedContentProducts = [mutableDownloadedContentProducts copy];
      }]
      setNameWithFormat:@"%@ -deleteProductContent", self];
}

- (RACSignal *)refreshReceipt {
  @weakify(self);
  return [[[RACSignal defer:^RACSignal *{
    @strongify(self);
    RACSignal *refreshReceipt = [[self.storeKitFacade restoreCompletedTransactions]
        concat:[self.validationStatusProvider fetchReceiptValidationStatus]];
    return ([self isReceiptAvailable] ? refreshReceipt :
            [[self.storeKitFacade refreshReceipt] concat:refreshReceipt]);
  }]
  ignoreValues]
  setNameWithFormat:@"%@ -refreshReceipt", self];
}

- (BOOL)isReceiptAvailable {
  NSURL *receiptURL = [self.applicationReceiptBundle appStoreReceiptURL];
  return receiptURL && [self.fileManager fileExistsAtPath:receiptURL.path];
}

- (RACSignal *)productList {
  RACSignal *fetchProductListErrorsSignal = [[self.errorsSignal filter:^BOOL(NSError *error) {
    return error.code == BZRErrorCodeFetchingProductListFailed;
  }]
  flattenMap:^RACStream *(NSError *error) {
    return [RACSignal error:error];
  }];
  RACSignal *productListSignal = [[RACObserve(self, productDictionary)
      ignore:nil]
      map:^NSSet<BZRProduct *> *(BZRProductDictionary *productDictionary) {
        return [NSSet setWithArray:[productDictionary allValues]];
      }];

  return [[[RACSignal merge:@[productListSignal, fetchProductListErrorsSignal]]
      take:1]
      setNameWithFormat:@"%@ -productList", self];
}

#pragma mark -
#pragma mark KVO-Compliance.
#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingPurchasedProducts {
  return [NSSet setWithObject:
          @instanceKeypath(BZRCachedReceiptValidationStatusProvider, receiptValidationStatus)];
}

+ (NSSet *)keyPathsForValuesAffectingAcquiredViaSubscriptionProducts {
  return [NSSet setWithObject:
          @instanceKeypath(BZRAcquiredViaSubscriptionProvider, productsAcquiredViaSubscription)];
}

+ (NSSet *)keyPathsForValuesAffectingAcquiredProducts {
  return [NSSet setWithObjects:
    @instanceKeypath(BZRCachedReceiptValidationStatusProvider, receiptValidationStatus),
    @instanceKeypath(BZRAcquiredViaSubscriptionProvider, productsAcquiredViaSubscription),
    nil
  ];
}

+ (NSSet *)keyPathsForValuesAffectingAllowedProducts {
  return [NSSet setWithObjects:
    @instanceKeypath(BZRCachedReceiptValidationStatusProvider, receiptValidationStatus),
    @instanceKeypath(BZRAcquiredViaSubscriptionProvider, productsAcquiredViaSubscription),
    nil
  ];
}

+ (NSSet *)keyPathsForValuesAffectingSubscriptionInfo {
  return [NSSet setWithObject:
          @instanceKeypath(BZRCachedReceiptValidationStatusProvider, receiptValidationStatus)];
}

@end

NS_ASSUME_NONNULL_END
