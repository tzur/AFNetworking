// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "SPXConsumablesManager.h"

#import <Bazaar/BZRProductsManager.h>
#import <Bazaar/BZRReceiptValidationStatus.h>
#import <Bazaar/BZRValidatricksModels.h>
#import <Bazaar/NSError+Bazaar.h>
#import <Bazaar/NSErrorCodes+Bazaar.h>
#import <BazaarTestUtils/BZRTestUtils.h>

#import "SPXConsumableItemsModels.h"

SpecBegin(SPXConsumablesManager)

__block id<BZRProductsManager> productsManager;
__block SPXConsumablesManager *consumablesManager;
__block id<SPXConsumablesManagerDelegate> consumablesManagerDelegate;
__block NSString *creditType;
__block BZRUserCreditStatus *userCreditStatus;
__block NSDictionary<NSString *, NSNumber *> *creditTypeToPrice;

beforeEach(^{
  productsManager = OCMProtocolMock(@protocol(BZRProductsManager));
  consumablesManager = [[SPXConsumablesManager alloc] initWithProductsManager:productsManager];
  consumablesManagerDelegate = OCMProtocolMock(@protocol(SPXConsumablesManagerDelegate));
  consumablesManager.delegate = consumablesManagerDelegate;

  creditType = @"typeOfCredit";

  auto itemDescriptor = [[BZRConsumableItemDescriptor alloc] initWithDictionary:@{
    @instanceKeypath(BZRConsumableItemDescriptor, consumableItemId): @"bar",
    @instanceKeypath(BZRConsumableItemDescriptor, consumableType): @"videoFoo"
  } error:nil];
  userCreditStatus = [[BZRUserCreditStatus alloc] initWithDictionary:@{
    @instanceKeypath(BZRUserCreditStatus, requestId): @"baz",
    @instanceKeypath(BZRUserCreditStatus, creditType): creditType,
    @instanceKeypath(BZRUserCreditStatus, credit): @1337,
    @instanceKeypath(BZRUserCreditStatus, consumedItems): @[itemDescriptor]
  } error:nil];
  creditTypeToPrice = @{
    @"imageFoo": @13,
    @"videoFoo": @37
  };
});

