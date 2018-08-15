// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "SPXConsumablesManager.h"

#import <Bazaar/BZRProductsManager.h>
#import <Bazaar/BZRValidatricksModels.h>
#import <Bazaar/NSError+Bazaar.h>
#import <Bazaar/NSErrorCodes+Bazaar.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSDictionary+Functional.h>

#import "NSError+Shopix.h"
#import "SPXConsumableItemsModels.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXConsumablesManager ()

/// Manager used to calculate order summary and redeem credit for consumable products.
@property (readonly, nonatomic) id<BZRProductsManager> productsManager;

@end

@implementation SPXConsumablesManager

- (instancetype)init {
  id<BZRProductsManager> _Nullable productsManager =
      [JSObjection defaultInjector][@protocol(BZRProductsManager)];

  LTAssert(productsManager, @"BZRProductsManager was not injected properly, make sure Objection's "
                            "default injector has binding for this protocol");

  return [self initWithProductsManager:productsManager];
}

- (instancetype)initWithProductsManager:(id<BZRProductsManager>)productsManager {
  if (self = [super init]) {
    _productsManager = productsManager;
  }

  return self;
}

#pragma mark -
#pragma mark Calculate order summary
#pragma mark -

- (BOOL)userOwnsAllItems:(NSDictionary<NSString *, NSString *> *)consumableItemIDToType
          withCreditType:(NSString *)creditType {
  auto _Nullable userCreditStatus = [self.productsManager getCachedUserCreditStatus:creditType];
  return userCreditStatus ?
      [self isAllItemsOwned:consumableItemIDToType userCreditStatus:userCreditStatus] : NO;
}

- (BOOL)isAllItemsOwned:(NSDictionary<NSString *, NSString *> *)consumableItemIDToType
       userCreditStatus:(BZRUserCreditStatus *)userCreditStatus {
  auto requestedItemsIDs = consumableItemIDToType.allKeys.lt_set;
  auto consumedItemsIDs = [self calculateConsumedItemsIDs:consumableItemIDToType
                                               userCredit:userCreditStatus];

  return [consumedItemsIDs.lt_set isEqualToSet:requestedItemsIDs];
}

- (RACSignal<SPXConsumablesOrderSummary *> *)calculateOrderSummary:(NSString *)creditType
    consumableItemIDToType:(NSDictionary<NSString *, NSString *> *)consumableItemIDToType {
  auto userCreditAndTypesPricesSignal =
      [self userCreditAndTypesPricesSignal:creditType
                    consumableItemIDToType:consumableItemIDToType];

  return [[userCreditAndTypesPricesSignal
      tryMap:^SPXConsumablesOrderSummary *(RACTuple *tuple, NSError * __autoreleasing *error) {
        RACTupleUnpack(BZRUserCreditStatus *userCredit,
                       NSDictionary *consumableTypeToPrice) = tuple;
        return [self summaryFromUserCredit:userCredit consumableTypeToPrice:consumableTypeToPrice
                    consumableItemIDToType:consumableItemIDToType error:error];
      }]
      catch:^(NSError *error) {
        if (error.code == BZRErrorCodeOperationCancelled) {
          return [RACSignal error:error];
        }
        return [self presentCalculateOrderSummaryFailedWithError:error creditType:creditType
                                          consumableItemIDToType:consumableItemIDToType];
      }];
}

- (RACSignal<RACTuple *> *)userCreditAndTypesPricesSignal:(NSString *)creditType
    consumableItemIDToType:(NSDictionary<NSString *, NSString *> *)consumableItemIDToType {
  auto requestedTypes = consumableItemIDToType.allValues.lt_set;
  return [RACSignal combineLatest:@[
    [self.productsManager getUserCreditStatus:creditType],
    [self.productsManager getCreditPriceOfType:creditType consumableTypes:requestedTypes]
  ]];
}

