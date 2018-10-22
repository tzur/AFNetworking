// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStore.h"

#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>
#import <LTKit/NSDictionary+Functional.h>
#import <LTKit/NSSet+Functional.h>
#import <LTKit/NSSet+Operations.h>

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRAllowedProductsProvider.h"
#import "BZRAppStoreLocaleProvider.h"
#import "BZRCachedContentFetcher.h"
#import "BZREvent+AdditionalInfo.h"
#import "BZRKeychainStorage.h"
#import "BZRMultiAppReceiptValidationStatusProvider.h"
#import "BZRMultiAppSubscriptionClassifier.h"
#import "BZRPeriodicReceiptValidatorActivator.h"
#import "BZRProduct+EnablesProduct.h"
#import "BZRProduct+StoreKit.h"
#import "BZRProductContentManager.h"
#import "BZRProductsProvider.h"
#import "BZRProductsVariantSelector.h"
#import "BZRProductsVariantSelectorFactory.h"
#import "BZRReceiptModel+ProductPurchased.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRStoreConfiguration.h"
#import "BZRStoreKitCachedMetadataFetcher.h"
#import "BZRStoreKitFacade.h"
#import "BZRUserIDProvider.h"
#import "BZRValidatricksClient.h"
#import "BZRValidatricksModels.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSString+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRStore ()

/// Provider used to provide the list of products.
@property (readonly, nonatomic) id<BZRProductsProvider> productsProvider;

/// Manager used to manage products content directory.
@property (readonly, nonatomic) BZRProductContentManager *contentManager;

/// Fetcher used to provide products' content.
@property (readonly, nonatomic) id<BZRProductContentFetcher> contentFetcher;

/// Provider used to provide all of the latest \c BZRReceiptValidationStatuses.
@property (readonly, nonatomic) BZRMultiAppReceiptValidationStatusProvider
    *multiAppValidationStatusProvider;

/// Object used to check which subscription products are multi-app subscriptions.
@property (readonly, nonatomic, nullable) id<BZRMultiAppSubscriptionClassifier>
    multiAppSubscriptionClassifier;

/// Provider used to provide list of products that were acquired via subsription.
@property (readonly, nonatomic) BZRAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;

/// Activator used to control the periodic validation.
@property (readonly, nonatomic, nullable) BZRPeriodicReceiptValidatorActivator
    *periodicValidatorActivator;

/// Facade used to interact with Apple StoreKit.
@property (readonly, nonatomic) BZRStoreKitFacade *storeKitFacade;

/// Factory used to create \c BZRLocaleProductsvariantSelector.
@property (readonly, nonatomic) id<BZRProductsVariantSelectorFactory> variantSelectorFactory;

/// Selector used to select the active variant for each product. The selector is initialized with
/// \c BZRProductsVariantSelector. When the list of products is fetched successfully,
/// \c variantSelectorFactory is called which returns a new \c BZRProductsVariantSelector. If the
/// selector was created successfully, \c variantSelector is set to that selector.
@property (strong, atomic) id<BZRProductsVariantSelector> variantSelector;

/// Provider used to provide products the user is allowed to use.
@property (readonly, nonatomic) BZRAllowedProductsProvider *allowedProductsProvider;

/// Provider used to provide product list before getting their price info from StoreKit.
@property (readonly, nonatomic) id<BZRProductsProvider> netherProductsProvider;

/// Fetcher used to fetch products metadata.
@property (readonly, nonatomic) BZRStoreKitCachedMetadataFetcher *storeKitMetadataFetcher;

/// Provider used to provide the current user's App Store locale.
@property (readonly, nonatomic) BZRAppStoreLocaleProvider *appStoreLocaleProvider;

/// Storage used to store and retrieve values from keychain storage.
@property (readonly, nonatomic) BZRKeychainStorage *keychainStorage;

/// Client used to make HTTP requests to Validatricks.
@property (readonly, nonatomic) id<BZRValidatricksClient> validatricksClient;

/// Provider used to provide a unique identifier of the user.
@property (readonly, nonatomic) id<BZRUserIDProvider> userIDProvider;

/// The source of \c completedTransactionsSignal.
@property (readonly, nonatomic) RACSubject *completedTransactionsSubject;

/// List of products that their content is already available on the device and ready to be used.
/// Products without content will be in the list as well.
@property (strong, readwrite, nonatomic) NSSet<NSString *> *downloadedContentProducts;

/// Subject used to send events with.
@property (readonly, nonatomic) RACSubject<BZREvent *> *eventsSubject;

/// Dictionary that maps fetched product identifier to \c BZRProduct.
@property (strong, atomic, nullable) NSDictionary<NSString *, BZRProduct *> *productDictionary;

/// Dictionary that contains products information based only on the products JSON file.
@property (strong, nonatomic, nullable) NSDictionary<NSString *, BZRProduct *> *
    productsJSONDictionary;

