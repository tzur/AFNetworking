// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionManager.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductsInfoProvider.h>
#import <Bazaar/BZRProductsManager.h>
#import <Bazaar/BZRReceiptModel.h>
#import <Bazaar/NSErrorCodes+Bazaar.h>

#import "SPXAlertViewModel.h"

SpecBegin(SPXSubscriptionManager)

__block id<BZRProductsManager> productsManager;
__block id<BZRProductsInfoProvider> productsInfoProvider;
__block id<SPXSubscriptionManagerDelegate> delegate;
__block SPXSubscriptionManager *subscriptionManager;

beforeEach(^{
  productsManager = OCMProtocolMock(@protocol(BZRProductsManager));
  productsInfoProvider = OCMProtocolMock(@protocol(BZRProductsInfoProvider));
  OCMStub([productsInfoProvider productsJSONDictionary]).andReturn(@{
    @"foo": OCMClassMock([BZRProduct class])
  });
  delegate = OCMStrictProtocolMock(@protocol(SPXSubscriptionManagerDelegate));
  subscriptionManager =
      [[SPXSubscriptionManager alloc] initWithProductsInfoProvider:productsInfoProvider
                                                   productsManager:productsManager];
  subscriptionManager.delegate = delegate;
});

context(@"fetching products information", ^{
  it(@"should present an alert if fetch failed", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([productsManager fetchProductsInfo:[@[@"foo"] lt_set]])
        .andReturn([RACSignal error:error]);
    OCMExpect([delegate presentAlertWithViewModel:OCMOCK_ANY]);

    [subscriptionManager fetchProductsInfo:[@[@"foo"] lt_set]
                         completionHandler:^(NSDictionary *, NSError *) {}];

    OCMVerifyAll((id)delegate);
  });

  it(@"should invoke the completion block with error if fetch failed" , ^{
    auto expectedError = [NSError lt_errorWithCode:1337];
    OCMStub([productsManager fetchProductsInfo:[@[@"foo"] lt_set]])
        .andReturn([RACSignal error:expectedError]);
    OCMExpect([delegate presentAlertWithViewModel:OCMOCK_ANY]);

    [subscriptionManager fetchProductsInfo:[@[@"foo"] lt_set]
                         completionHandler:^(NSDictionary<NSString *, BZRProduct *> *products,
                                             NSError *error) {
      expect(products).will.beNil();
      expect(error).will.equal(expectedError);
    }];
  });

  it(@"should invoke the completion block with products if fetch succeeded" , ^{
    OCMStub([productsManager fetchProductsInfo:[@[@"foo"] lt_set]])
        .andReturn([RACSignal return:@{}]);

    [subscriptionManager fetchProductsInfo:[@[@"foo"] lt_set]
                         completionHandler:^(NSDictionary<NSString *, BZRProduct *> *products,
                                             NSError *error) {
      expect(products).willNot.beNil();
      expect(error).will.beNil();
    }];
  });

  context(@"fetch failed alert", ^{
    __block id<SPXAlertViewModel> viewModel;
    __block BOOL completionBlockInvoked;
    __block NSDictionary<NSString *, BZRProduct *> *completionBlockProducts;
    __block NSError *completionBlockError;

    beforeEach(^{
      OCMStub([delegate presentAlertWithViewModel:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<SPXAlertViewModel> unsafeViewModel;
        [invocation getArgument:&unsafeViewModel atIndex:2];
        viewModel = unsafeViewModel;
      });

      // This expectation is not for varifaction, it's a replacment for OCMStub since we stub
      // this method again with a different return value in the tests.
      OCMExpect([productsManager fetchProductsInfo:[@[@"foo"] lt_set]])
          .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
      [subscriptionManager fetchProductsInfo:[@[@"foo"] lt_set]
                           completionHandler:^(NSDictionary<NSString *, BZRProduct *> *products,
                                               NSError *error) {
             completionBlockInvoked = YES;
             completionBlockProducts = products;
             completionBlockError = error;
           }];
    });

    it(@"should invoke fetch products when try again button is pressed", ^{
      OCMExpect([productsManager fetchProductsInfo:@[@"foo"].lt_set]).andReturn([RACSignal empty]);

      viewModel.buttons[0].action();

      OCMVerifyAll((id)productsManager);
    });

    it(@"should present mail composer when contact us button is pressed", ^{
      OCMExpect([delegate presentFeedbackMailComposerWithCompletionHandler:OCMOCK_ANY]);

      viewModel.buttons[1].action();

      OCMVerifyAll((id)delegate);
    });

    it(@"should invoke completion block with error when not now button is pressed", ^{
      viewModel.buttons[2].action();

      expect(completionBlockInvoked).will.equal(YES);
      expect(completionBlockProducts).will.beNil();
      expect(completionBlockError).will.equal([NSError lt_errorWithCode:1337]);
    });
  });
});

