// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStore.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRPeriodicReceiptValidatorActivator.h"
#import "BZRProduct+SKProduct.h"
#import "BZRProductContentManager.h"
#import "BZRProductContentProvider.h"
#import "BZRProductDictionary.h"
#import "BZRProductPriceInfo+SKProduct.h"
#import "BZRProductPriceInfo.h"
#import "BZRProductsProvider.h"
#import "BZRProductsVariantSelector.h"
#import "BZRProductsVariantSelectorFactory.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRStoreConfiguration.h"
#import "BZRStoreKitFacade.h"
#import "BZRStoreKitFacadeFactory.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSString+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

/// Collection of \c BZRProducts.
typedef NSArray<BZRProduct *> BZRProductList;

/// Collection of classified \c BZRProduct.
typedef NSDictionary<id, BZRProductList *> BZRClassifiedProducts;

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

/// Activator used to control the periodic validation.
@property (readonly, nonatomic) BZRPeriodicReceiptValidatorActivator *periodicValidatorActivator;

/// Facade used to interact with Apple StoreKit.
@property (readonly, nonatomic) BZRStoreKitFacade *storeKitFacade;

/// Factory used to create \c BZRLocaleProductsvariantSelector.
@property (readonly, nonatomic) id<BZRProductsVariantSelectorFactory> variantSelectorFactory;

/// Selector used to select the active variant for each product. The selector is initialized with
/// \c BZRProductsVariantSelector. When the list of products is fetched successfully,
/// \c variantSelectorFactory is called which returns a new \c BZRProductsVariantSelector. If the
/// selector was created successfully, \c variantSelector is set to that selector.
@property (strong, atomic) id<BZRProductsVariantSelector> variantSelector;

/// Provider used to provide validation parameters sent to validatricks.
@property (readonly, nonatomic) id<BZRReceiptValidationParametersProvider>
    validationParametersProvider;

/// Subject used to send errors with.
@property (readonly, nonatomic) RACSubject *errorsSubject;

/// The other end of \c completedTransactionsSignal used to send completed transactions.
@property (readonly, nonatomic) RACSubject *completedTransactionsSubject;

/// Dictionary that maps fetched product identifier to \c BZRProduct.
@property (strong, atomic, nullable) NSDictionary<NSString *, BZRProduct *> *productDictionary;

/// Flag indicating whether product dictionary fetch is currently in progress or not.
@property (atomic) BOOL productDictionaryFetchInProgress;

/// Set of products with downloaded content.
@property (strong, nonatomic) NSSet<NSString *> *downloadedContentProducts;

@end

@implementation BZRStore

@synthesize productDictionary = _productDictionary;
@synthesize productDictionaryFetchInProgress = _productDictionaryFetchInProgress;
@synthesize completedTransactionsSignal = _completedTransactionsSignal;

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
    _periodicValidatorActivator = configuration.periodicValidatorActivator;
    _variantSelectorFactory = configuration.variantSelectorFactory;
    _variantSelector = [[BZRProductsVariantSelector alloc] init];
    _validationParametersProvider = configuration.validationParametersProvider;

    [self initializeCompletedTransactionsSignal];
    [self initializeErrorsSignal];
    [self initializeStoreKitFacade:configuration.storeKitFacadeFactory];
    [self prefetchProductDictionary];
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
  _errorsSignal = [RACSignal merge:@[
    [self.errorsSubject replay],
    self.validationStatusProvider.nonCriticalErrorsSignal,
    self.acquiredViaSubscriptionProvider.storageErrorsSignal,
    self.periodicValidatorActivator.errorsSignal
  ]];
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
  _errorsSignal = [[[RACSignal merge:@[
    self.errorsSignal,
    self.storeKitFacade.unhandledTransactionsErrorsSignal
  ]]
  takeUntil:[self rac_willDeallocSignal]]
  setNameWithFormat:@"%@ -errorsSignal", self];
}

- (void)prefetchProductDictionary {
  @weakify(self);
  [[[self fetchProductDictionary]
      takeUntil:[self rac_willDeallocSignal]]
      subscribeNext:^(BZRProductDictionary * _Nullable productDictionary) {
        @strongify(self);
        self.productDictionary = productDictionary;
        [self createVariantSelectorWithProductDictionary:productDictionary];
      } error:^(NSError *underlyingError) {
        @strongify(self);
        NSError *error = [NSError lt_errorWithCode:BZRErrorCodeFetchingProductListFailed
                                   underlyingError:underlyingError];
        [self.errorsSubject sendNext:error];
      }];
}