/// \c YES if the product list was fetched successfully using \c self.productsProvider. \c NO
/// otherwise.
@property (nonatomic) BOOL productListWasFetched;

@end

@implementation BZRStore

@synthesize allowedProducts = _allowedProducts;
@synthesize downloadedContentProducts = _downloadedContentProducts;
@synthesize productDictionary = _productDictionary;
@synthesize productsJSONDictionary = _productsJSONDictionary;
@synthesize eventsSignal = _eventsSignal;
@synthesize completedTransactionsSignal = _completedTransactionsSignal;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithConfiguration:(BZRStoreConfiguration *)configuration {
  if (self = [super init]) {
    _productsProvider = configuration.productsProvider;
    _contentManager = configuration.contentManager;
    _contentFetcher = configuration.contentFetcher;
    _multiAppValidationStatusProvider = configuration.multiAppValidationStatusProvider;
    _multiAppSubscriptionClassifier = configuration.multiAppSubscriptionClassifier;
    _acquiredViaSubscriptionProvider = configuration.acquiredViaSubscriptionProvider;
    _periodicValidatorActivator = configuration.periodicValidatorActivator;
    _storeKitFacade = configuration.storeKitFacade;
    _variantSelectorFactory = configuration.variantSelectorFactory;
    _variantSelector = [[BZRProductsVariantSelector alloc] init];
    _allowedProductsProvider = configuration.allowedProductsProvider;
    _netherProductsProvider = configuration.netherProductsProvider;
    _storeKitMetadataFetcher = configuration.storeKitMetadataFetcher;
    _appStoreLocaleProvider = configuration.appStoreLocaleProvider;
    _keychainStorage = configuration.keychainStorage;
    _validatricksClient = configuration.validatricksClient;
    _userIDProvider = configuration.userIDProvider;
    _completedTransactionsSubject = [RACSubject subject];
    _downloadedContentProducts = [NSSet set];
    _productListWasFetched = NO;

    [self initializeEventsSignal];
    [self initializeCompletedTransactionsSignal];
    [self activateBackgroundValidation];
    [self prefetchProductDictionary];
    [self prefetchProductsJSONDictionary];
    [self setupAllowedProductsUpdates];
  }
  return self;
}

- (void)initializeEventsSignal {
  _eventsSubject = [RACSubject subject];

  _eventsSignal = [[[RACSignal merge:@[
    [self.eventsSubject replay],
    self.multiAppValidationStatusProvider.eventsSignal,
    self.storeKitFacade.transactionsErrorEventsSignal,
    self.productsProvider.eventsSignal,
    self.contentFetcher.eventsSignal,
    self.storeKitMetadataFetcher.eventsSignal,
    self.keychainStorage.eventsSignal,
    self.storeKitFacade.eventsSignal,
    [self appStoreLocaleChangedEvents]
  ]]
  takeUntil:[self rac_willDeallocSignal]]
  setNameWithFormat:@"%@ -eventsSignal", self];
}

- (void)initializeCompletedTransactionsSignal {
  _completedTransactionsSignal = [[self.completedTransactionsSubject
      takeUntil:[self rac_willDeallocSignal]]
      setNameWithFormat:@"%@ -completedTransactionsSignal", self];
}

- (RACSignal<BZREvent *> *)appStoreLocaleChangedEvents {
  return [[[RACObserve(self, appStoreLocaleProvider.appStoreLocale)
      distinctUntilChanged]
      skip:1]
      map:^BZREvent *(NSLocale * _Nullable appStoreLocale) {
        return [[BZREvent alloc] initWithType:$(BZREventTypeInformational) eventInfo:@{
            kBZREventAppStoreLocaleKey: appStoreLocale.localeIdentifier ?: [NSNull null]
        }];
      }];
}

- (void)activateBackgroundValidation {
  RACSignal *completedTransactionsSignal =
      [self.storeKitFacade.unhandledSuccessfulTransactionsSignal
      deliverOn:[RACScheduler scheduler]];

  // We want to wait for the first value of the App Store locale that is fetched from the products'
  // metadata before doing validation that is triggered from the completed transactions signal.
  auto appStoreLocaleFetchedSignal =
      [[RACObserve(self, appStoreLocaleProvider.localeFetchedFromProductList) ignore:@NO] take:1];

  @weakify(self);
  auto triggerSignal = [appStoreLocaleFetchedSignal then:^{
    @strongify(self);
    return self.receiptValidationStatus ? completedTransactionsSignal :
        [completedTransactionsSignal startWith:@[]];
  }];

  [[triggerSignal
      flattenMap:^(BZRPaymentTransactionList *transactions) {
        @strongify(self);
        return [self validateTransactions:transactions];
      }]
      subscribeNext:^(BZRPaymentTransactionList *validatedTransactions) {
        @strongify(self);
        for (SKPaymentTransaction *transaction in validatedTransactions) {
          [self.storeKitFacade finishTransaction:transaction];
          if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
            [self sendPurchaseSuccessEventForTransaction:transaction];
          }
          [self.completedTransactionsSubject sendNext:transaction];
        }
      }];
}