context(@"purchasing subscription", ^{
  it(@"should present an alert if purchase failed", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal error:error]);
    OCMExpect([delegate presentAlertWithViewModel:OCMOCK_ANY]);

    [subscriptionManager purchaseSubscription:@"foo" completionHandler:^(BOOL) {}];

    OCMVerifyAll((id)delegate);
  });

  it(@"should not present an alert if purchae was cancelled", ^{
    auto error = [NSError lt_errorWithCode:BZRErrorCodeOperationCancelled];
    OCMStub([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal error:error]);

    [subscriptionManager purchaseSubscription:@"foo" completionHandler:^(BOOL) {}];
  });

  it(@"should invoke the completion block if purchase succeeded" , ^{
    OCMStub([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal empty]);
    [subscriptionManager purchaseSubscription:@"foo" completionHandler:^(BOOL success) {
      expect(success).will.beTruthy();
    }];
  });

  context(@"purchase failed alert", ^{
    __block id<SPXAlertViewModel> viewModel;
    __block BOOL completionBlockInvoked;
    __block BOOL completionBlockSuccess;

    beforeEach(^{
      OCMStub([delegate presentAlertWithViewModel:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<SPXAlertViewModel> unsafeViewModel;
        [invocation getArgument:&unsafeViewModel atIndex:2];
        viewModel = unsafeViewModel;
      });

      // This expectation is not for varifaction, it's a replacment for OCMStub since we stub
      // this method again with a different return value in the tests.
      OCMExpect([productsManager purchaseProduct:@"foo"])
          .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
      [subscriptionManager purchaseSubscription:@"foo" completionHandler:^(BOOL success) {
        completionBlockInvoked = YES;
        completionBlockSuccess = success;
      }];
    });

    it(@"should invoke refresh receipt when try again button is pressed", ^{
      OCMExpect([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal empty]);

      viewModel.buttons[0].action();

      OCMVerifyAll((id)productsManager);
    });

    it(@"should present mail composer when contact us button is pressed", ^{
      OCMExpect([delegate presentFeedbackMailComposerWithCompletionHandler:OCMOCK_ANY]);

      viewModel.buttons[1].action();

      OCMVerifyAll((id)delegate);
    });

    it(@"should invoke completion block with NO when not now button is pressed", ^{
      viewModel.buttons[2].action();

      expect(completionBlockInvoked).will.equal(YES);
      expect(completionBlockSuccess).will.equal(NO);
    });
  });
});

context(@"restore purchases", ^{
  it(@"should present failure alert if restoration failed", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal error:error]);
    OCMExpect([delegate presentAlertWithViewModel:OCMOCK_ANY]);

    [subscriptionManager restorePurchasesWithCompletionHandler:^(BOOL) {}];

    OCMVerifyAll((id)delegate);
  });

  it(@"should present success alert if restoration succeeded and active subscription found", ^{
    OCMExpect([delegate presentAlertWithViewModel:
               [OCMArg checkWithBlock:^BOOL(id<SPXAlertViewModel> viewModel) {
      return viewModel.buttons.count == 1 &&
          [viewModel.message isEqualToString:@"Your subscription was restored successfully"];
    }]]);

    BZRReceiptSubscriptionInfo *subscriptionInfo = OCMClassMock([BZRReceiptSubscriptionInfo class]);
    OCMStub([productsInfoProvider subscriptionInfo]).andReturn(subscriptionInfo);
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal empty]);

    [subscriptionManager restorePurchasesWithCompletionHandler:^(BOOL) {}];

    OCMVerifyAll((id)delegate);
  });

  it(@"should present an alert if restoration succeeded and no subscription found", ^{
    OCMExpect([delegate presentAlertWithViewModel:
               [OCMArg checkWithBlock:^BOOL(id<SPXAlertViewModel> viewModel) {
      return viewModel.buttons.count == 1 &&
          [viewModel.message isEqualToString:
           @"Your purchases were restored successfully, no active subscription found"];
    }]]);
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal empty]);

    [subscriptionManager restorePurchasesWithCompletionHandler:^(BOOL) {}];

    OCMVerifyAll((id)delegate);
  });

  it(@"should invoke the completion block if restore purchases succeeded" , ^{
    OCMExpect([delegate presentAlertWithViewModel:OCMOCK_ANY]);
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal empty]);
    [subscriptionManager restorePurchasesWithCompletionHandler:^(BOOL success) {
      expect(success).will.beTruthy();
    }];
  });

  context(@"restoration failed alert", ^{
    __block id<SPXAlertViewModel> viewModel;
    __block BOOL completionBlockInvoked;
    __block BOOL completionBlockSuccess;

    beforeEach(^{
      OCMStub([delegate presentAlertWithViewModel:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<SPXAlertViewModel> unsafeViewModel;
        [invocation getArgument:&unsafeViewModel atIndex:2];
        viewModel = unsafeViewModel;
      });

      // This expectation is not for varifaction, it's a replacment for OCMStub since we stub
      // this method again with a different return value in the tests.
      OCMExpect([productsManager refreshReceipt])
          .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
      [subscriptionManager restorePurchasesWithCompletionHandler:^(BOOL success) {
        completionBlockInvoked = YES;
        completionBlockSuccess = success;
      }];
    });

    it(@"should invoke refresh receipt when try again button is pressed", ^{
      OCMExpect([productsManager refreshReceipt]).andReturn([RACSignal empty]);

      viewModel.buttons[0].action();

      OCMVerifyAll((id)productsManager);
    });

    it(@"should present mail composer when contact us button is pressed", ^{
      OCMExpect([delegate presentFeedbackMailComposerWithCompletionHandler:OCMOCK_ANY]);

      viewModel.buttons[1].action();

      OCMVerifyAll((id)delegate);
    });

    it(@"should invoke completion block with NO when not now button is pressed", ^{
      viewModel.buttons[2].action();

      expect(completionBlockInvoked).will.equal(YES);
      expect(completionBlockSuccess).will.equal(NO);
    });
  });
});

SpecEnd