- (nullable BZRProductDictionary *)productDictionary {
  @synchronized(self) {
    return _productDictionary;
  }
}

- (void)setProductDictionary:(nullable NSDictionary<NSString *,BZRProduct *> *)productDictionary {
  @synchronized(self) {
    _productDictionary = productDictionary;

    self.downloadedContentProducts =
        [NSSet setWithArray:[[productDictionary.allValues lt_filter:^BOOL(BZRProduct *product) {
          return !product.contentFetcherParameters ||
              [self pathToContentOfProduct:product.identifier];
        }] valueForKey:@instanceKeypath(BZRProduct, identifier)]];
  }
}

- (void)createVariantSelectorWithProductDictionary:(BZRProductDictionary *)productDictionary {
  NSError *error;
  id<BZRProductsVariantSelector> selector = [self.variantSelectorFactory
      productsVariantSelectorWithProductDictionary:productDictionary error:&error];
  if (error) {
    [self.errorsSubject sendNext:error];
  } else {
    self.variantSelector = selector;
  }
}

#pragma mark -
#pragma mark Fetching Product List
#pragma mark -

- (RACSignal *)fetchProductDictionary {
  @weakify(self);
  return [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    self.productDictionaryFetchInProgress = YES;
    return [[self fetchProductDictionaryInternal] subscribe:subscriber];
  }] doError:^(NSError *) {
    @strongify(self);
    self.productDictionaryFetchInProgress = NO;
  }] doCompleted:^{
    @strongify(self);
    self.productDictionaryFetchInProgress = NO;
  }];
}

/// Label used to mark AppStore products in a \c BZRClassifiedProducts.
static NSNumber * const kAppStoreProductsLabel = @1;

/// Label used to mark non AppStore products in a \c BZRClassifiedProducts.
static NSNumber * const kNonAppStoreProductsLabel = @0;

- (RACSignal *)fetchProductDictionaryInternal {
  @weakify(self);
  return [[[self.productsProvider fetchProductList]
      map:^BZRClassifiedProducts *(BZRProductList *productList) {
        return [productList lt_classify:^NSNumber *(BZRProduct * product) {
              return product.isSubscribersOnly ? kNonAppStoreProductsLabel : kAppStoreProductsLabel;
            }];
      }]
      flattenMap:^RACStream *(BZRClassifiedProducts *classifiedProducts) {
        @strongify(self);
        if (!self) {
          return [RACSignal empty];
        }

        RACSignal *appStoreProductsMapper =
            [self appStoreProductsDictionary:classifiedProducts[kAppStoreProductsLabel]];
        RACSignal *nonAppStoreProductsMapper =
            [self nonAppStoreProductsDictionary:classifiedProducts[kNonAppStoreProductsLabel]];
        return [[RACSignal
            zip:@[appStoreProductsMapper, nonAppStoreProductsMapper]]
            map:^BZRProductDictionary *(RACTuple *productDictionaries) {
              return [self mergeProductDictionaries:productDictionaries.allObjects];
            }];
      }];
}

- (BOOL)productDictionaryFetchInProgress {
  @synchronized(self) {
    return _productDictionaryFetchInProgress;
  }
}

- (void)setProductDictionaryFetchInProgress:(BOOL)productDictionaryFetchInProgress {
  @synchronized(self) {
    _productDictionaryFetchInProgress = productDictionaryFetchInProgress;
  }
}