- (void)prefetchProductDictionary {
  @weakify(self);
  [[[self fetchProductDictionaryWithProvider:self.productsProvider]
      takeUntil:[self rac_willDeallocSignal]]
      subscribeNext:^(BZRProductDictionary *productDictionary) {
        @strongify(self);
        @synchronized(self) {
          self.productListWasFetched = YES;
          [self mergeProductDictionaryWithExistingDictionary:productDictionary];
        }
      } error:^(NSError *underlyingError) {
        @strongify(self);
        NSError *error = [NSError lt_errorWithCode:BZRErrorCodeFetchingProductListFailed
                                   underlyingError:underlyingError];
        [self sendErrorEventOfType:$(BZREventTypeCriticalError) error:error];
      }];
}

- (void)mergeProductDictionaryWithExistingDictionary:(BZRProductDictionary *)productDictionary {
  self.productDictionary = self.productDictionary ?
      [self.productDictionary mtl_dictionaryByAddingEntriesFromDictionary:productDictionary] :
      productDictionary;
}

- (RACSignal<BZRProductDictionary *> *)
    fetchProductDictionaryWithProvider:(id<BZRProductsProvider>)productsProvider {
  return [[productsProvider fetchProductList]
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

    [self createVariantSelectorWithProductDictionary:productDictionary];
    [self addPreAcquiredProductsToAcquiredViaSubscription:productDictionary];
  }
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
  auto preAcquiredViaSubscriptionProducts = [[[[productDictionary allValues]
      lt_filter:^BOOL(BZRProduct *product) {
        return product.preAcquiredViaSubscription;
      }]
      lt_map:^NSString *(BZRProduct *product) {
        return product.identifier;
      }]
      lt_set];

  [self.acquiredViaSubscriptionProvider
   addAcquiredViaSubscriptionProducts:preAcquiredViaSubscriptionProducts];
}

- (void)prefetchProductsJSONDictionary {
  @weakify(self);
  [[[self fetchProductDictionaryWithProvider:self.netherProductsProvider]
      takeUntil:[self rac_willDeallocSignal]]
      subscribeNext:^(BZRProductDictionary *productDictionary) {
        @strongify(self);
        self.productsJSONDictionary = productDictionary;
      } error:^(NSError *underlyingError) {
        @strongify(self);
        NSError *error = [NSError lt_errorWithCode:BZRErrorCodeFetchingProductListFailed
                                   underlyingError:underlyingError];
        [self sendErrorEventOfType:$(BZREventTypeCriticalError) error:error];
      }];
}

- (void)setProductsJSONDictionary:(nullable NSDictionary<NSString *, BZRProduct *> *)
    productsJSONDictionary {
  _productsJSONDictionary = productsJSONDictionary;

  self.downloadedContentProducts =
      [NSSet setWithArray:[[productsJSONDictionary.allValues lt_filter:^BOOL(BZRProduct *product) {
        return !product.contentFetcherParameters;
      }] valueForKey:@instanceKeypath(BZRProduct, identifier)]];
}

- (void)setupAllowedProductsUpdates {
  @weakify(self);
  RAC(self, allowedProducts) = [[RACSignal combineLatest:@[
    RACObserve(self, allowedProductsProvider.allowedProducts),
    RACObserve(self, productDictionary)
  ] reduce:(id)^NSSet<NSString *> *(NSSet<NSString *> *allowedProducts,
                                    BZRProductDictionary * _Nullable productDictionary) {
    @strongify(self);
    NSSet<NSString *> *allowedProductsIdentifiers = [[[allowedProducts allObjects]
        lt_map:^NSString *(NSString *identifier) {
          return [identifier bzr_baseProductIdentifier];
        }]
        lt_set];

    if (!productDictionary) {
      return allowedProductsIdentifiers;
    }

    return [[self preAcquiredProducts:productDictionary]
            setByAddingObjectsFromSet:allowedProductsIdentifiers];
  }]
  distinctUntilChanged];
}

- (NSSet<NSString *> *)preAcquiredProducts:(BZRProductDictionary *)productDictionary {
  return [[[productDictionary.allValues
    lt_filter:^BOOL(BZRProduct *product) {
      return product.preAcquired;
    }]
    lt_map:^NSString *(BZRProduct *product) {
      return product.identifier;
    }]
    lt_set];
}

#pragma mark -
#pragma mark BZRProductsInfoProvider
#pragma mark -