context(@"calculating order summary", ^{
  __block NSDictionary<NSString *, NSString *> *consumableItemIDToType;

  beforeEach(^{
    consumableItemIDToType = @{
      @"foo": @"imageFoo",
      @"bar": @"videoFoo"
    };
  });

  it(@"should calculate order summary correctly", ^{
    OCMStub([productsManager getUserCreditStatus:creditType])
        .andReturn([RACSignal return:userCreditStatus]);

    OCMStub([productsManager getCreditPriceOfType:creditType
                                  consumableTypes:consumableItemIDToType.allValues.lt_set])
        .andReturn([RACSignal return:creditTypeToPrice]);

    auto fooItemStatus = [[SPXConsumableItemStatus alloc] initWithDictionary:@{
      @instanceKeypath(SPXConsumableItemStatus, consumableItemID): @"foo",
      @instanceKeypath(SPXConsumableItemStatus, creditRequired): @13,
      @instanceKeypath(SPXConsumableItemStatus, consumableType): @"imageFoo",
      @instanceKeypath(SPXConsumableItemStatus, isOwned): @NO,
      @instanceKeypath(SPXConsumableItemStatus, creditWorth): @13
    } error:nil];
    auto barItemStatus = [[SPXConsumableItemStatus alloc] initWithDictionary:@{
      @instanceKeypath(SPXConsumableItemStatus, consumableItemID): @"bar",
      @instanceKeypath(SPXConsumableItemStatus, creditRequired): @0,
      @instanceKeypath(SPXConsumableItemStatus, consumableType): @"videoFoo",
      @instanceKeypath(SPXConsumableItemStatus, isOwned): @YES,
      @instanceKeypath(SPXConsumableItemStatus, creditWorth): @37
    } error:nil];
    auto expectedOrderSummary = [[SPXConsumablesOrderSummary alloc] initWithDictionary:@{
      @instanceKeypath(SPXConsumablesOrderSummary, creditType): creditType,
      @instanceKeypath(SPXConsumablesOrderSummary, currentCredit): @1337,
      @instanceKeypath(SPXConsumablesOrderSummary, consumableItemsStatus): @{
        @"foo": fooItemStatus,
        @"bar": barItemStatus
      }
    } error:nil];

    auto recorder =
        [[consumablesManager calculateOrderSummary:creditType
                            consumableItemIDToType:consumableItemIDToType] testRecorder];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[expectedOrderSummary]);
  });

  it(@"should send error without calling delegate if the operation is cancelled", ^{
    OCMReject([consumablesManagerDelegate presentAlertWithError:OCMOCK_ANY
                                                 tryAgainAction:OCMOCK_ANY
                                                contactUsAction:OCMOCK_ANY
                                                   cancelAction:OCMOCK_ANY]);

    auto bazaarError = [NSError lt_errorWithCode:BZRErrorCodeOperationCancelled];
    OCMExpect([productsManager getUserCreditStatus:OCMOCK_ANY])
        .andReturn([RACSignal error:bazaarError]);
    OCMExpect([productsManager getCreditPriceOfType:OCMOCK_ANY consumableTypes:OCMOCK_ANY])
        .andReturn([RACSignal error:bazaarError]);

    auto signal = [consumablesManager calculateOrderSummary:@"foo"
                                     consumableItemIDToType:consumableItemIDToType];

    expect(signal).will.sendError(bazaarError);
  });

  context(@"handling bazaar errors", ^{
    __block NSError *bazaarError;

    beforeEach(^{
      bazaarError = [NSError lt_errorWithCode:1337];
      OCMExpect([productsManager getUserCreditStatus:OCMOCK_ANY])
          .andReturn([RACSignal error:bazaarError]);
      OCMExpect([productsManager getCreditPriceOfType:@"foo" consumableTypes:OCMOCK_ANY])
          .andReturn([RACSignal error:bazaarError]);
    });

    it(@"should send error if delegate invoked cancel action", ^{
      OCMStub([consumablesManagerDelegate presentAlertWithError:OCMOCK_ANY
                                                 tryAgainAction:OCMOCK_ANY
                                                contactUsAction:OCMOCK_ANY
                                                   cancelAction:[OCMArg invokeBlock]]);

      auto signal = [consumablesManager calculateOrderSummary:@"foo"
                                       consumableItemIDToType:consumableItemIDToType];

      expect(signal).will.sendError(bazaarError);
    });

    it(@"should call present feedback mail composer when contact us action is invoked", ^{
      OCMStub([consumablesManagerDelegate presentAlertWithError:OCMOCK_ANY
                                                 tryAgainAction:OCMOCK_ANY
                                                contactUsAction:[OCMArg invokeBlock]
                                                   cancelAction:OCMOCK_ANY]);
      OCMExpect([consumablesManagerDelegate
          presentFeedbackMailComposerWithCompletionHandler:[OCMArg invokeBlock]]);

      auto signal = [consumablesManager calculateOrderSummary:@"foo"
                                       consumableItemIDToType:consumableItemIDToType];

      expect(signal).will.finish();
      OCMVerifyAll((id)consumablesManagerDelegate);
    });

    it(@"should send error after present feedback mail composer invokes completion block", ^{
      OCMStub([consumablesManagerDelegate presentAlertWithError:OCMOCK_ANY
                                                 tryAgainAction:OCMOCK_ANY
                                                contactUsAction:[OCMArg invokeBlock]
                                                   cancelAction:OCMOCK_ANY]);
      OCMStub([consumablesManagerDelegate
               presentFeedbackMailComposerWithCompletionHandler:[OCMArg invokeBlock]]);

      auto signal = [consumablesManager calculateOrderSummary:@"foo"
                                       consumableItemIDToType:consumableItemIDToType];

      expect(signal).will.sendError(bazaarError);
    });

    it(@"should try to calculate order summary again if try again action is invoked", ^{
      OCMStub([consumablesManagerDelegate presentAlertWithError:OCMOCK_ANY
                                                 tryAgainAction:[OCMArg invokeBlock]
                                                contactUsAction:OCMOCK_ANY
                                                   cancelAction:OCMOCK_ANY]);

      OCMExpect([productsManager getUserCreditStatus:OCMOCK_ANY])
          .andReturn([RACSignal return:userCreditStatus]);
      OCMExpect([productsManager getCreditPriceOfType:OCMOCK_ANY consumableTypes:OCMOCK_ANY])
          .andReturn([RACSignal return:creditTypeToPrice]);

      auto recorder =
          [[consumablesManager calculateOrderSummary:@"foo"
                              consumableItemIDToType:consumableItemIDToType] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValuesWithCount(1);
      OCMVerifyAll((id)productsManager);
    });
  });
});