- (nullable SPXConsumablesOrderSummary *)summaryFromUserCredit:(BZRUserCreditStatus *)userCredit
    consumableTypeToPrice:(NSDictionary<NSString *, NSNumber *> *)consumableTypeToPrice
    consumableItemIDToType:(NSDictionary<NSString *, NSString *> *)consumableItemIDToType
    error:(NSError * __autoreleasing *)error {
  auto consumedItemsIDs = [self calculateConsumedItemsIDs:consumableItemIDToType
                                               userCredit:userCredit];

  auto consumableItemsStatus = [consumableItemIDToType
      lt_mapValues:^SPXConsumableItemStatus *(NSString *consumableItemID,
                                              NSString *consumableType) {
        auto consumableTypePrice = consumableTypeToPrice[consumableType];
        return [self buildConsumableItemStatus:consumableItemID consumedItemsIDs:consumedItemsIDs
                                consumableType:consumableType requiredCredit:consumableTypePrice];
      }];

  return [[SPXConsumablesOrderSummary alloc] initWithDictionary:@{
    @instanceKeypath(SPXConsumablesOrderSummary, creditType): userCredit.creditType,
    @instanceKeypath(SPXConsumablesOrderSummary, currentCredit): @(userCredit.credit),
    @instanceKeypath(SPXConsumablesOrderSummary, consumableItemsStatus): consumableItemsStatus
  } error:error];
}

- (NSArray<NSString *> *)calculateConsumedItemsIDs:
    (NSDictionary<NSString *, NSString *> *)consumableItemIDToType
    userCredit:(BZRUserCreditStatus *)userCredit {
  return [[consumableItemIDToType
      lt_filter:^BOOL(NSString *consumableItemID, NSString *consumableType) {
        return [userCredit.consumedItems lt_find:^BOOL(BZRConsumableItemDescriptor *item) {
          return [item.consumableItemId isEqualToString:consumableItemID] &&
              [item.consumableType isEqualToString:consumableType];
        }] != nil;
      }]
      allKeys];
}

- (SPXConsumableItemStatus *)buildConsumableItemStatus:(NSString *)consumableItemID
    consumedItemsIDs:(NSArray<NSString *> *)consumedItemsIDs
    consumableType:(NSString *)consumableType requiredCredit:(NSNumber *)requiredCredit {
  return lt::nn([[SPXConsumableItemStatus alloc] initWithDictionary:@{
    @instanceKeypath(SPXConsumableItemStatus, consumableItemID): consumableItemID,
    @instanceKeypath(SPXConsumableItemStatus, creditRequired):
        [consumedItemsIDs containsObject:consumableItemID] ? @0 : requiredCredit,
    @instanceKeypath(SPXConsumableItemStatus, consumableType): consumableType,
    @instanceKeypath(SPXConsumableItemStatus, isOwned):
        [consumedItemsIDs containsObject:consumableItemID] ? @YES : @NO
  } error:nil]);
}

#pragma mark -
#pragma mark Place order
#pragma mark -

- (RACSignal<SPXRedeemStatus *> *)placeOrder:(SPXConsumablesOrderSummary *)orderSummary
                       withProductIdentifier:(NSString *)productIdentifier {
  return [[self placeOrderInternal:orderSummary withProductIdentifier:productIdentifier]
      catch:^(NSError *error) {
        if (error.code == BZRErrorCodeOperationCancelled) {
          return [RACSignal error:error];
        }
        return [self presentPlaceOrderFailedWithError:error orderSummary:orderSummary
                                    productIdentifier:productIdentifier];
      }];
}

- (RACSignal<SPXRedeemStatus *> *)placeOrderInternal:
    (SPXConsumablesOrderSummary *)orderSummary withProductIdentifier:(NSString *)productIdentifier {
  NSNumber *totalRequiredCredit = [orderSummary.consumableItemsStatus.allValues
      lt_reduce:^NSNumber *(NSNumber *requiredCreditSoFar, SPXConsumableItemStatus *itemStatus) {
        return @(requiredCreditSoFar.unsignedIntegerValue + itemStatus.creditRequired);
      } initial:@0];

  auto requiredCreditToPurchase =
      totalRequiredCredit.integerValue - (NSInteger)orderSummary.currentCredit;

  if (requiredCreditToPurchase > 0) {
    auto purchaseProductSignal =
        [self.productsManager purchaseConsumableProduct:productIdentifier
                                               quantity:(NSUInteger)requiredCreditToPurchase];
    return [purchaseProductSignal
        concat:[self redeemConsumableItemsFromOrderSummary:orderSummary]];
  }

  return [self redeemConsumableItemsFromOrderSummary:orderSummary];
}