- (RACSignal<NSBundle *> *)contentBundleForProduct:(NSString *)productIdentifier {
  if (!self.productsJSONDictionary[productIdentifier].contentFetcherParameters) {
    return [RACSignal return:nil];
  }

  return [self.contentFetcher contentBundleForProduct:
          self.productsJSONDictionary[productIdentifier]];
}

- (BOOL)isMultiAppSubscription:(NSString *)productIdentifier {
  return [self.multiAppSubscriptionClassifier isMultiAppSubscription:productIdentifier];
}

- (NSSet<NSString *> *)purchasedProducts {
  auto inAppPurchases = self.multiAppValidationStatusProvider.aggregatedReceiptValidationStatus
      .receipt.inAppPurchases;
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
  return
      self.multiAppValidationStatusProvider.aggregatedReceiptValidationStatus.receipt.subscription;
}

- (nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  return self.multiAppValidationStatusProvider.aggregatedReceiptValidationStatus;
}

- (nullable NSDictionary<NSString *, BZRReceiptValidationStatus *> *)
    multiAppReceiptValidationStatus {
  return self.multiAppValidationStatusProvider.multiAppReceiptValidationStatus;
}

- (nullable NSLocale *)appStoreLocale {
  return self.appStoreLocaleProvider.appStoreLocale;
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
            *error = [NSError lt_errorWithCode:BZRErrorCodeInvalidProductForPurchasing
                                   description:@"Received a request to purchase a product that "
                      "doesn't exist. Product id: %@", variantIdentifier];
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
        if ([self isUserSubscribed] && ![self isSubscriptionProduct:variantIdentifier] &&
            [self doesSubscriptionEnablesProductWithIdentifier:variantIdentifier]) {
          // Since there is no need to connect to StoreKit for a product that is bought/purchased by
          // a subscriber, we don't save the variant but the base product's identifier.
          [self.acquiredViaSubscriptionProvider
           addAcquiredViaSubscriptionProduct:productIdentifier];
          return [RACSignal empty];
        } else if (self.productDictionary[variantIdentifier].isSubscribersOnly) {
          NSError *error =
              [NSError lt_errorWithCode:BZRErrorCodeInvalidProductForPurchasing
                            description:@"Received a request to purchase a subscribers-only "
               "product while the user is not a subscriber. Product id: %@", variantIdentifier];
          return [RACSignal error:error];
        }
        return [self purchaseProductWithStoreKit:variantIdentifier quantity:1];
      }]
      setNameWithFormat:@"%@ -purchaseProduct", self];
}

- (RACSignal *)purchaseConsumableProduct:(NSString *)productIdentifier
                                quantity:(NSUInteger)quantity {
  static const NSUInteger kMaxQuantity = 10;

  if (quantity > kMaxQuantity) {
    auto description = [NSString stringWithFormat:@"Cannot purchase more than %lu products in one "
                        "transaction (requested quantity: %lu).", (unsigned long)kMaxQuantity,
                        (unsigned long)quantity];
    return [RACSignal error:[NSError lt_errorWithCode:BZRErrorCodeInvalidQuantityForPurchasing
                                          description:@"%@", description]];
  }

  return [self purchaseProductWithStoreKit:productIdentifier quantity:quantity];
}

- (RACSignal<NSNumber *> *)isProductClearedForSale:(NSString *)productIdentifier {
  @weakify(self);
  return [RACSignal defer:^{
    @strongify(self);
    return [RACSignal return:(self.productDictionary[productIdentifier] ? @YES : @NO)];
  }];
}

- (BOOL)isUserSubscribed {
  return [self subscriptionInfo] && ![self subscriptionInfo].isExpired;
}

- (BOOL)isSubscriptionProduct:(NSString *)productIdentifier {
  return self.productsJSONDictionary[productIdentifier].isSubscriptionProduct;
}

- (BOOL)doesSubscriptionEnablesProductWithIdentifier:(NSString *)productIdentifier {
  BZRProduct * _Nullable subscriptionProduct =
      self.productsJSONDictionary[self.subscriptionInfo.productId];
  if (!subscriptionProduct) {
    auto description = [NSString stringWithFormat:@"User has an active subscription (%@) which "
                        "is not listed in the product list", self.subscriptionInfo.productId];
    [self.eventsSubject sendNext:[[BZREvent alloc] initWithType:$(BZREventTypeInformational)
                                                      eventInfo:@{@"description": description}]];
    return YES;
  }

  return [subscriptionProduct enablesProductWithIdentifier:productIdentifier];
}