- (RACSignal *)appStoreProductsDictionary:(BZRProductList *)products {
  // If the given product list is empty avoid StoreKit overhead and return a signal that delivers an
  // empty dictionary. Returning an empty signal is not good cause the returned signal is zipped
  // with another signal and we don't want to lose the values from the other signal.
  if (!products.count) {
    return [RACSignal return:@{}];
  }
  
  NSArray<NSString *> *identifiers =
      [products valueForKey:@instanceKeypath(BZRProduct, identifier)];
  @weakify(self);
  return [[[[self.storeKitFacade
      fetchMetadataForProductsWithIdentifiers:[NSSet setWithArray:identifiers]]
      doNext:^(SKProductsResponse *response) {
        @strongify(self);
        if (response.invalidProductIdentifiers.count) {
          NSSet<NSString *> *productIdentifiers =
              [NSSet setWithArray:response.invalidProductIdentifiers];
          NSError *error = [NSError bzr_invalidProductsErrorWithIdentifers:productIdentifiers];
          [self.errorsSubject sendNext:error];
        }
      }]
      doNext:^(SKProductsResponse *response) {
        self.validationParametersProvider.appStoreLocale =
            response.products.firstObject.priceLocale;
      }]
      map:^BZRProductDictionary *(SKProductsResponse *response) {
        @strongify(self);
        if (![response.products count]) {
          return @{};
        }

        BZRProductDictionary *productDictionary = [NSDictionary dictionaryWithObjects:products
                                                                              forKeys:identifiers];
        return [self productDictionary:productDictionary withMetadataFromProductsResponse:response];
      }];
}

