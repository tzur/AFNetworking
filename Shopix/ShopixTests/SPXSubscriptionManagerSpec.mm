// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionManager.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductsInfoProvider.h>
#import <Bazaar/BZRProductsManager.h>
#import <Bazaar/BZRReceiptModel.h>
#import <Bazaar/BZRReceiptValidationStatus.h>
#import <Bazaar/NSError+Bazaar.h>
#import <Bazaar/NSErrorCodes+Bazaar.h>

#import "SPXAlertViewModel.h"

SpecBegin(SPXSubscriptionManager)

__block id<BZRProductsManager> productsManager;
__block id<BZRProductsInfoProvider> productsInfoProvider;
__block id<SPXSubscriptionManagerDelegate> delegate;
__block SPXSubscriptionManager *subscriptionManager;
__block NSError *cancellationError;

beforeEach(^{
  productsManager = OCMProtocolMock(@protocol(BZRProductsManager));
  productsInfoProvider = OCMProtocolMock(@protocol(BZRProductsInfoProvider));
  OCMStub([productsInfoProvider productsJSONDictionary]).andReturn((@{
    @"foo": OCMClassMock([BZRProduct class]),
    @"bar": OCMClassMock([BZRProduct class])
  }));

  delegate = OCMStrictProtocolMock(@protocol(SPXSubscriptionManagerDelegate));
  subscriptionManager =
      [[SPXSubscriptionManager alloc] initWithProductsInfoProvider:productsInfoProvider
                                                   productsManager:productsManager];
  subscriptionManager.delegate = delegate;

  cancellationError = [NSError lt_errorWithCode:BZRErrorCodeOperationCancelled];
});

