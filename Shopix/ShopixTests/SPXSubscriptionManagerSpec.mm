// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionManager.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductsInfoProvider.h>
#import <Bazaar/BZRProductsManager.h>
#import <Bazaar/BZRReceiptModel.h>
#import <MessageUI/MessageUI.h>

#import "SPXFeedbackComposeViewControllerProvider.h"

/// Category for testing, exposes the alert method.
@interface SPXSubscriptionManager (ForTesting)

- (UIAlertAction *)alertButtonWithTitle:(NSString *)title
                                handler:(LTVoidBlock)handler;

@end

SpecBegin(SPXSubscriptionManager)

__block id<BZRProductsManager> productsManager;
__block id<BZRProductsInfoProvider> productsInfoProvider;
__block MFMailComposeViewController *mailComposeViewController;
__block UIViewController *viewController;
__block SPXSubscriptionManager *subscriptionManager;

beforeEach(^{
  productsManager = OCMProtocolMock(@protocol(BZRProductsManager));
  productsInfoProvider = OCMProtocolMock(@protocol(BZRProductsInfoProvider));
  mailComposeViewController = OCMClassMock([MFMailComposeViewController class]);
  id<SPXFeedbackComposeViewControllerProvider> mailComposerProvider =
      OCMProtocolMock(@protocol(SPXFeedbackComposeViewControllerProvider));
  OCMStub([mailComposerProvider feedbackComposeViewController])
      .andReturn(mailComposeViewController);
  viewController = OCMClassMock([UIViewController class]);
  OCMStub([productsInfoProvider productsJSONDictionary]).andReturn(@{
    @"foo": OCMClassMock([BZRProduct class])
  });
  subscriptionManager = [[SPXSubscriptionManager alloc]
                         initWithProductsInfoProvider:productsInfoProvider
                         productsManager:productsManager
                         mailComposeProvider:mailComposerProvider
                         viewController:viewController];
});

context(@"purchase subscription", ^{
  it(@"should present an alert if purchase subscription failed", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal error:error]);
    OCMExpect([viewController presentViewController:[OCMArg checkWithBlock:^BOOL(id obj) {
      return [obj isKindOfClass:[UIAlertController class]];
    }] animated:YES completion:nil]);

    [subscriptionManager purchaseSubscription:@"foo" completionHandler:^(BOOL) {}];

    OCMVerifyAll((id)viewController);
  });

  it(@"should invoke the completion block if purchase subscription succeeded" , ^{
    OCMStub([productsManager purchaseProduct:@"foo"]).andReturn([RACSignal empty]);
    [subscriptionManager purchaseSubscription:@"foo" completionHandler:^(BOOL success) {
      expect(success).will.beTruthy();
    }];
  });

  context(@"purchase failed alert", ^{
    __block NSDictionary *mappingButtonTitleToHandler;
    __block BOOL completionBlockInvoked;
    __block BOOL completionBlockSuccess;

    beforeEach(^{
      NSMutableDictionary *actionHandlers = [NSMutableDictionary dictionary];
      id subscriptionManagerMock = OCMPartialMock(subscriptionManager);
      OCMStub([subscriptionManagerMock alertButtonWithTitle:OCMOCK_ANY handler:OCMOCK_ANY])
          .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained NSString *title;
            [invocation getArgument:&title atIndex:2];
            __unsafe_unretained LTVoidBlock handler;
            [invocation getArgument:&handler atIndex:3];
            actionHandlers[title] = handler;
          }).andForwardToRealObject();
      OCMExpect([productsManager purchaseProduct:@"foo"])
          .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
      [subscriptionManagerMock purchaseSubscription:@"foo" completionHandler:^(BOOL success) {
        completionBlockInvoked = YES;
        completionBlockSuccess = success;
      }];
      mappingButtonTitleToHandler = [actionHandlers copy];
    });

    it(@"should invoke purchase product when try again button is pressed", ^{
      OCMExpect([productsManager purchaseProduct:@"foo"]);

      LTVoidBlock handler = mappingButtonTitleToHandler[@"Try Again"];
      handler();

      OCMVerifyAll((id)productsManager);
    });

    it(@"should present mail composer when contact us button is pressed", ^{
      OCMExpect([viewController presentViewController:mailComposeViewController animated:YES
                                           completion:nil]);
      LTVoidBlock handler = mappingButtonTitleToHandler[@"Contact Us"];
      handler();

      OCMVerifyAll((id)viewController);
    });

    it(@"should invoke completion block with NO when not now button is pressed", ^{
      LTVoidBlock handler = mappingButtonTitleToHandler[@"Not Now"];
      handler();

      expect(completionBlockInvoked).will.equal(YES);
      expect(completionBlockSuccess).will.equal(NO);
    });
  });
});

