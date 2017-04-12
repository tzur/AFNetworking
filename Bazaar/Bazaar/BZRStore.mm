// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStore.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRAllowedProductsProvider.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZREvent.h"
#import "BZRExternalTriggerReceiptValidator.h"
#import "BZRPeriodicReceiptValidatorActivator.h"
#import "BZRProduct+SKProduct.h"
#import "BZRProductContentManager.h"
#import "BZRProductContentProvider.h"
#import "BZRProductPriceInfo+SKProduct.h"
#import "BZRProductsProvider.h"
#import "BZRProductsVariantSelector.h"
#import "BZRProductsVariantSelectorFactory.h"
#import "BZRProductTypedefs.h"
#import "BZRReceiptModel+ProductPurchased.h"
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRStoreConfiguration.h"
#import "BZRStoreKitFacade.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSString+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

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

/// Activator used to control the periodic validation.
@property (readonly, nonatomic) BZRPeriodicReceiptValidatorActivator *periodicValidatorActivator;

/// Facade used to interact with Apple StoreKit.
@property (readonly, nonatomic) BZRStoreKitFacade *storeKitFacade;

/// Validator used to validate receipt on initialization if required.
@property (readonly, nonatomic) BZRExternalTriggerReceiptValidator *startupReceiptValidator;

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

/// Provider used to provide products the user is allowed to use.
@property (readonly, nonatomic) BZRAllowedProductsProvider *allowedProductsProvider;

/// Subject used to send events with.
@property (readonly, nonatomic) RACSubject *eventsSubject;

/// Dictionary that maps fetched product identifier to \c BZRProduct.
@property (strong, atomic, nullable) NSDictionary<NSString *, BZRProduct *> *productDictionary;

/// Set of products with downloaded content.
@property (strong, readwrite, nonatomic) NSSet<NSString *> *downloadedContentProducts;

@end

@implementation BZRStore

@synthesize downloadedContentProducts = _downloadedContentProducts;
@synthesize productDictionary = _productDictionary;
@synthesize eventsSignal = _eventsSignal;

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
    _periodicValidatorActivator = configuration.periodicValidatorActivator;
    _storeKitFacade = configuration.storeKitFacade;
    _variantSelectorFactory = configuration.variantSelectorFactory;
    _variantSelector = [[BZRProductsVariantSelector alloc] init];
    _validationParametersProvider = configuration.validationParametersProvider;
    _allowedProductsProvider = configuration.allowedProductsProvider;
    _downloadedContentProducts = [NSSet set];
    _startupReceiptValidator = [[BZRExternalTriggerReceiptValidator alloc]
                                initWithValidationStatusProvider:self.validationStatusProvider];

    [self initializeEventsSignal];
    [self finishUnfinishedTransactions];
    [self activateStartupValidation];
    [self prefetchProductDictionary];
  }
  return self;
}

- (void)initializeEventsSignal {
  _eventsSubject = [RACSubject subject];

  _eventsSignal = [[[RACSignal merge:@[
    [self.eventsSubject replay],
    self.validationStatusProvider.eventsSignal,
    self.acquiredViaSubscriptionProvider.storageErrorEventsSignal,
    self.periodicValidatorActivator.errorEventsSignal,
    self.storeKitFacade.transactionsErrorEventsSignal,
    self.productsProvider.eventsSignal,
    [self.startupReceiptValidator.eventsSignal replay]
  ]]
  takeUntil:[self rac_willDeallocSignal]]
  setNameWithFormat:@"%@ -eventsSignal", self];
}

- (void)finishUnfinishedTransactions {
  @weakify(self);
  [[self.storeKitFacade.unfinishedSuccessfulTransactionsSignal
      flattenMap:^RACStream *(NSArray<SKPaymentTransaction *> *transactions) {
        return [transactions.rac_sequence signalWithScheduler:[RACScheduler immediateScheduler]];
      }]
      subscribeNext:^(SKPaymentTransaction *transaction) {
        @strongify(self);
        [self.storeKitFacade finishTransaction:transaction];
      }];
}

- (void)activateStartupValidation {
  RACSignal *triggerSignal = [self.storeKitFacade.unfinishedSuccessfulTransactionsSignal
      deliverOn:[RACScheduler scheduler]];
  if (!self.receiptValidationStatus) {
    triggerSignal = [triggerSignal startWith:[RACUnit defaultUnit]];
  }
  [self.startupReceiptValidator activateWithTrigger:triggerSignal];
}