context(@"placing order", ^{
  __block SPXConsumableItemStatus *fooItemStatus;
  __block SPXConsumableItemStatus *barItemStatus;
  __block SPXConsumablesOrderSummary *orderSummaryWithEnoughCredit;
  __block SPXConsumablesOrderSummary *orderSummaryWithoutEnoughCredit;

  beforeEach(^{
    fooItemStatus = [[SPXConsumableItemStatus alloc] initWithDictionary:@{
      @instanceKeypath(SPXConsumableItemStatus, consumableItemID): @"foo",
      @instanceKeypath(SPXConsumableItemStatus, creditRequired): @13,
      @instanceKeypath(SPXConsumableItemStatus, consumableType): @"imageFoo",
      @instanceKeypath(SPXConsumableItemStatus, isOwned): @NO,
      @instanceKeypath(SPXConsumableItemStatus, creditWorth): @13
    } error:nil];
    barItemStatus = [[SPXConsumableItemStatus alloc] initWithDictionary:@{
      @instanceKeypath(SPXConsumableItemStatus, consumableItemID): @"bar",
      @instanceKeypath(SPXConsumableItemStatus, creditRequired): @0,
      @instanceKeypath(SPXConsumableItemStatus, consumableType): @"videoFoo",
      @instanceKeypath(SPXConsumableItemStatus, isOwned): @YES,
      @instanceKeypath(SPXConsumableItemStatus, creditWorth): @37
    } error:nil];

    orderSummaryWithEnoughCredit = [[SPXConsumablesOrderSummary alloc] initWithDictionary:@{
      @instanceKeypath(SPXConsumablesOrderSummary, creditType): creditType,
      @instanceKeypath(SPXConsumablesOrderSummary, currentCredit): @1337,
      @instanceKeypath(SPXConsumablesOrderSummary, consumableItemsStatus): @{
          @"foo": fooItemStatus,
          @"bar": barItemStatus
      }
    } error:nil];

    orderSummaryWithoutEnoughCredit = [[SPXConsumablesOrderSummary alloc] initWithDictionary:@{
      @instanceKeypath(SPXConsumablesOrderSummary, creditType): creditType,
      @instanceKeypath(SPXConsumablesOrderSummary, currentCredit): @10,
      @instanceKeypath(SPXConsumablesOrderSummary, consumableItemsStatus): @{
          @"foo": fooItemStatus,
          @"bar": barItemStatus
      }
    } error:nil];
  });

  it(@"should not purchase more credit when there is enough credit", ^{
    auto consumedItemDescriptor = [[BZRConsumedItemDescriptor alloc] initWithDictionary:@{
      @instanceKeypath(BZRConsumedItemDescriptor, consumableType): @"imageFoo",
      @instanceKeypath(BZRConsumedItemDescriptor, consumableItemId): @"foo",
      @instanceKeypath(BZRConsumedItemDescriptor, redeemedCredit): @37
    } error:nil];
    auto bazaarRedeemStatus = [[BZRRedeemConsumablesStatus alloc] initWithDictionary:@{
      @instanceKeypath(BZRRedeemConsumablesStatus, requestId): @"requestId",
      @instanceKeypath(BZRRedeemConsumablesStatus, creditType): creditType,
      @instanceKeypath(BZRRedeemConsumablesStatus, currentCredit): @133,
      @instanceKeypath(BZRRedeemConsumablesStatus, consumedItems): @[consumedItemDescriptor]
    } error:nil];
    OCMStub([productsManager redeemConsumableItems:@{@"foo": @"imageFoo"} ofCreditType:creditType])
        .andReturn([RACSignal return:bazaarRedeemStatus]);
    OCMReject([[(id)productsManager ignoringNonObjectArgs] purchaseConsumableProduct:OCMOCK_ANY
                                                                            quantity:0]);

    auto redeemedItemStatus = [[SPXRedeemedItemStatus alloc] initWithDictionary:@{
      @instanceKeypath(SPXRedeemedItemStatus, consumableItemID): @"foo",
      @instanceKeypath(SPXRedeemedItemStatus, consumableType): @"imageFoo",
      @instanceKeypath(SPXRedeemedItemStatus, redeemedCredit): @37
    } error:nil];
    auto expectedRedeemStatus = [[SPXRedeemStatus alloc] initWithDictionary:@{
      @instanceKeypath(SPXRedeemStatus, creditType): creditType,
      @instanceKeypath(SPXRedeemStatus, currentCredit): @133,
      @instanceKeypath(SPXRedeemStatus, redeemedItems): @{@"foo": redeemedItemStatus}
    } error:nil];

    auto recorder = [[consumablesManager placeOrder:orderSummaryWithEnoughCredit
                              withProductIdentifier:@"baz"] testRecorder];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[expectedRedeemStatus]);
  });

  it(@"should purchase more credit with given product when there is not enough credit", ^{
    auto consumedItemDescriptor = [[BZRConsumedItemDescriptor alloc] initWithDictionary:@{
      @instanceKeypath(BZRConsumedItemDescriptor, consumableType): @"imageFoo",
      @instanceKeypath(BZRConsumedItemDescriptor, consumableItemId): @"foo",
      @instanceKeypath(BZRConsumedItemDescriptor, redeemedCredit): @37
    } error:nil];
    auto bazaarRedeemStatus = [[BZRRedeemConsumablesStatus alloc] initWithDictionary:@{
      @instanceKeypath(BZRRedeemConsumablesStatus, requestId): @"requestId",
      @instanceKeypath(BZRRedeemConsumablesStatus, creditType): creditType,
      @instanceKeypath(BZRRedeemConsumablesStatus, currentCredit): @0,
      @instanceKeypath(BZRRedeemConsumablesStatus, consumedItems): @[consumedItemDescriptor]
    } error:nil];
    OCMStub([productsManager purchaseConsumableProduct:@"baz" quantity:3])
        .andReturn([RACSignal empty]);
    OCMStub([productsManager redeemConsumableItems:@{@"foo": @"imageFoo"} ofCreditType:creditType])
        .andReturn([RACSignal return:bazaarRedeemStatus]);

    auto recorder = [[consumablesManager placeOrder:orderSummaryWithoutEnoughCredit
                              withProductIdentifier:@"baz"] testRecorder];

    auto redeemedItemStatus = [[SPXRedeemedItemStatus alloc] initWithDictionary:@{
      @instanceKeypath(SPXRedeemedItemStatus, consumableItemID): @"foo",
      @instanceKeypath(SPXRedeemedItemStatus, consumableType): @"imageFoo",
      @instanceKeypath(SPXRedeemedItemStatus, redeemedCredit): @37
    } error:nil];
    auto expectedRedeemStatus = [[SPXRedeemStatus alloc] initWithDictionary:@{
      @instanceKeypath(SPXRedeemStatus, creditType): creditType,
      @instanceKeypath(SPXRedeemStatus, currentCredit): @0,
      @instanceKeypath(SPXRedeemStatus, redeemedItems): @{@"foo": redeemedItemStatus}
    } error:nil];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[expectedRedeemStatus]);

    OCMVerifyAll((id)productsManager);
  });

  it(@"should send redeem status without forwarding to products manager if all items are already "
     "owned", ^{
    fooItemStatus = [[SPXConsumableItemStatus alloc] initWithDictionary:@{
      @instanceKeypath(SPXConsumableItemStatus, consumableItemID): @"foo",
      @instanceKeypath(SPXConsumableItemStatus, creditRequired): @0,
      @instanceKeypath(SPXConsumableItemStatus, consumableType): @"imageFoo",
      @instanceKeypath(SPXConsumableItemStatus, isOwned): @YES,
      @instanceKeypath(SPXConsumableItemStatus, creditWorth): @13
    } error:nil];
    auto orderSummary = [[SPXConsumablesOrderSummary alloc] initWithDictionary:@{
      @instanceKeypath(SPXConsumablesOrderSummary, creditType): creditType,
      @instanceKeypath(SPXConsumablesOrderSummary, currentCredit): @10,
      @instanceKeypath(SPXConsumablesOrderSummary, consumableItemsStatus): @{
          @"foo": fooItemStatus,
          @"bar": barItemStatus
      }
    } error:nil];

    OCMReject([[(id)productsManager ignoringNonObjectArgs] purchaseConsumableProduct:OCMOCK_ANY
                                                                            quantity:0]);
    OCMReject([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:OCMOCK_ANY]);

    auto recorder =
        [[consumablesManager placeOrder:orderSummary withProductIdentifier:@"baz"] testRecorder];

    auto expectedRedeemStatus = [[SPXRedeemStatus alloc] initWithDictionary:@{
      @instanceKeypath(SPXRedeemStatus, creditType): creditType,
      @instanceKeypath(SPXRedeemStatus, currentCredit): @10,
      @instanceKeypath(SPXRedeemStatus, redeemedItems): @{}
    } error:nil];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[expectedRedeemStatus]);
  });

  context(@"handling errors", ^{
    it(@"should send error without calling delegate if the operation is cancelled", ^{
      OCMReject([consumablesManagerDelegate presentAlertWithError:OCMOCK_ANY
                                                   tryAgainAction:OCMOCK_ANY
                                                  contactUsAction:OCMOCK_ANY
                                                     cancelAction:OCMOCK_ANY]);

      auto bazaarError = [NSError lt_errorWithCode:BZRErrorCodeOperationCancelled];
      OCMExpect([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:OCMOCK_ANY])
          .andReturn([RACSignal error:bazaarError]);

      auto signal =
          [consumablesManager placeOrder:orderSummaryWithEnoughCredit withProductIdentifier:@"baz"];

      expect(signal).will.sendError(bazaarError);
    });

    it(@"should send error if delegate invoked cancel action", ^{
      auto bazaarError = [NSError lt_errorWithCode:1337];
      OCMStub([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:OCMOCK_ANY])
          .andReturn([RACSignal error:bazaarError]);

      OCMStub([consumablesManagerDelegate presentAlertWithError:OCMOCK_ANY
                                                 tryAgainAction:OCMOCK_ANY
                                                contactUsAction:OCMOCK_ANY
                                                   cancelAction:[OCMArg invokeBlock]]);

      auto signal =
          [consumablesManager placeOrder:orderSummaryWithEnoughCredit withProductIdentifier:@"baz"];

      expect(signal).will.sendError(bazaarError);
    });

    it(@"should call present feedback mail composer when contact us action is invoked", ^{
      auto bazaarError = [NSError lt_errorWithCode:1337];
      OCMStub([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:OCMOCK_ANY])
          .andReturn([RACSignal error:bazaarError]);
      OCMStub([consumablesManagerDelegate presentAlertWithError:OCMOCK_ANY
                                                 tryAgainAction:OCMOCK_ANY
                                                contactUsAction:[OCMArg invokeBlock]
                                                   cancelAction:OCMOCK_ANY]);
      OCMExpect([consumablesManagerDelegate
          presentFeedbackMailComposerWithCompletionHandler:[OCMArg invokeBlock]]);

      auto signal =
          [consumablesManager placeOrder:orderSummaryWithEnoughCredit withProductIdentifier:@"baz"];

      expect(signal).will.finish();
      OCMVerifyAll((id)consumablesManagerDelegate);
    });

    it(@"should send error after present feedback mail composer invokes completion block", ^{
      auto bazaarError = [NSError lt_errorWithCode:1337];
      OCMStub([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:OCMOCK_ANY])
          .andReturn([RACSignal error:bazaarError]);

      OCMStub([consumablesManagerDelegate presentAlertWithError:OCMOCK_ANY
                                                 tryAgainAction:OCMOCK_ANY
                                                contactUsAction:[OCMArg invokeBlock]
                                                   cancelAction:OCMOCK_ANY]);
      OCMStub([consumablesManagerDelegate
               presentFeedbackMailComposerWithCompletionHandler:[OCMArg invokeBlock]]);

      auto signal =
          [consumablesManager placeOrder:orderSummaryWithEnoughCredit withProductIdentifier:@"baz"];

      expect(signal).will.sendError(bazaarError);
    });

    it(@"should pass nil try again action if the error from bazaar is unknown", ^{
      auto bazaarError = [NSError lt_errorWithCode:1337];
      OCMExpect([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:creditType])
          .andReturn([RACSignal error:bazaarError]);

      OCMExpect([consumablesManagerDelegate presentAlertWithError:OCMOCK_ANY
                                                   tryAgainAction:[OCMArg isNil]
                                                  contactUsAction:OCMOCK_ANY
                                                     cancelAction:[OCMArg invokeBlock]]);

      auto signal = [consumablesManager placeOrder:orderSummaryWithEnoughCredit
                             withProductIdentifier:@"baz"];

      expect(signal).will.sendError(bazaarError);
      OCMVerifyAll((id)consumablesManagerDelegate);
    });

    it(@"should pass nil try again action if the error from bazaar is not enough credit", ^{
      BZRValidatricksNotEnoughCreditErrorInfo *errorInfo =
          OCMClassMock(BZRValidatricksNotEnoughCreditErrorInfo.class);
      auto bazaarError =
          [NSError bzr_validatricksRequestErrorWithURL:[NSURL URLWithString:@"http://foo"]
                                 validatricksErrorInfo:errorInfo
                                       underlyingError:OCMClassMock(NSError.class)];
      OCMExpect([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:creditType])
          .andReturn([RACSignal error:bazaarError]);

      OCMExpect([consumablesManagerDelegate presentAlertWithError:OCMOCK_ANY
                                                   tryAgainAction:[OCMArg isNil]
                                                  contactUsAction:OCMOCK_ANY
                                                     cancelAction:[OCMArg invokeBlock]]);

      auto signal = [consumablesManager placeOrder:orderSummaryWithEnoughCredit
                             withProductIdentifier:@"baz"];

      expect(signal).will.sendError(bazaarError);
      OCMVerifyAll((id)consumablesManagerDelegate);
    });

    context(@"try again action", ^{
      __block BZRRedeemConsumablesStatus *redeemStatus;

      beforeEach(^{
        auto consumedItemDescriptor = [[BZRConsumedItemDescriptor alloc] initWithDictionary:@{
          @instanceKeypath(BZRConsumedItemDescriptor, consumableType): @"imageFoo",
          @instanceKeypath(BZRConsumedItemDescriptor, consumableItemId): @"foo",
          @instanceKeypath(BZRConsumedItemDescriptor, redeemedCredit): @37
        } error:nil];
        redeemStatus = [[BZRRedeemConsumablesStatus alloc] initWithDictionary:@{
          @instanceKeypath(BZRRedeemConsumablesStatus, requestId): @"requestId",
          @instanceKeypath(BZRRedeemConsumablesStatus, creditType): creditType,
          @instanceKeypath(BZRRedeemConsumablesStatus, currentCredit): @133,
          @instanceKeypath(BZRRedeemConsumablesStatus, consumedItems): @[consumedItemDescriptor]
        } error:nil];

        OCMStub([consumablesManagerDelegate presentAlertWithError:OCMOCK_ANY
                                                   tryAgainAction:[OCMArg invokeBlock]
                                                  contactUsAction:OCMOCK_ANY
                                                     cancelAction:OCMOCK_ANY]);
      });

      it(@"should pass try again action with retry receipt validation and redeem if receipt "
         "validation failed", ^{
        auto underlyingError = [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed];
        auto bazaarError = [NSError lt_errorWithCode:BZRErrorCodePurchaseFailed
                                     underlyingError:underlyingError];
        OCMExpect([[(id)productsManager ignoringNonObjectArgs]
            purchaseConsumableProduct:OCMOCK_ANY quantity:0])
            .andReturn([RACSignal error:bazaarError]);
        OCMExpect([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:creditType])
            .andReturn([RACSignal return:redeemStatus]);

        OCMExpect([productsManager validateReceipt])
            .andReturn([RACSignal return:BZRReceiptValidationStatusWithExpiry(NO)]);
        OCMExpect([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:creditType])
            .andReturn([RACSignal return:redeemStatus]);

        auto recorder = [[consumablesManager placeOrder:orderSummaryWithoutEnoughCredit
                                  withProductIdentifier:@"baz"] testRecorder];

        expect(recorder).will.complete();
        expect(recorder).will.sendValuesWithCount(1);
        OCMVerifyAll((id)productsManager);
      });

      it(@"should pass try again action with validating transaction and redeem if the transaction "
         "wasn't found in receipt", ^{
        SKPaymentTransaction *transaction = OCMClassMock(SKPaymentTransaction.class);
        OCMStub([transaction transactionIdentifier]).andReturn(@"transactionId");
        auto underlyingError = [NSError bzr_errorWithCode:BZRErrorCodeTransactionNotFoundInReceipt
                                              transaction:transaction];
        auto bazaarError = [NSError lt_errorWithCode:BZRErrorCodePurchaseFailed
                                     underlyingError:underlyingError];

        OCMExpect([[(id)productsManager ignoringNonObjectArgs]
            purchaseConsumableProduct:OCMOCK_ANY quantity:0])
            .andReturn([RACSignal error:bazaarError]);
        OCMExpect([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:creditType])
            .andReturn([RACSignal return:redeemStatus]);

        OCMExpect([productsManager validateTransaction:@"transactionId"])
            .andReturn([RACSignal empty]);
        OCMExpect([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:creditType])
            .andReturn([RACSignal return:redeemStatus]);

        auto recorder = [[consumablesManager placeOrder:orderSummaryWithoutEnoughCredit
                                  withProductIdentifier:@"baz"] testRecorder];

        expect(recorder).will.complete();
        expect(recorder).will.sendValuesWithCount(1);
        OCMVerifyAll((id)productsManager);
      });

      it(@"should pass try again action with purchase product and redeem if the purchase failed", ^{
        auto bazaarError = [NSError lt_errorWithCode:BZRErrorCodePurchaseFailed];
        OCMExpect([[(id)productsManager ignoringNonObjectArgs]
            purchaseConsumableProduct:OCMOCK_ANY quantity:0])
            .andReturn([RACSignal error:bazaarError]);
        OCMExpect([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:creditType])
            .andReturn([RACSignal return:redeemStatus]);

        OCMExpect([[(id)productsManager ignoringNonObjectArgs]
            purchaseConsumableProduct:OCMOCK_ANY quantity:0]).andReturn([RACSignal empty]);
        OCMExpect([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:creditType])
            .andReturn([RACSignal return:redeemStatus]);

        auto recorder = [[consumablesManager placeOrder:orderSummaryWithoutEnoughCredit
                                  withProductIdentifier:@"baz"] testRecorder];

        expect(recorder).will.complete();
        expect(recorder).will.sendValuesWithCount(1);
        OCMVerifyAll((id)productsManager);
      });

      it(@"should pass try again action with redeem if the redeem failed", ^{
        auto bazaarError = [NSError lt_errorWithCode:BZRErrorCodeValidatricksRequestFailed];
        OCMExpect([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:creditType])
            .andReturn([RACSignal error:bazaarError]);

        OCMReject([[(id)productsManager ignoringNonObjectArgs]
            purchaseConsumableProduct:OCMOCK_ANY quantity:0]);
        OCMExpect([productsManager redeemConsumableItems:OCMOCK_ANY ofCreditType:creditType])
            .andReturn([RACSignal return:redeemStatus]);

        auto recorder = [[consumablesManager placeOrder:orderSummaryWithEnoughCredit
                                  withProductIdentifier:@"baz"] testRecorder];

        expect(recorder).will.complete();
        expect(recorder).will.sendValuesWithCount(1);
        OCMVerifyAll((id)productsManager);
      });
    });
  });
});

SpecEnd
