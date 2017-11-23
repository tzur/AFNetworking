// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionManager.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductsInfoProvider.h>
#import <Bazaar/BZRProductsManager.h>
#import <Bazaar/BZRReceiptModel.h>
#import <Bazaar/NSErrorCodes+Bazaar.h>
#import <MessageUI/MessageUI.h>

#import "SPXAlertViewControllerProvider.h"
#import "SPXAlertViewModel.h"
#import "SPXAlertViewModel+ShopixPresets.h"
#import "SPXFeedbackComposeViewControllerProvider.h"

SpecBegin(SPXSubscriptionManager)

__block id<BZRProductsManager> productsManager;
__block id<BZRProductsInfoProvider> productsInfoProvider;
__block MFMailComposeViewController *mailComposeViewController;
__block id<SPXFeedbackComposeViewControllerProvider> mailComposerProvider;
__block UIViewController *alertViewController;
__block id<SPXAlertViewControllerProvider> alertProvider;
__block UIViewController *viewController;
__block SPXSubscriptionManager *subscriptionManager;

beforeEach(^{
  productsManager = OCMProtocolMock(@protocol(BZRProductsManager));
  productsInfoProvider = OCMProtocolMock(@protocol(BZRProductsInfoProvider));
  mailComposeViewController = OCMClassMock([MFMailComposeViewController class]);
  mailComposerProvider = OCMProtocolMock(@protocol(SPXFeedbackComposeViewControllerProvider));
  alertViewController = OCMClassMock([UIViewController class]);
  alertProvider = OCMProtocolMock(@protocol(SPXAlertViewControllerProvider));
  OCMStub([mailComposerProvider feedbackComposeViewController])
      .andReturn(mailComposeViewController);
  viewController = OCMClassMock([UIViewController class]);
  OCMStub([productsInfoProvider productsJSONDictionary]).andReturn(@{
    @"foo": OCMClassMock([BZRProduct class])
  });
  subscriptionManager =
      [[SPXSubscriptionManager alloc] initWithProductsInfoProvider:productsInfoProvider
                                                   productsManager:productsManager
                                               mailComposeProvider:mailComposerProvider
                                                     alertProvider:alertProvider
                                                    viewController:viewController];
});

context(@"purchasing subscription", ^{
  it(@"should present an alert if purchase failed", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal error:error]);
    OCMStub([alertProvider alertViewControllerWithModel:OCMOCK_ANY]).andReturn(alertViewController);
    OCMExpect([viewController presentViewController:alertViewController animated:YES
                                         completion:nil]);

    [subscriptionManager purchaseSubscription:@"foo" completionHandler:^(BOOL) {}];

    OCMVerifyAll((id)viewController);
  });

  it(@"should not present an alert if purchae was cancelled", ^{
    auto error = [NSError lt_errorWithCode:BZRErrorCodeOperationCancelled];
    OCMStub([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal error:error]);
    OCMReject([viewController presentViewController:OCMOCK_ANY animated:YES completion:OCMOCK_ANY]);

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
      OCMStub([alertProvider alertViewControllerWithModel:OCMOCK_ANY])
          .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained id<SPXAlertViewModel> unsafeViewModel;
            [invocation getArgument:&unsafeViewModel atIndex:2];
            viewModel = unsafeViewModel;
          }).andReturn(alertViewController);
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
      OCMExpect([viewController presentViewController:mailComposeViewController animated:YES
                                           completion:nil]);

      viewModel.buttons[1].action();

      OCMVerifyAll((id)viewController);
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
    OCMStub([alertProvider alertViewControllerWithModel:[OCMArg checkWithBlock:^BOOL(id viewModel) {
      return [viewModel conformsToProtocol:@protocol(SPXAlertViewModel)] &&
          ((id<SPXAlertViewModel>)viewModel).buttons.count == 3;
    }]]).andReturn(alertViewController);
    OCMExpect([viewController presentViewController:alertViewController animated:YES
                                         completion:nil]);

    [subscriptionManager restorePurchasesWithCompletionHandler:^(BOOL) {}];

    OCMVerifyAll((id)viewController);
  });

  it(@"should present success alert if restoration succeeded and active subscription found", ^{
    OCMStub([alertProvider alertViewControllerWithModel:[OCMArg checkWithBlock:^BOOL(id viewModel) {
      return [viewModel conformsToProtocol:@protocol(SPXAlertViewModel)] &&
          ((id<SPXAlertViewModel>)viewModel).buttons.count == 1 &&
          [((id<SPXAlertViewModel>)viewModel).message isEqualToString:
           @"Your subscription was restored successfully"];
    }]]).andReturn(alertViewController);
    OCMExpect([viewController presentViewController:alertViewController animated:YES
                                         completion:nil]);

    BZRReceiptSubscriptionInfo *subscriptionInfo = OCMClassMock([BZRReceiptSubscriptionInfo class]);
    OCMStub([productsInfoProvider subscriptionInfo]).andReturn(subscriptionInfo);
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal empty]);

    [subscriptionManager restorePurchasesWithCompletionHandler:^(BOOL) {}];

    OCMVerifyAll((id)viewController);
  });

  it(@"should present an alert if restoration succeeded and no subscription found", ^{
    OCMStub([alertProvider alertViewControllerWithModel:[OCMArg checkWithBlock:^BOOL(id viewModel) {
      return [viewModel conformsToProtocol:@protocol(SPXAlertViewModel)] &&
          ((id<SPXAlertViewModel>)viewModel).buttons.count == 1 &&
          [((id<SPXAlertViewModel>)viewModel).message isEqualToString:
           @"Your purchases were restored successfully, no active subscription found"];
    }]]).andReturn(alertViewController);
    OCMExpect([viewController presentViewController:alertViewController animated:YES
                                         completion:nil]);
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal empty]);

    [subscriptionManager restorePurchasesWithCompletionHandler:^(BOOL) {}];

    OCMVerifyAll((id)viewController);
  });

  it(@"should invoke the completion block if restore purchases succeeded" , ^{
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
      OCMStub([alertProvider alertViewControllerWithModel:OCMOCK_ANY])
          .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained id<SPXAlertViewModel> unsafeViewModel;
            [invocation getArgument:&unsafeViewModel atIndex:2];
            viewModel = unsafeViewModel;
          }).andReturn(alertViewController);
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
      OCMExpect([viewController presentViewController:mailComposeViewController animated:YES
                                           completion:nil]);

      viewModel.buttons[1].action();

      OCMVerifyAll((id)viewController);
    });

    it(@"should invoke completion block with NO when not now button is pressed", ^{
      viewModel.buttons[2].action();

      expect(completionBlockInvoked).will.equal(YES);
      expect(completionBlockSuccess).will.equal(NO);
    });
  });
});

SpecEnd