- (void)prefetchProductDictionary {
  @weakify(self);
  [[[self fetchProductDictionary]
      takeUntil:[self rac_willDeallocSignal]]
      subscribeNext:^(BZRProductDictionary * _Nullable productDictionary) {
        @strongify(self);
        self.productDictionary = productDictionary;
      } error:^(NSError *underlyingError) {
        @strongify(self);
        NSError *error = [NSError lt_errorWithCode:BZRErrorCodeFetchingProductListFailed
                                   underlyingError:underlyingError];
        [self sendErrorEventOfType:$(BZREventTypeCriticalError) error:error];
      }];
}

- (RACSignal *)fetchProductDictionary {
  return [[self.productsProvider fetchProductList]
      map:^BZRProductDictionary *(BZRProductList *products) {
        NSArray<NSString *> *identifiers =
            [products valueForKey:@instanceKeypath(BZRProduct, identifier)];
        return [NSDictionary dictionaryWithObjects:products forKeys:identifiers];
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
    [self updateAppStoreLocaleFromProductDictionary:productDictionary];
    [self createVariantSelectorWithProductDictionary:productDictionary];
    [self addPreAcquiredProductsToAcquiredViaSubscription:productDictionary];
  }
}

- (void)updateAppStoreLocaleFromProductDictionary:(BZRProductDictionary *)productDictionary {
  BZRProductList *productsWithPriceInfo =
      [[productDictionary allValues] lt_filter:^BOOL(BZRProduct *product) {
        return product.bzr_underlyingProduct != nil;
      }];
  self.validationParametersProvider.appStoreLocale =
      productsWithPriceInfo.firstObject.bzr_underlyingProduct.priceLocale;
}

- (void)createVariantSelectorWithProductDictionary:(BZRProductDictionary *)productDictionary {
  NSError *error;
  id<BZRProductsVariantSelector> selector = [self.variantSelectorFactory
      productsVariantSelectorWithProductDictionary:productDictionary error:&error];
  if (error) {
    [self sendErrorEventOfType:$(BZREventTypeNonCriticalError) error:error];
  } else {
    self.variantSelector = selector;
  }
}

- (void)addPreAcquiredProductsToAcquiredViaSubscription:(BZRProductDictionary *)productDictionary {
  BZRProductList *preAcquiredViaSubscriptionProducts = [[productDictionary allValues]
      lt_filter:^BOOL(BZRProduct *product) {
        return product.preAcquiredViaSubscription;
      }];
  for (BZRProduct *product in preAcquiredViaSubscriptionProducts) {
    [self.acquiredViaSubscriptionProvider addAcquiredViaSubscriptionProduct:product.identifier];
  }
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
  return [[self preAcquiredProducts] setByAddingObjectsFromSet:
          self.allowedProductsProvider.allowedProducts];
}

- (NSSet<NSString *> *)preAcquiredProducts {
  NSArray <BZRProduct *> *preAcquriedProducts = [[self.productDictionary.allValues
    lt_filter:^BOOL(BZRProduct *product) {
      return product.preAcquired;
    }]
    lt_map:^NSString *(BZRProduct *product) {
      return product.identifier;
    }];

  return [NSSet setWithArray:preAcquriedProducts];
}

- (NSSet<NSString *> *)downloadedContentProducts {
  @synchronized (self) {
    return _downloadedContentProducts;
  }
}

- (void)setDownloadedContentProducts:(NSSet<NSString *> *)downloadedContentProducts {
  @synchronized (self) {
    _downloadedContentProducts = downloadedContentProducts;
  }
}

- (nullable BZRReceiptSubscriptionInfo *)subscriptionInfo {
  return self.validationStatusProvider.receiptValidationStatus.receipt.subscription;
}

- (nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  return self.validationStatusProvider.receiptValidationStatus;
}

- (nullable NSLocale *)appStoreLocale {
  return self.validationParametersProvider.appStoreLocale;
}

#pragma mark -
#pragma mark BZRProductsManager
#pragma mark -

- (RACSignal *)purchaseProduct:(NSString *)productIdentifier {
  NSString *variantIdentifier =
      [self.variantSelector selectedVariantForProductWithIdentifier:productIdentifier];

  @weakify(self);
  return [[[[[self isProductClearedForSale:variantIdentifier]
      tryMap:^id(NSNumber *isClearedForSale, NSError **error) {
        if (![isClearedForSale boolValue]) {
          if(error) {
            *error = [NSError lt_errorWithCode:BZRErrorCodeInvalidProductIdentifer];
          }
          return nil;
        }
        return isClearedForSale;
      }]
      doError:^(NSError *error) {
        @strongify(self);
        [self sendErrorEventOfType:$(BZREventTypeNonCriticalError) error:error];
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
  return [[[[[[self.storeKitFacade purchaseProduct:product]
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
        [self sendErrorEventOfType:$(BZREventTypeNonCriticalError) error:error];
      }]
      then:^RACSignal *{
        @strongify(self);
        return [[self.validationStatusProvider fetchReceiptValidationStatus]
            doError:^(NSError *error) {
              @strongify(self);
              [self sendErrorEventOfType:$(BZREventTypeCriticalError) error:error];
            }];
      }]
      flattenMap:^RACSignal *(BZRReceiptValidationStatus *receiptValidationStatus) {
        @strongify(self);
        BZRReceiptInfo *receipt = receiptValidationStatus.receipt;
        if (![receipt wasProductPurchased:productIdentifier] &&
            ![receipt.subscription.productId isEqualToString:productIdentifier]) {
          return [self handlePurchasedProductNotFoundInReceipt:productIdentifier];
        }

        return [RACSignal empty];
      }];
}

- (RACSignal *)handlePurchasedProductNotFoundInReceipt:(NSString *)productIdentifier {
  NSError *error = [NSError bzr_purchasedProductNotFoundInReceipt:productIdentifier];
  [self sendErrorEventOfType:$(BZREventTypeCriticalError) error:error];

  RACSignal *fetchReceiptSignal = [self.validationStatusProvider fetchReceiptValidationStatus];
  return [[[self.storeKitFacade refreshReceipt]
      concat:fetchReceiptSignal]
      ignoreValues];
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
    return [[self.storeKitFacade refreshReceipt] concat:[self restoreCompletedTransactions]];
  }]
  doError:^(NSError *error) {
    [self sendErrorEventOfType:$(BZREventTypeNonCriticalError) error:error];
  }]
  setNameWithFormat:@"%@ -refreshReceipt", self];
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
  RACSignal *productDictionarySignal = self.productDictionary ?
      [RACSignal return:self.productDictionary] : [self refetchProductDictionarySignal];
  return [productDictionarySignal
      map:^NSSet<BZRProduct *> *(BZRProductDictionary *productDictionary) {
        @strongify(self);
        return [self variantsWithBaseIdentifiers:productDictionary];
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

- (RACSignal *)refetchProductDictionarySignal {
  @weakify(self);
  return [[[self fetchProductDictionary]
      doNext:^(BZRProductDictionary *productDictionary) {
        @strongify(self);
        self.productDictionary = productDictionary;
      }]
      doError:^(NSError *underlyingError) {
        @strongify(self);
        NSError *error = [NSError lt_errorWithCode:BZRErrorCodeFetchingProductListFailed
                                   underlyingError:underlyingError];
        [self sendErrorEventOfType:$(BZREventTypeCriticalError) error:error];
      }];
}

/// Returns a set of products that are the chosen variants according to \c self.variantSelector.
/// Since this set is sent outside of this class, each variant's identifier is modified to be its
/// corresponding base product's identifier.
- (NSSet<BZRProduct *> *)variantsWithBaseIdentifiers:(BZRProductDictionary *)productDictionary {
  BZRProductList *variantsWithBaseIdentifers =
      [[productDictionary.allValues lt_filter:^BOOL(BZRProduct *product) {
        NSString *baseProductIdentifier =
            [self baseProductForProductWithIdentifier:product.identifier];
        return [product.identifier isEqualToString:baseProductIdentifier];
      }]
      lt_map:^BZRProduct *(BZRProduct *product) {
        NSString *variantIdentifier =
            [self.variantSelector selectedVariantForProductWithIdentifier:product.identifier];
        BZRProduct *variant = productDictionary[variantIdentifier];
        return [variant modelByOverridingProperty:@keypath(variant, identifier)
                                        withValue:product.identifier];
  }];
  return [NSSet setWithArray:variantsWithBaseIdentifers];
}

- (RACSignal *)completedTransactionsSignal {
  return [[[self.storeKitFacade.unfinishedSuccessfulTransactionsSignal
      flattenMap:^RACStream *(NSArray<SKPaymentTransaction *> *transactions) {
        return [transactions.rac_sequence signalWithScheduler:[RACScheduler immediateScheduler]];
      }]
      takeUntil:[self rac_willDeallocSignal]]
      setNameWithFormat:@"%@ -completedTransactionsSignal", self];
}

#pragma mark -
#pragma mark Sending events
#pragma mark -

- (void)sendErrorEventOfType:(BZREventType *)eventType error:(NSError *)error {
  [self.eventsSubject sendNext:[[BZREvent alloc] initWithType:eventType eventError:error]];
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
      @instanceKeypath(BZRStore, allowedProductsProvider.allowedProducts),
      @instanceKeypath(BZRStore, productDictionary),
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

+ (NSSet *)keyPathsForValuesAffectingAppStoreLocale {
  return [NSSet setWithObject:
      @instanceKeypath(BZRStore, validationParametersProvider.appStoreLocale)];
}

@end

NS_ASSUME_NONNULL_END