- (RACSignal *)purchaseProductWithStoreKit:(NSString *)productIdentifier
                                  quantity:(NSUInteger)quantity {
  SKProduct * _Nullable product = self.productDictionary[productIdentifier].underlyingProduct;
  if (!product) {
    auto error = [NSError lt_errorWithCode:BZRErrorCodeInvalidProductForPurchasing
                               description:@"Received a request to purchase a product that doesn't "
                  "exist or doesn't contain StoreKit product. Product id: %@", productIdentifier];
    return [RACSignal error:error];
  }

  @weakify(self);
  return [[[[[[self.storeKitFacade purchaseProduct:product quantity:quantity]
      doError:^(NSError *error) {
        @strongify(self);
        [self.storeKitFacade finishTransaction:error.bzr_transaction];
        [self sendErrorEventOfType:$(BZREventTypeNonCriticalError) error:error];
      }]
      filter:^BOOL(SKPaymentTransaction *transaction) {
        return transaction.transactionState == SKPaymentTransactionStatePurchased;
      }]
      take:1]
      flattenMap:^(SKPaymentTransaction *transaction) {
        @strongify(self);
        return [[[[self validateAndFinishTransaction:transaction]
            catch:^(NSError *error) {
              return [RACSignal error:
                  [NSError lt_errorWithCode:BZRErrorCodePurchaseFailed underlyingError:error]];
            }]
            doNext:^(SKPaymentTransaction *transaction) {
              @strongify(self);
              [self sendPurchaseSuccessEventForTransaction:transaction];
            }]
            doError:^(NSError *error) {
              @strongify(self);
              [self sendErrorEventOfType:$(BZREventTypeCriticalError) error:error];
            }];
      }]
      ignoreValues];
}

- (void)sendPurchaseSuccessEventForTransaction:(SKPaymentTransaction *)transaction {
  auto successfulPurchaseEventInfo = @{
    @"ProductID": transaction.payment.productIdentifier,
    @"PurchaseDate": transaction.transactionDate ?: [NSNull null],
    @"ValidatricksRequestID": self.receiptValidationStatus.requestId ?: [NSNull null],
    @"AppStoreLocale": self.appStoreLocale ?: [NSNull null]
  };
  auto purchaseEvent = [[BZREvent alloc] initWithType:$(BZREventTypeInformational)
                                         eventSubtype:@"PurchaseSuccessful"
                                            eventInfo:successfulPurchaseEventInfo];
  [self.eventsSubject sendNext:purchaseEvent];
}

- (RACSignal *)validateTransaction:(NSString *)transactionId {
  return [[[[RACSignal
      defer:^{
        auto * _Nullable transaction =
            [self.storeKitFacade.transactions lt_find:^BOOL(SKPaymentTransaction *transaction) {
              return [transaction.transactionIdentifier isEqualToString:transactionId] &&
                  transaction.transactionState == SKPaymentTransactionStatePurchased;
            }];

        return [RACSignal return:transaction];
      }]
      try:^BOOL(SKPaymentTransaction * _Nullable transaction, NSError *__autoreleasing *error) {
        if (!transaction && error) {
          *error = [NSError lt_errorWithCode:BZRErrorCodeInvalidTransactionIdentifier];
        }
        return transaction != nil;
      }]
      flattenMap:^RACSignal *(SKPaymentTransaction *transaction) {
        return [[self refreshReceiptInternal]
            concat:[self validateAndFinishTransaction:transaction]];
      }]
      ignoreValues];
}

- (RACSignal *)refreshReceiptInternal {
  @weakify(self);
  return [[[self.storeKitFacade refreshReceipt]
      doError:^(NSError *error) {
        @strongify(self);
        [self sendErrorEventOfType:$(BZREventTypeNonCriticalError) error:error];
      }]
      catch:^RACSignal *(NSError *error) {
        if (error.code == BZRErrorCodeOperationCancelled) {
          return [RACSignal error:error];
        }

        return [RACSignal empty];
      }];
}

- (RACSignal *)validateAndFinishTransaction:(SKPaymentTransaction *)transaction {
  @weakify(self);
  return [[[self validateTransactions:@[transaction]]
      tryMap:^SKPaymentTransaction * _Nullable(BZRPaymentTransactionList *validatedTransactions,
                                               NSError *__autoreleasing *error) {
        if (!validatedTransactions.firstObject && error) {
          *error = [NSError bzr_errorWithCode:BZRErrorCodeTransactionNotFoundInReceipt
                                  transaction:transaction];
        }

        return validatedTransactions.firstObject;
      }]
      doNext:^(SKPaymentTransaction *validatedTransaction) {
        @strongify(self);
        [self.storeKitFacade finishTransaction:validatedTransaction];
      }];
}