context(@"restore purchases", ^{
  it(@"should present an alert if restore purchases failed", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal error:error]);
    OCMExpect([viewController presentViewController:[OCMArg checkWithBlock:^BOOL(id obj) {
      return [obj isKindOfClass:[UIAlertController class]];
    }] animated:YES completion:nil]);

    [subscriptionManager restorePurchasesWithCompletionHandler:^(BOOL) {}];

    OCMVerifyAll((id)viewController);
  });

    it(@"should present an alert if restore purchases succeeded and active subscription found", ^{
    OCMExpect([viewController presentViewController:
              [OCMArg checkWithBlock:^BOOL(UIViewController *presentedController) {
      return [presentedController isKindOfClass:[UIAlertController class]] &&
      [((UIAlertController *)presentedController).message
       isEqualToString:@"Your subscription was restored successfully"];
    }] animated:YES completion:nil]);

    BZRReceiptSubscriptionInfo *subscriptionInfo = OCMClassMock([BZRReceiptSubscriptionInfo class]);
    OCMStub([productsInfoProvider subscriptionInfo]).andReturn(subscriptionInfo);
    OCMStub([productsManager refreshReceipt]).andReturn([RACSignal empty]);

    [subscriptionManager restorePurchasesWithCompletionHandler:^(BOOL) {}];

    OCMVerifyAll((id)viewController);
  });

  it(@"should present an alert if restore purchases succeeded and no subscription found", ^{
    OCMExpect([viewController presentViewController:
              [OCMArg checkWithBlock:^BOOL(UIViewController *presentedController) {
      return [presentedController isKindOfClass:[UIAlertController class]] &&
      [((UIAlertController *)presentedController).message
       isEqualToString:@"Your purchases were restored successfully, no active subscription found"];
    }] animated:YES completion:nil]);
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

  context(@"restore purchases failed alert", ^{
    __block NSDictionary *mappingButtonTitleToHandler;
    __block BOOL completionBlockInvoked;
    __block BOOL completionBlockSuccess;

    beforeEach(^{
      NSMutableDictionary *actionHandlers = [NSMutableDictionary dictionary];
      id subscriptionManagerMock = OCMPartialMock(subscriptionManager);
      OCMStub([subscriptionManagerMock alertButtonWithTitle:OCMOCK_ANY handler:OCMOCK_ANY])
          .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained NSString *title;
            [invocation getArgument:&title atIndex:2];
            __unsafe_unretained LTVoidBlock handler;
            [invocation getArgument:&handler atIndex:3];
            actionHandlers[title] = handler;
          }).andForwardToRealObject();
      OCMExpect([productsManager refreshReceipt])
          .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
      [subscriptionManagerMock restorePurchasesWithCompletionHandler:^(BOOL success) {
        completionBlockInvoked = YES;
        completionBlockSuccess = success;
      }];
      mappingButtonTitleToHandler = [actionHandlers copy];
    });

    it(@"should invoke refresh receipt when try again button is pressed", ^{
      OCMExpect([productsManager refreshReceipt]);

      LTVoidBlock handler = mappingButtonTitleToHandler[@"Try Again"];
      handler();

      OCMVerifyAll((id)productsManager);
    });

    it(@"should present mail composer when contact us button is pressed", ^{
      OCMExpect([viewController presentViewController:mailComposeViewController animated:YES
                                           completion:nil]);
      LTVoidBlock handler = mappingButtonTitleToHandler[@"Contact Us"];
      handler();

      OCMVerifyAll((id)viewController);
    });

    it(@"should invoke completion block with NO when not now button is pressed", ^{
      LTVoidBlock handler = mappingButtonTitleToHandler[@"Not Now"];
      handler();

      expect(completionBlockInvoked).will.equal(YES);
      expect(completionBlockSuccess).will.equal(NO);
    });
  });
});

SpecEnd