context(@"fetching products information", ^{
  __block NSError *fetchError;
  __block NSSet<NSString *> *products;
  __block NSDictionary<NSString *, BZRProduct *> *productsInfo;
  __block SPXFetchProductsCompletionBlock completionBlock;
  __block BOOL completionBlockInvoked;
  __block NSDictionary<NSString *, BZRProduct *> *completionBlockProductsInfo;
  __block NSError *completionBlockError;

  beforeEach(^{
    fetchError = [NSError lt_errorWithCode:BZRErrorCodeProductsMetadataFetchingFailed];
    products = @[@"foo", @"bar"].lt_set;
    productsInfo = @{
      @"foo": OCMClassMock([BZRProduct class]),
      @"bar": OCMClassMock([BZRProduct class])
    };

    completionBlockInvoked = NO;
    completionBlockProductsInfo = nil;
    completionBlockError = nil;
    completionBlock = ^(NSDictionary<NSString *, BZRProduct *> * _Nullable productsInfo,
                        NSError * _Nullable error) {
      completionBlockInvoked = YES;
      completionBlockProductsInfo = productsInfo;
      completionBlockError = error;
    };
  });

  it(@"should present an alert if fetch failed", ^{
    OCMStub([productsManager fetchProductsInfo:products]).andReturn([RACSignal error:fetchError]);
    OCMExpect([delegate presentAlertWithViewModel:OCMOCK_ANY]);

    [subscriptionManager fetchProductsInfo:products completionHandler:completionBlock];

    OCMVerifyAll((id)delegate);
  });

  it(@"should invoke the completion block with error immediately if no delegate is set", ^{
    OCMStub([productsManager fetchProductsInfo:products]).andReturn([RACSignal error:fetchError]);
    subscriptionManager.delegate = nil;

    [subscriptionManager fetchProductsInfo:products completionHandler:completionBlock];

    expect(completionBlockInvoked).will.beTruthy();
    expect(completionBlockProductsInfo).to.beNil();
    expect(completionBlockError).to.equal(fetchError);
  });

  it(@"should invoke the completion block with result if fetch succeeded", ^{
    OCMStub([productsManager fetchProductsInfo:products])
        .andReturn([RACSignal return:productsInfo]);

    [subscriptionManager fetchProductsInfo:products completionHandler:completionBlock];

    expect(completionBlockInvoked).will.beTruthy();
    expect(completionBlockProductsInfo).to.equal(productsInfo);
    expect(completionBlockError).to.beNil();
  });

  context(@"fetch failed alert", ^{
    __block id<SPXAlertViewModel> viewModel;

    beforeEach(^{
      viewModel = nil;

      OCMStub([delegate presentAlertWithViewModel:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<SPXAlertViewModel> unsafeViewModel;
        [invocation getArgument:&unsafeViewModel atIndex:2];
        viewModel = unsafeViewModel;
      });

      // This expectation is not for verification, it's a replacement for OCMStub since we stub
      // this method again with a different return value in the tests.
      OCMExpect([productsManager fetchProductsInfo:products])
          .andReturn([RACSignal error:fetchError]);
      [subscriptionManager fetchProductsInfo:products completionHandler:completionBlock];
    });

    context(@"try again button is pressed", ^{
      it(@"should try the operation again", ^{
        OCMExpect([productsManager fetchProductsInfo:products]).andReturn([RACSignal empty]);

        viewModel.buttons[0].action();

        OCMVerifyAll((id)productsManager);
        expect(completionBlockInvoked).to.beFalsy();
      });

      it(@"should invoke the completion block with result after successful retry", ^{
        OCMExpect([productsManager fetchProductsInfo:products])
            .andReturn([RACSignal return:productsInfo]);

        viewModel.buttons[0].action();

        OCMVerifyAll((id)productsManager);
        expect(completionBlockInvoked).will.beTruthy();
        expect(completionBlockProductsInfo).to.equal(productsInfo);
        expect(completionBlockError).to.beNil();
      });

      it(@"should keep trying again as long as the operation fails and try again is pressed", ^{
        OCMExpect([productsManager fetchProductsInfo:products])
            .andReturn([RACSignal error:fetchError]);
        viewModel.buttons[0].action();
        expect(completionBlockInvoked).to.beFalsy();

        OCMExpect([productsManager fetchProductsInfo:products])
            .andReturn([RACSignal return:productsInfo]);

        viewModel.buttons[0].action();

        OCMVerifyAll((id)productsManager);
        expect(completionBlockInvoked).will.beTruthy();
        expect(completionBlockProductsInfo).to.equal(productsInfo);
        expect(completionBlockError).to.beNil();
      });
    });

    context(@"contact us button is pressed", ^{
      it(@"should present mail composer", ^{
        OCMExpect([delegate presentFeedbackMailComposerWithCompletionHandler:OCMOCK_ANY]);

        viewModel.buttons[1].action();

        OCMVerifyAll((id)delegate);
      });

      it(@"should invoke the completion block with error when mail composer is dismissed", ^{
        OCMExpect([delegate presentFeedbackMailComposerWithCompletionHandler:[OCMArg invokeBlock]]);

        viewModel.buttons[1].action();

        OCMVerifyAll((id)delegate);
        expect(completionBlockInvoked).will.beTruthy();
        expect(completionBlockProductsInfo).to.beNil();
        expect(completionBlockError).to.equal(fetchError);
      });

      it(@"should invoke the completion block with error if no delegate is set", ^{
        subscriptionManager.delegate = nil;

        viewModel.buttons[1].action();

        expect(completionBlockInvoked).will.beTruthy();
        expect(completionBlockProductsInfo).to.beNil();
        expect(completionBlockError).to.equal(fetchError);
      });
    });

    context(@"not now button is pressed", ^{
      it(@"should invoke completion block with error", ^{
        viewModel.buttons[2].action();

        expect(completionBlockInvoked).will.equal(YES);
        expect(completionBlockProductsInfo).to.beNil();
        expect(completionBlockError).to.equal(fetchError);
      });
    });
  });
});