- (RACSignal<SPXRedeemStatus *> *)redeemConsumableItemsFromOrderSummary:
    (SPXConsumablesOrderSummary *)orderSummary {
  auto consumableItemsToRedeem = [[orderSummary.consumableItemsStatus
      lt_filter:^BOOL(NSString *, SPXConsumableItemStatus *consumableItemStatus) {
        return !consumableItemStatus.isOwned;
      }]
      lt_mapValues:^NSString *(NSString *, SPXConsumableItemStatus *consumableItemStatus) {
        return consumableItemStatus.consumableType;
      }];

  if (!consumableItemsToRedeem.count) {
    return [RACSignal return:[[SPXRedeemStatus alloc] initWithDictionary:@{
      @instanceKeypath(SPXRedeemStatus, creditType): orderSummary.creditType,
      @instanceKeypath(SPXRedeemStatus, currentCredit): @(orderSummary.currentCredit),
      @instanceKeypath(SPXRedeemStatus, redeemedItems): @{}
    } error:nil]];
  }

  return [[self.productsManager redeemConsumableItems:consumableItemsToRedeem
                                         ofCreditType:orderSummary.creditType]
    tryMap:^SPXRedeemStatus *(BZRRedeemConsumablesStatus *redeemStatus,
                              NSError * __autoreleasing *error) {
      return [[SPXRedeemStatus alloc] initWithDictionary:@{
        @instanceKeypath(SPXRedeemStatus, creditType): redeemStatus.creditType,
        @instanceKeypath(SPXRedeemStatus, currentCredit): @(redeemStatus.currentCredit),
        @instanceKeypath(SPXRedeemStatus, redeemedItems):
            [self buildRedeemedItems:redeemStatus.consumedItems]
      } error:error];
    }];
}

- (NSDictionary<NSString *, SPXRedeemedItemStatus *> *)buildRedeemedItems:
    (NSArray<BZRConsumedItemDescriptor *> *)consumedItems {
  auto redeemedItems = [consumedItems
      lt_map:^SPXRedeemedItemStatus *(BZRConsumedItemDescriptor *consumedItem) {
        return lt::nn([[SPXRedeemedItemStatus alloc] initWithDictionary:@{
          @instanceKeypath(SPXRedeemedItemStatus, consumableItemID): consumedItem.consumableItemId,
          @instanceKeypath(SPXRedeemedItemStatus, consumableType): consumedItem.consumableType,
          @instanceKeypath(SPXRedeemedItemStatus, redeemedCredit): @(consumedItem.redeemedCredit)
        } error:nil]);
      }];

  NSArray<NSString *> *consumableItemsIDs =
      [redeemedItems valueForKey:@instanceKeypath(SPXRedeemedItemStatus, consumableItemID)];
  return [NSDictionary dictionaryWithObjects:redeemedItems forKeys:consumableItemsIDs];
}

#pragma mark -
#pragma mark Handling errors
#pragma mark -

- (RACSignal *)presentCalculateOrderSummaryFailedWithError:(NSError *)error
    creditType:(NSString *)creditType
    consumableItemIDToType:(NSDictionary<NSString *, NSString *> *)consumableItemIDToType {
  auto orderSummaryError =
      [NSError lt_errorWithCode:SPXErrorCodeConsumablesOrderSummaryCalculationFailed
                underlyingError:error];

  @weakify(self);
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    [self.delegate presentAlertWithError:orderSummaryError tryAgainAction:^{
      @strongify(self);
      if (!self) {
        [subscriber sendError:error];
        return;
      }

      [[self calculateOrderSummary:creditType consumableItemIDToType:consumableItemIDToType]
          subscribe:subscriber];
    } contactUsAction:^{
      @strongify(self);
      if (!self.delegate) {
        [subscriber sendError:error];
        return;
      }

      [self.delegate presentFeedbackMailComposerWithCompletionHandler:^{
        [subscriber sendError:error];
      }];
    } cancelAction:^{
      [subscriber sendError:error];
    }];

    return nil;
  }];
}