- (RACSignal<BZRPaymentTransactionList *> *)validateTransactions:
    (BZRPaymentTransactionList *)transactions {
  @weakify(self);
  return [[[self validateReceipt]
      map:^BZRPaymentTransactionList *(BZRReceiptValidationStatus *receiptValidationStatus) {
        return [transactions lt_filter:^BOOL(SKPaymentTransaction *transaction) {
          auto containsTransactionIdentifier = [[receiptValidationStatus.receipt.transactions
              valueForKey:@instanceKeypath(BZRReceiptTransactionInfo, transactionId)]
              containsObject:transaction.transactionIdentifier];
          auto containsTransactionDate =
              [receiptValidationStatus.receipt.transactions
               lt_find:^BOOL(BZRReceiptTransactionInfo *transactionInfo) {
                 return abs([transactionInfo.purchaseDateTime
                             timeIntervalSinceDate:transaction.transactionDate]) < FLT_EPSILON;
              }] != nil;

          return containsTransactionIdentifier || containsTransactionDate;
        }];
      }]
      doNext:^(BZRPaymentTransactionList *validatedTransactions) {
        @strongify(self);
        auto notValidatedTransactions =
            [transactions lt_filter:^BOOL(SKPaymentTransaction *transaction) {
              return ![validatedTransactions containsObject:transaction];
            }];

        for (SKPaymentTransaction *transaction in notValidatedTransactions) {
          auto error = [NSError bzr_errorWithCode:BZRErrorCodeTransactionNotFoundInReceipt
                                      transaction:transaction];
          [self sendErrorEventOfType:$(BZREventTypeCriticalError) error:error];
        }
      }];
}

- (RACSignal<BZRUserCreditStatus *> *)getUserCreditStatus:(NSString *)creditType {
  @weakify(self);
  return [[[RACSignal
      defer:^{
        @strongify(self);
        return self.receiptValidationStatus ? [RACSignal return:self.receiptValidationStatus] :
            [self validateReceipt];
      }]
      flattenMap:^RACSignal *(BZRReceiptValidationStatus *receiptValidationStatus) {
        @strongify(self);
        if (!self.userIDProvider.userID) {
          return [RACSignal error:
                  [NSError lt_errorWithCode:BZRErrorCodeUserIdentifierNotAvailable]];
        }
        return [self.validatricksClient getCreditOfType:creditType
                forUser:self.userIDProvider.userID
                environment:lt::nn(receiptValidationStatus.receipt).environment];
      }]
      doNext:^(BZRUserCreditStatus *userCreditStatus) {
        [self.keychainStorage setValue:userCreditStatus
                                forKey:[self userCreditCacheKeyForCreditType:creditType]
                                 error:nil];
      }];
}

- (NSString *)userCreditCacheKeyForCreditType:(NSString *)creditType {
  return [NSString stringWithFormat:@"bzr.userCredit.%@", creditType];
}

- (nullable BZRUserCreditStatus *)getCachedUserCreditStatus:(NSString *)creditType {
  auto userCreditCacheKey = [self userCreditCacheKeyForCreditType:creditType];
  return (BZRUserCreditStatus *)[self.keychainStorage valueForKey:userCreditCacheKey error:nil];
}

- (RACSignal<NSDictionary<NSString *, NSNumber *> *> *)getCreditPriceOfType:(NSString *)creditType
    consumableTypes:(NSSet<NSString *> *)consumableTypes {
  return [[self.validatricksClient
      getPricesInCreditType:creditType forConsumableTypes:consumableTypes.allObjects]
      tryMap:^NSDictionary<NSString *, NSNumber *> *
          (BZRConsumableTypesPriceInfo *consumableTypesPriceInfo, NSError *__autoreleasing *error) {
        auto consumableTypesWithPrice = consumableTypesPriceInfo.consumableTypesPrices.allKeys;
        auto consumableTypesWithoutPrice = [consumableTypes
                                            lt_minus:[consumableTypesWithPrice lt_set]];

        if (consumableTypesWithoutPrice.count) {
          if (error) {
            *error = [NSError lt_errorWithCode:BZRErrorCodeValidatricksRequestFailed
                                   description:@"Couldn't find prices for the consumable types: %@",
                                               consumableTypesWithoutPrice];
          }
          return nil;
        }

        return consumableTypesPriceInfo.consumableTypesPrices;
      }];
}

- (RACSignal<BZRRedeemConsumablesStatus *> *)
    redeemConsumableItems:(NSDictionary<NSString *, NSString *> *)consumableItemIDToType
    ofCreditType:(NSString *)creditType {
  auto itemsToRedeem = [[consumableItemIDToType
      lt_mapValues:^BZRConsumableItemDescriptor *(NSString *consumableItemID,
                                                  NSString *consumableType) {
        return lt::nn([[BZRConsumableItemDescriptor alloc] initWithDictionary:@{
          @instanceKeypath(BZRConsumableItemDescriptor, consumableItemId): consumableItemID,
          @instanceKeypath(BZRConsumableItemDescriptor, consumableType): consumableType,
        } error:nil]);
      }]
      allValues];

  @weakify(self);
  return [[[RACSignal
      defer:^{
        @strongify(self);
        return self.receiptValidationStatus ? [RACSignal return:self.receiptValidationStatus] :
            [self validateReceipt];
      }]
      flattenMap:^RACSignal *(BZRReceiptValidationStatus *receiptValidationStatus) {
        @strongify(self);
        if (!self.userIDProvider.userID) {
          return [RACSignal error:
                  [NSError lt_errorWithCode:BZRErrorCodeUserIdentifierNotAvailable]];
        }

        return [self.validatricksClient redeemConsumableItems:itemsToRedeem ofCreditType:creditType
                userId:self.userIDProvider.userID
                environment:lt::nn(receiptValidationStatus.receipt).environment];
      }]
      doNext:^(BZRRedeemConsumablesStatus *redeemStatus) {
        [self updateUserCreditStatusCacheWithRedeemStatus:redeemStatus];
      }];
}