context(@"purchasing subscription", ^{
  __block NSError *purchaseError;
  __block NSError *purchaseErrorWithUnderlyingValidationError;
  __block SPXPurchaseSubscriptionCompletionBlock completionBlock;
  __block BOOL completionBlockInvoked;
  __block BZRReceiptSubscriptionInfo *completionBlockSubscriptionInfo;
  __block NSError *completionBlockError;

  beforeEach(^{
    purchaseError = [NSError lt_errorWithCode:BZRErrorCodePurchaseFailed];
    purchaseErrorWithUnderlyingValidationError =
        [NSError lt_errorWithCode:BZRErrorCodePurchaseFailed
                  underlyingError:[NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed]];

    completionBlockInvoked = NO;
    completionBlockSubscriptionInfo = nil;
    completionBlockError = nil;
    completionBlock =
        ^(BZRReceiptSubscriptionInfo * _Nullable subscriptionInfo, NSError * _Nullable error) {
          completionBlockInvoked = YES;
          completionBlockSubscriptionInfo = subscriptionInfo;
          completionBlockError = error;
        };
  });

  it(@"should present an alert if purchase failed", ^{
    OCMStub([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal error:purchaseError]);
    OCMExpect([delegate presentAlertWithViewModel:OCMOCK_ANY]);

    [subscriptionManager purchaseSubscription:@"foo" completionHandler:completionBlock];

    OCMVerifyAll((id)delegate);
    expect(completionBlockInvoked).to.beFalsy();
  });

  it(@"should invoke completion block with error immediately if purchase failed and no delegate is "
     "set", ^{
    OCMStub([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal error:purchaseError]);
    subscriptionManager.delegate = nil;

    [subscriptionManager purchaseSubscription:@"foo" completionHandler:completionBlock];

    expect(completionBlockInvoked).will.beTruthy();
    expect(completionBlockSubscriptionInfo).to.beNil();
    expect(completionBlockError).to.equal(purchaseError);
  });

  it(@"should present an alert if receipt validation failed", ^{
    OCMStub([productsManager purchaseProduct:@"foo"])
        .andReturn([RACSignal error:purchaseErrorWithUnderlyingValidationError]);
    OCMExpect([delegate presentAlertWithViewModel:OCMOCK_ANY]);

    [subscriptionManager purchaseSubscription:@"foo" completionHandler:completionBlock];

    OCMVerifyAll((id)delegate);
    expect(completionBlockInvoked).to.beFalsy();
  });

  it(@"should invoke completion block with error immediately if receipt validation has failed and "
     "no delegate is set", ^{
    OCMStub([productsManager purchaseProduct:@"foo"])
        .andReturn([RACSignal error:purchaseErrorWithUnderlyingValidationError]);
    subscriptionManager.delegate = nil;

    [subscriptionManager purchaseSubscription:@"foo" completionHandler:completionBlock];

    expect(completionBlockInvoked).will.beTruthy();
    expect(completionBlockSubscriptionInfo).to.beNil();
    expect(completionBlockError).to.equal(purchaseErrorWithUnderlyingValidationError);
  });

  it(@"should invoke the completion block with error immediately and not present an alert if "
     "operation was cancelled", ^{
    OCMStub([productsManager purchaseProduct:@"foo"])
        .andReturn([RACSignal error:cancellationError]);
    OCMReject([delegate presentAlertWithViewModel:OCMOCK_ANY]);

    [subscriptionManager purchaseSubscription:@"foo" completionHandler:completionBlock];

    expect(completionBlockInvoked).will.beTruthy();
    expect(completionBlockSubscriptionInfo).to.beNil();
    expect(completionBlockError).to.equal(cancellationError);
  });

  it(@"should invoke the completion block with error immediately and not present an alert if "
     "operation is not allowed", ^{
       auto notAllowedError = [NSError lt_errorWithCode:BZRErrorCodePurchaseNotAllowed];
       OCMStub([productsManager purchaseProduct:@"foo"])
           .andReturn([RACSignal error:notAllowedError]);
       OCMReject([delegate presentAlertWithViewModel:OCMOCK_ANY]);

       [subscriptionManager purchaseSubscription:@"foo" completionHandler:completionBlock];

       expect(completionBlockInvoked).will.beTruthy();
       expect(completionBlockSubscriptionInfo).to.beNil();
       expect(completionBlockError).to.equal(notAllowedError);
     });

  it(@"should invoke the completion block with result if purchase succeeded", ^{
    OCMStub([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal empty]);
    BZRReceiptSubscriptionInfo *subscriptionInfo = OCMClassMock([BZRReceiptSubscriptionInfo class]);
    OCMStub([productsInfoProvider subscriptionInfo]).andReturn(subscriptionInfo);

    [subscriptionManager purchaseSubscription:@"foo" completionHandler:completionBlock];

    expect(completionBlockInvoked).will.beTruthy();
    expect(completionBlockSubscriptionInfo).to.equal(subscriptionInfo);
    expect(completionBlockError).to.beNil();
  });

  context(@"purchase failed alert", ^{
    __block NSError *purchaseError;
    __block BZRReceiptSubscriptionInfo *subscriptionInfo;
    __block id<SPXAlertViewModel> viewModel;

    beforeEach(^{
      subscriptionInfo = OCMClassMock([BZRReceiptSubscriptionInfo class]);

      OCMStub([delegate presentAlertWithViewModel:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<SPXAlertViewModel> unsafeViewModel;
        [invocation getArgument:&unsafeViewModel atIndex:2];
        viewModel = unsafeViewModel;
      });

      // This expectation is not for verification, it's a replacement for OCMStub since we stub
      // this method again with a different return value in the tests.
      OCMExpect([productsManager purchaseProduct:@"foo"])
          .andReturn([RACSignal error:purchaseError]);
      OCMStub([productsInfoProvider subscriptionInfo]).andReturn(subscriptionInfo);

      [subscriptionManager purchaseSubscription:@"foo" completionHandler:
       ^(BZRReceiptSubscriptionInfo * _Nullable subscriptionInfo, NSError * _Nullable error) {
         completionBlockInvoked = YES;
         completionBlockSubscriptionInfo = subscriptionInfo;
         completionBlockError = error;
      }];
    });

    context(@"try again button is pressed", ^{
      it(@"should try the operation again", ^{
        OCMExpect([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal never]);

        viewModel.buttons[0].action();

        OCMVerifyAll((id)productsManager);
        expect(completionBlockInvoked).to.beFalsy();
      });

      it(@"should invoke the completion block with result after successful retry", ^{
        OCMExpect([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal empty]);

        viewModel.buttons[0].action();

        OCMVerifyAll((id)productsManager);
        expect(completionBlockInvoked).will.beTruthy();
        expect(completionBlockSubscriptionInfo).to.equal(subscriptionInfo);
        expect(completionBlockError).to.beNil();
      });

      it(@"should keep retrying as long as the operation fails and try again is pressed", ^{
        OCMExpect([productsManager purchaseProduct:@"foo"])
            .andReturn([RACSignal error:purchaseError]);
        viewModel.buttons[0].action();
        expect(completionBlockInvoked).to.beFalsy();

        OCMExpect([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal empty]);

        viewModel.buttons[0].action();

        OCMVerifyAll((id)productsManager);
        expect(completionBlockInvoked).will.beTruthy();
        expect(completionBlockSubscriptionInfo).to.equal(subscriptionInfo);
        expect(completionBlockError).to.beNil();
      });

      it(@"should retry to validate the receipt if the receipt validation phase has failed", ^{
        // Retry the purchase, but this time simulate receipt validation failure.
        OCMExpect([productsManager purchaseProduct:@"foo"])
            .andReturn([RACSignal error:purchaseErrorWithUnderlyingValidationError]);
        viewModel.buttons[0].action();

        // Retry should only execute receipt validation this time.
        OCMExpect([productsManager validateReceipt]).andReturn([RACSignal never]);
        OCMReject([productsManager purchaseProduct:OCMOCK_ANY]);
        viewModel.buttons[0].action();

        OCMVerifyAll((id)productsManager);
        expect(completionBlockInvoked).to.beFalsy();
      });

      it(@"should retry to validate the transaction if the transaction was not found while "
          "validating the receipt", ^{
        SKPaymentTransaction *transaction = OCMClassMock(SKPaymentTransaction.class);
        auto transactionIdentifier = @"transactionId";
        OCMStub([transaction transactionIdentifier]).andReturn(transactionIdentifier);
        auto transactionNotFoundInReceiptError =
            [NSError bzr_errorWithCode:BZRErrorCodeTransactionNotFoundInReceipt
                           transaction:transaction];
        auto errorWithTransactionNotFoundUnderlyingError =
            [NSError lt_errorWithCode:BZRErrorCodePurchaseFailed
                      underlyingError:transactionNotFoundInReceiptError];

        // Should retry validating the transaction both in the case of a nested error (such as
        // those sent by the \c purchaseProduct: method) and not nested errors ones (sent by
        // the \c validateTransaction: method).
        OCMExpect([productsManager purchaseProduct:@"foo"])
            .andReturn([RACSignal error:errorWithTransactionNotFoundUnderlyingError]);
        viewModel.buttons[0].action();

        OCMExpect([productsManager validateTransaction:transactionIdentifier])
            .andReturn([RACSignal error:transactionNotFoundInReceiptError]);
        viewModel.buttons[0].action();

        OCMExpect([productsManager validateTransaction:transactionIdentifier])
            .andReturn([RACSignal return:@[transaction]]);
        viewModel.buttons[0].action();

        expect(completionBlockInvoked).to.beTruthy();
        OCMVerifyAll((id)productsManager);
      });
    });

    context(@"contact us button is pressed", ^{
      it(@"should present mail composer", ^{
        OCMExpect([delegate presentFeedbackMailComposerWithCompletionHandler:OCMOCK_ANY]);

        viewModel.buttons[1].action();

        OCMVerifyAll((id)delegate);
      });

      it(@"should invoke the completion block with error when mail composer is dismissed", ^{
        OCMExpect([delegate presentFeedbackMailComposerWithCompletionHandler:[OCMArg invokeBlock]]);

        viewModel.buttons[1].action();

        OCMVerifyAll((id)delegate);
        expect(completionBlockInvoked).will.beTruthy();
        expect(completionBlockSubscriptionInfo).to.beNil();
        expect(completionBlockError).to.equal(purchaseError);
      });

      it(@"should invoke the completion block with error if no delegate is set", ^{
        subscriptionManager.delegate = nil;

        viewModel.buttons[1].action();

        expect(completionBlockInvoked).will.beTruthy();
        expect(completionBlockSubscriptionInfo).to.beNil();
        expect(completionBlockError).to.equal(purchaseError);
      });
    });

    context(@"not now button is pressed", ^{
      it(@"should invoke completion block with error", ^{
        viewModel.buttons[2].action();

        expect(completionBlockInvoked).will.equal(YES);
        expect(completionBlockSubscriptionInfo).will.beNil();
        expect(completionBlockError).will.equal(purchaseError);
      });
    });
  });
});