- (RACSignal *)presentPlaceOrderFailedWithError:(NSError *)error
                                   orderSummary:(SPXConsumablesOrderSummary *)orderSummary
                              productIdentifier:(NSString *)productIdentifier {
  auto placeOrderError =
      [NSError lt_errorWithCode:SPXErrorCodeConsumablesPlacingOrderFailed underlyingError:error];

  @weakify(self);
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    auto _Nullable tryAgainBlock =
        [self placeOrderTryAgainBlock:error orderSummary:orderSummary
                    productIdentifier:productIdentifier subscriber:subscriber];

    [self.delegate presentAlertWithError:placeOrderError tryAgainAction:tryAgainBlock
                         contactUsAction:^{
      @strongify(self);
      if (!self.delegate) {
        [subscriber sendError:error];
        return;
      }

      [self.delegate presentFeedbackMailComposerWithCompletionHandler:^{
        [subscriber sendError:error];
      }];
    } cancelAction:^{
      [subscriber sendError:error];
    }];

    return nil;
  }];
}

- (nullable LTVoidBlock)placeOrderTryAgainBlock:(NSError *)error
                                   orderSummary:(SPXConsumablesOrderSummary *)orderSummary
                              productIdentifier:(NSString *)productIdentifier
                                     subscriber:(id<RACSubscriber>)subscriber {
  auto _Nullable retryAttemptSignal = [self retryRedeemSignal:error orderSummary:orderSummary
                                            productIdentifier:productIdentifier];

  if (retryAttemptSignal) {
    return ^{
      [[retryAttemptSignal
          catch:^(NSError *error) {
            if (error.code == BZRErrorCodeOperationCancelled) {
              return [RACSignal error:error];
            }
            return [self presentPlaceOrderFailedWithError:error orderSummary:orderSummary
                                        productIdentifier:productIdentifier];
          }]
          subscribe:subscriber];
    };
  }

  return nil;
}

- (nullable RACSignal *)retryRedeemSignal:(NSError *)error
                             orderSummary:(SPXConsumablesOrderSummary *)orderSummary
                        productIdentifier:(NSString *)productIdentifier {
  if (error.code == BZRErrorCodePurchaseFailed) {
    return [self retryPurchaseSignal:error orderSummary:orderSummary
                   productIdentifier:productIdentifier];
  } else if (error.code == BZRErrorCodeTransactionNotFoundInReceipt) {
    auto transactionIdentifier = error.bzr_transactionIdentifier;
    return [[self.productsManager validateTransaction:transactionIdentifier]
        concat:[self redeemConsumableItemsFromOrderSummary:orderSummary]];
  } else if (error.code == BZRErrorCodeValidatricksRequestFailed) {
    if ([error.bzr_validatricksErrorInfo
      isKindOfClass:BZRValidatricksNotEnoughCreditErrorInfo.class]) {
      // If there was an error because the user doesn't have enough credit, it means that the
      // manager tried to redeem because according to the summary there is enough credit. Therefore
      // the order summary is outdated and there is a need to recalculate the order summary.
      return nil;
    }

    return [self redeemConsumableItemsFromOrderSummary:orderSummary];
  }

  return nil;
}

- (nullable RACSignal *)retryPurchaseSignal:(NSError *)error
                               orderSummary:(SPXConsumablesOrderSummary *)orderSummary
                          productIdentifier:(NSString *)productIdentifier {
  if (error.lt_underlyingError.code == BZRErrorCodeReceiptValidationFailed) {
    return [[[self.productsManager validateReceipt]
        ignoreValues]
        concat:[self redeemConsumableItemsFromOrderSummary:orderSummary]];
  } else if (error.lt_underlyingError.code == BZRErrorCodeTransactionNotFoundInReceipt) {
    auto transactionIdentifier = error.lt_underlyingError.bzr_transactionIdentifier;
    return [[self.productsManager validateTransaction:transactionIdentifier]
        concat:[self redeemConsumableItemsFromOrderSummary:orderSummary]];
  }

  return [self placeOrderInternal:orderSummary withProductIdentifier:productIdentifier];
}

@end

NS_ASSUME_NONNULL_END