- (void)updateUserCreditStatusCacheWithRedeemStatus:(BZRRedeemConsumablesStatus *)redeemStatus {
  auto creditTypeKey = [self userCreditCacheKeyForCreditType:redeemStatus.creditType];
  auto _Nullable cachedUserCreditStatus =
      (BZRUserCreditStatus *)[self.keychainStorage valueForKey:creditTypeKey error:nil];
  auto userCreditStatus = cachedUserCreditStatus ?
      [cachedUserCreditStatus updatedUserCreditStatusWithRedeemStatus:redeemStatus] :
      [[BZRUserCreditStatus alloc] initWithRedeemStatus:redeemStatus];

  [self.keychainStorage setValue:userCreditStatus forKey:creditTypeKey error:nil];
}

- (RACSignal<BZRContentFetchingProgress *> *)fetchProductContent:(NSString *)productIdentifier {
  if (!self.productsJSONDictionary[productIdentifier].contentFetcherParameters) {
    return [RACSignal return:nil];
  }

  @weakify(self);
  return [[[self.contentFetcher fetchProductContent:self.productsJSONDictionary[productIdentifier]]
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
  return [[[[[[[self.storeKitFacade refreshReceipt]
      concat:[self restorePurchases]]
      doError:^(NSError *error) {
        @strongify(self);
        [self sendErrorEventOfType:$(BZREventTypeNonCriticalError) error:error];
      }]
      catch:^RACSignal *(NSError *error) {
        if (error.code == BZRErrorCodeOperationCancelled) {
          return [RACSignal error:error];
        }

        return [RACSignal empty];
      }]
      concat:[self validateReceipt]]
      ignoreValues]
      setNameWithFormat:@"%@ -refreshReceipt", self];
}

- (RACSignal *)restorePurchases {
  @weakify(self);
  return [[[self.storeKitFacade restoreCompletedTransactions]
      deliverOnMainThread]
      doNext:^(SKPaymentTransaction *transaction) {
        @strongify(self);
        [self.storeKitFacade finishTransaction:transaction];
      }];
}

- (RACSignal<NSSet<BZRProduct *> *> *)productList {
  RACSignal<BZRProductDictionary *> *productDictionarySignal;
  @synchronized(self) {
    productDictionarySignal = self.productListWasFetched ?
        [RACSignal return:self.productDictionary] : [self refetchProductDictionarySignal];
  }

  @weakify(self);
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

- (RACSignal<BZRProductDictionary *> *)refetchProductDictionarySignal {
  @weakify(self);
  return [[[self fetchProductDictionaryWithProvider:self.productsProvider]
      doNext:^(BZRProductDictionary *productDictionary) {
        @strongify(self);
        @synchronized(self) {
          self.productListWasFetched = YES;
          [self mergeProductDictionaryWithExistingDictionary:productDictionary];
        }
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
  BZRProductList *variantsWithBaseIdentifiers =
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
  return [NSSet setWithArray:variantsWithBaseIdentifiers];
}

- (RACSignal<BZRReceiptValidationStatus *> *)validateReceipt {
  @weakify(self);
  return [[RACSignal
      defer:^{
        @strongify(self);
        return [self.multiAppValidationStatusProvider fetchReceiptValidationStatus];
      }]
      doError:^(NSError *error) {
        @strongify(self);
        [self sendErrorEventOfType:$(BZREventTypeCriticalError) error:error];
      }];
}

- (RACSignal *)acquireAllEnabledProducts {
  @weakify(self);
  return [[[RACSignal defer:^{
    @strongify(self);
    if (![self isUserSubscribed]) {
      NSError *error = [NSError lt_errorWithCode:BZRErrorCodeAcquireAllRequestedForNonSubscriber];
      return [RACSignal error:error];
    }

    auto enabledProducts =
        [[[[self.productsJSONDictionary allValues] lt_filter:^BOOL(BZRProduct *product) {
          return ![self isSubscriptionProduct:product.identifier] &&
              [self doesSubscriptionEnablesProductWithIdentifier:product.identifier];
        }]
        lt_map:^NSString *(BZRProduct *product) {
          return product.identifier;
        }]
        lt_set];

    [self.acquiredViaSubscriptionProvider addAcquiredViaSubscriptionProducts:enabledProducts];

    return [RACSignal empty];
  }]
  takeUntil:[self rac_willDeallocSignal]]
  setNameWithFormat:@"%@ -acquireAllEnabledProducts", self];
}

- (RACSignal<BZRProductDictionary *> *)fetchProductsInfo:(NSSet<NSString *> *)productIdentifiers {
  @weakify(self);
  return [[[[[[RACObserve(self, productsJSONDictionary)
      ignore:nil]
      take:1]
      flattenMap:^RACSignal<BZRProductList *> *(BZRProductDictionary *productDictionary) {
        @strongify(self);
        if (!self) {
          return [RACSignal return:(BZRProductList *)@[]];
        }

        auto requestedProductList =
            [[productDictionary allValues] lt_filter:^BOOL(BZRProduct *product) {
              return [productIdentifiers containsObject:product.identifier];
            }];

        if (requestedProductList.count != productIdentifiers.count) {
          auto missingProductIdentifiers =
              [productIdentifiers lt_filter:^BOOL(NSString *productIdentifier) {
                return !productDictionary[productIdentifier];
              }];

          return [RACSignal error:
                  [NSError bzr_invalidProductsErrorWithIdentifiers:missingProductIdentifiers]];
        }

        auto requestedProductsWithFullProducts =
            [self productsWithFullPriceProducts:requestedProductList
                              productDictionary:productDictionary];

        return [self.storeKitMetadataFetcher
                fetchProductsMetadata:requestedProductsWithFullProducts];
      }]
      map:^BZRProductDictionary *(BZRProductList *productList) {
        NSArray<NSString *> *identifiers =
            [productList valueForKey:@instanceKeypath(BZRProduct, identifier)];
        return [NSDictionary dictionaryWithObjects:productList forKeys:identifiers];
      }]
      doNext:^(BZRProductDictionary *productDictionary) {
        @strongify(self);
        [self mergeProductDictionaryWithExistingDictionary:productDictionary];
      }]
      map:^BZRProductDictionary *(BZRProductDictionary *productDictionary) {
        return [productDictionary lt_filter:^BOOL(NSString *productIdentifier, BZRProduct *) {
          return [productIdentifiers containsObject:productIdentifier];
        }];
      }];
}

- (BZRProductList *)productsWithFullPriceProducts:(BZRProductList *)products
                                productDictionary:(BZRProductDictionary *)productDictionary {
  auto productIdentifiers = [products lt_map:^NSString *(BZRProduct *product) {
    return product.identifier;
  }];

  return [[[products
      lt_filter:^BOOL(BZRProduct *product) {
        return product.fullPriceProductIdentifier &&
            ![productIdentifiers containsObject:product.fullPriceProductIdentifier] &&
            productDictionary[product.fullPriceProductIdentifier];
      }]
      lt_map:^BZRProduct *(BZRProduct *product) {
        return productDictionary[product.fullPriceProductIdentifier];
      }]
      arrayByAddingObjectsFromArray:products];
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
      @instanceKeypath(BZRStore,
                       multiAppValidationStatusProvider.aggregatedReceiptValidationStatus)];
}

+ (NSSet *)keyPathsForValuesAffectingAcquiredViaSubscriptionProducts {
  return [NSSet setWithObject:
      @instanceKeypath(BZRStore, acquiredViaSubscriptionProvider.productsAcquiredViaSubscription)];
}

+ (NSSet *)keyPathsForValuesAffectingAcquiredProducts {
  return [NSSet setWithObjects:
      @instanceKeypath(BZRStore,
                       multiAppValidationStatusProvider.aggregatedReceiptValidationStatus),
      @instanceKeypath(BZRStore, acquiredViaSubscriptionProvider.productsAcquiredViaSubscription),
      nil];
}

+ (NSSet *)keyPathsForValuesAffectingSubscriptionInfo {
  return [NSSet setWithObject:
      @instanceKeypath(BZRStore,
                       multiAppValidationStatusProvider.aggregatedReceiptValidationStatus)];
}

+ (NSSet *)keyPathsForValuesAffectingReceiptValidationStatus {
  return [NSSet setWithObject:
      @instanceKeypath(BZRStore,
                       multiAppValidationStatusProvider.aggregatedReceiptValidationStatus)];
}

+ (NSSet *)keyPathsForValuesAffectingMultiAppReceiptValidationStatus {
  return [NSSet setWithObject:
      @instanceKeypath(BZRStore,
                       multiAppValidationStatusProvider.multiAppReceiptValidationStatus)];
}

+ (NSSet *)keyPathsForValuesAffectingAppStoreLocale {
  return [NSSet setWithObject:
      @instanceKeypath(BZRStore, appStoreLocaleProvider.appStoreLocale)];
}

@end

NS_ASSUME_NONNULL_END