- (BZRProductDictionary *)productDictionary:(BZRProductDictionary *)productDictionary
           withMetadataFromProductsResponse:(SKProductsResponse *)productsResponse {
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

- (RACSignal *)nonAppStoreProductsDictionary:(BZRProductList *)products {
  NSArray<NSString *> *identifiers =
      [products valueForKey:@instanceKeypath(BZRProduct, identifier)];
  return [RACSignal return:[NSDictionary dictionaryWithObjects:products forKeys:identifiers]];
}

- (BZRProductDictionary *)mergeProductDictionaries:(NSArray<BZRProductDictionary *> *)dictionaries {
  return [dictionaries
      lt_reduce:^BZRProductDictionary *(BZRProductDictionary *mergedDictionary,
                                        BZRProductDictionary *dictionary) {
        return [mergedDictionary mtl_dictionaryByAddingEntriesFromDictionary:dictionary];
      } initial:@{}];
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
  NSArray<NSString *> *baseProductsIdentifiers =
      [[inAppPurchases valueForKey:@instanceKeypath(BZRReceiptInAppPurchaseInfo, productId)]
       lt_map:^NSString *(NSString *identifier) {
         return [self baseProductForProductWithIdentifier:identifier];
       }];
  return [NSSet setWithArray:baseProductsIdentifiers];
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

- (nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  return self.validationStatusProvider.receiptValidationStatus;
}

#pragma mark -
#pragma mark BZRProductsManager
#pragma mark -

- (RACSignal *)purchaseProduct:(NSString *)productIdentifier {
  NSString *variantIdentifier =
      [self.variantSelector selectedVariantForProductWithIdentifier:productIdentifier];

  @weakify(self);
  return [[[[self isProductClearedForSale:variantIdentifier]
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
        if ([self isUserSubscribed] && ![self isSubscriptionProduct:variantIdentifier]) {
          // Since there is no need to connect to StoreKit for a product that is bought/purchased by
          // a subscriber, we don't save the variant but the base product's identifier.
          [self.acquiredViaSubscriptionProvider
           addAcquiredViaSubscriptionProduct:productIdentifier];
          return [RACSignal empty];
        }
        return [self purchaseProductWithStoreKit:variantIdentifier];
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

- (BOOL)isSubscriptionProduct:(NSString *)productIdentifier {
  BZRProductType *productType = self.productDictionary[productIdentifier].productType;
  return [productType isEqual:$(BZRProductTypeRenewableSubscription)] ||
      [productType isEqual:$(BZRProductTypeNonRenewingSubscription)];
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
  return [[RACSignal defer:^RACSignal *{
    @strongify(self);
    return [self isReceiptAvailable] ? [self restoreCompletedTransactions] :
            [[self.storeKitFacade refreshReceipt] concat:[self restoreCompletedTransactions]];
  }]
  setNameWithFormat:@"%@ -refreshReceipt", self];
}

- (BOOL)isReceiptAvailable {
  NSURL *receiptURL = [self.applicationReceiptBundle appStoreReceiptURL];
  return receiptURL && [self.fileManager fileExistsAtPath:receiptURL.path];
}

- (RACSignal *)restoreCompletedTransactions {
  @weakify(self);
  return [[[[self.storeKitFacade restoreCompletedTransactions]
      doNext:^(SKPaymentTransaction *transaction) {
        @strongify(self);
        [self.storeKitFacade finishTransaction:transaction];
      }]
      concat:[self.validationStatusProvider fetchReceiptValidationStatus]]
      ignoreValues];
}

- (RACSignal *)productList {
  @weakify(self);
  return [[[[RACObserve(self, productDictionaryFetchInProgress)
      ignore:@YES]
      take:1]
      flattenMap:^RACStream *(NSNumber *) {
        @strongify(self);
        return self.productDictionary ? [RACSignal return:self.productDictionary] :
            [self refetchProductListSignal];
      }]
      map:^NSSet<BZRProduct *> *(BZRProductDictionary *productDictionary) {
        @strongify(self);
        NSArray<BZRProduct *> *variantsWithBaseIdentifers =
            [[productDictionary.allValues lt_filter:^BOOL(BZRProduct *product) {
              @strongify(self);
              NSString *baseProductIdentifier =
                  [self baseProductForProductWithIdentifier:product.identifier];
              return [product.identifier isEqualToString:baseProductIdentifier];
            }]
            lt_map:^BZRProduct *(BZRProduct *product) {
              @strongify(self);
              NSString *variantIdentifier =
                  [self.variantSelector selectedVariantForProductWithIdentifier:product.identifier];
              BZRProduct *variant = productDictionary[variantIdentifier];
              return [variant modelByOverridingProperty:@keypath(variant, identifier)
                                              withValue:product.identifier];
        }];
        return [NSSet setWithArray:variantsWithBaseIdentifers];
      }];
}

- (NSString *)baseProductForProductWithIdentifier:(NSString *)productIdentifier {
  NSString *baseIdentifier = [productIdentifier bzr_baseProductIdentifier];
  LTAssert(!self.productDictionary[productIdentifier] || self.productDictionary[baseIdentifier],
           @"Got a request for base product that does not exist. This is probably a typo in the "
           "base or the variant identifiers. The base identifier is: %@. The variant identifier "
           "is: %@.", baseIdentifier, productIdentifier);
  return baseIdentifier;
}

- (RACSignal *)refetchProductListSignal {
  @weakify(self);
  return [[[self fetchProductDictionary]
      doNext:^(BZRProductDictionary *productDictionary) {
        @strongify(self);
        self.productDictionary = productDictionary;
        [self createVariantSelectorWithProductDictionary:productDictionary];
      }]
      doError:^(NSError *underlyingError) {
        @strongify(self);
        NSError *error = [NSError lt_errorWithCode:BZRErrorCodeFetchingProductListFailed
                                   underlyingError:underlyingError];
        [self.errorsSubject sendNext:error];
      }];
}

#pragma mark -
#pragma mark KVO-Compliance.
#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingPurchasedProducts {
  return [NSSet setWithObject:
      @instanceKeypath(BZRStore, validationStatusProvider.receiptValidationStatus)];
}

+ (NSSet *)keyPathsForValuesAffectingAcquiredViaSubscriptionProducts {
  return [NSSet setWithObject:
      @instanceKeypath(BZRStore, acquiredViaSubscriptionProvider.productsAcquiredViaSubscription)];
}

+ (NSSet *)keyPathsForValuesAffectingAcquiredProducts {
  return [NSSet setWithObjects:
      @instanceKeypath(BZRStore, validationStatusProvider.receiptValidationStatus),
      @instanceKeypath(BZRStore, acquiredViaSubscriptionProvider.productsAcquiredViaSubscription),
      nil];
}

+ (NSSet *)keyPathsForValuesAffectingAllowedProducts {
  return [NSSet setWithObjects:
      @instanceKeypath(BZRStore, validationStatusProvider.receiptValidationStatus),
      @instanceKeypath(BZRStore, acquiredViaSubscriptionProvider.productsAcquiredViaSubscription),
      nil];
}

+ (NSSet *)keyPathsForValuesAffectingSubscriptionInfo {
  return [NSSet setWithObject:
      @instanceKeypath(BZRStore, validationStatusProvider.receiptValidationStatus)];
}

+ (NSSet *)keyPathsForValuesAffectingReceiptValidationStatus {
  return [NSSet setWithObject:
      @instanceKeypath(BZRStore, validationStatusProvider.receiptValidationStatus)];
}

@end

NS_ASSUME_NONNULL_END