context(@"restore purchases", ^{
  __block NSError *restorationError;
  __block SPXRestorationCompletionBlock completionBlock;
  __block BOOL completionBlockInvoked;
  __block BZRReceiptInfo *completionBlockReceiptInfo;
  __block NSError *completionBlockError;

  __block BZRReceiptValidationStatus *receiptValidationStatus;
  __block BZRReceiptInfo *receiptInfo;
  __block BZRReceiptSubscriptionInfo *subscriptionInfo;

  beforeEach(^{
    restorationError = [NSError lt_errorWithCode:BZRErrorCodeReceiptRefreshFailed];
    completionBlockInvoked = NO;
    completionBlockReceiptInfo = nil;
    completionBlockError = nil;
    completionBlock =
    ^(BZRReceiptInfo * _Nullable receiptInfo, NSError * _Nullable error) {
      completionBlockInvoked = YES;
      completionBlockReceiptInfo = receiptInfo;
      completionBlockError = error;
    };

    receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
    receiptInfo = OCMClassMock([BZRReceiptInfo class]);
    subscriptionInfo = OCMClassMock([BZRReceiptSubscriptionInfo class]);
    OCMStub([receiptInfo subscription]).andReturn(subscriptionInfo);
    OCMStub([receiptValidationStatus receipt]).andReturn(receiptInfo);
    OCMStub([productsInfoProvider receiptValidationStatus]).andReturn(receiptValidationStatus);
    OCMStub([productsInfoProvider subscriptionInfo]).andReturn(subscriptionInfo);
  });

  it(@"should present failure alert if restoration failed", ^{
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal error:restorationError]);
    OCMExpect([delegate presentAlertWithViewModel:OCMOCK_ANY]);

    [subscriptionManager restorePurchasesWithCompletionHandler:completionBlock];

    OCMVerifyAll((id)delegate);
    expect(completionBlockInvoked).to.beFalsy();
  });

  it(@"should invoke completion block with error immediately if restoration failed and no delegate "
     "is set", ^{
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal error:restorationError]);
    subscriptionManager.delegate = nil;

    [subscriptionManager restorePurchasesWithCompletionHandler:completionBlock];

    expect(completionBlockInvoked).will.beTruthy();
    expect(completionBlockReceiptInfo).to.beNil();
    expect(completionBlockError).to.equal(restorationError);
  });

  it(@"should invoke the completion block with error immediately and not present an alert if "
     "operation was cancelled", ^{
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal error:cancellationError]);
    OCMReject([delegate presentAlertWithViewModel:OCMOCK_ANY]);

    [subscriptionManager restorePurchasesWithCompletionHandler:completionBlock];

    expect(completionBlockInvoked).will.beTruthy();
    expect(completionBlockReceiptInfo).to.beNil();
    expect(completionBlockError).to.equal(cancellationError);
  });

  it(@"should present success alert if restoration succeeded and active subscription was found", ^{
    OCMExpect([delegate presentAlertWithViewModel:
               [OCMArg checkWithBlock:^BOOL(id<SPXAlertViewModel> viewModel) {
      return viewModel.buttons.count == 1 &&
          [viewModel.message isEqualToString:@"Your subscription was restored successfully"];
    }]]);
    OCMStub([subscriptionInfo isExpired]).andReturn(NO);
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal empty]);

    [subscriptionManager restorePurchasesWithCompletionHandler:completionBlock];

    OCMVerifyAll((id)delegate);
    expect(completionBlockInvoked).to.beFalsy();
  });

  it(@"should present success alert if restoration succeeded and and no subscription found", ^{
    OCMExpect([delegate presentAlertWithViewModel:
               [OCMArg checkWithBlock:^BOOL(id<SPXAlertViewModel> viewModel) {
      return viewModel.buttons.count == 1 &&
          [viewModel.message isEqualToString:
           @"Your purchases were restored successfully, no active subscription found"];
    }]]);
    OCMStub([subscriptionInfo isExpired]).andReturn(YES);
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal empty]);

    [subscriptionManager restorePurchasesWithCompletionHandler:completionBlock];

    OCMVerifyAll((id)delegate);
    expect(completionBlockInvoked).to.beFalsy();
  });

  it(@"should invoke completion block with result immediately if restoration succeeded and no "
     "delegate is set", ^{
    subscriptionManager.delegate = nil;
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal empty]);

    [subscriptionManager restorePurchasesWithCompletionHandler:completionBlock];

    expect(completionBlockInvoked).will.beTruthy();
    expect(completionBlockReceiptInfo).to.equal(receiptInfo);
    expect(completionBlockError).to.beNil();
  });

  it(@"should invoke completion block with result after alert is dismissed if restoration "
     "succeeded", ^{
    OCMExpect([delegate presentAlertWithViewModel:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
      __unsafe_unretained id<SPXAlertViewModel> viewModel;
      [invocation getArgument:&viewModel atIndex:2];
      viewModel.buttons[0].action();
    });

    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal empty]);
    [subscriptionManager restorePurchasesWithCompletionHandler:completionBlock];

    expect(completionBlockInvoked).will.beTruthy();
    expect(completionBlockReceiptInfo).to.equal(receiptInfo);
    expect(completionBlockError).to.beNil();
  });

  context(@"restoration failed alert", ^{
    __block id<SPXAlertViewModel> viewModel;

    beforeEach(^{
      OCMStub([delegate presentAlertWithViewModel:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<SPXAlertViewModel> unsafeViewModel;
        [invocation getArgument:&unsafeViewModel atIndex:2];
        viewModel = unsafeViewModel;
      });

      // This expectation is not for verification, it's a replacement for OCMStub since we stub
      // this method again with a different return value in the tests.
      OCMExpect([productsManager refreshReceipt]).andReturn([RACSignal error:restorationError]);
      [subscriptionManager restorePurchasesWithCompletionHandler:completionBlock];
    });

    context(@"try again button is pressed", ^{
      it(@"should try the operation again", ^{
        OCMExpect([productsManager refreshReceipt]).andReturn([RACSignal never]);

        viewModel.buttons[0].action();

        OCMVerifyAll((id)productsManager);
        expect(completionBlockInvoked).to.beFalsy();
      });

      it(@"should invoke the completion block with result after successful retry", ^{
        subscriptionManager.delegate = nil;
        OCMExpect([productsManager refreshReceipt]).andReturn([RACSignal empty]);

        viewModel.buttons[0].action();

        OCMVerifyAll((id)productsManager);
        expect(completionBlockInvoked).will.beTruthy();
        expect(completionBlockReceiptInfo).to.equal(receiptInfo);
        expect(completionBlockError).to.beNil();
      });

      it(@"should keep trying again as long as the operation fails and try again is pressed", ^{
        OCMExpect([productsManager refreshReceipt]).andReturn([RACSignal error:restorationError]);
        viewModel.buttons[0].action();
        expect(completionBlockInvoked).to.beFalsy();

        subscriptionManager.delegate = nil;
        OCMExpect([productsManager refreshReceipt]).andReturn([RACSignal empty]);

        viewModel.buttons[0].action();

        OCMVerifyAll((id)productsManager);
        expect(completionBlockInvoked).will.beTruthy();
        expect(completionBlockReceiptInfo).to.equal(receiptInfo);
        expect(completionBlockError).to.beNil();
      });
    });

    context(@"contact us button is pressed", ^{
      it(@"should present mail composer", ^{
        OCMExpect([delegate presentFeedbackMailComposerWithCompletionHandler:OCMOCK_ANY]);

        viewModel.buttons[1].action();

        OCMVerifyAll((id)delegate);
      });

      it(@"should invoke the completion block with error when mail composer is dismissed", ^{
        OCMExpect([delegate presentFeedbackMailComposerWithCompletionHandler:[OCMArg invokeBlock]]);

        viewModel.buttons[1].action();

        OCMVerifyAll((id)delegate);
        expect(completionBlockInvoked).will.beTruthy();
        expect(completionBlockReceiptInfo).to.beNil();
        expect(completionBlockError).to.equal(restorationError);
      });

      it(@"should invoke the completion block with error if no delegate is set", ^{
        subscriptionManager.delegate = nil;

        viewModel.buttons[1].action();

        expect(completionBlockInvoked).will.beTruthy();
        expect(completionBlockReceiptInfo).to.beNil();
        expect(completionBlockError).to.equal(restorationError);
      });
    });

    context(@"not now button is pressed", ^{
      it(@"should invoke completion block with error", ^{
        viewModel.buttons[2].action();

        expect(completionBlockInvoked).will.equal(YES);
        expect(completionBlockReceiptInfo).to.beNil();
        expect(completionBlockError).to.equal(restorationError);
      });
    });
  });
});

SpecEnd
