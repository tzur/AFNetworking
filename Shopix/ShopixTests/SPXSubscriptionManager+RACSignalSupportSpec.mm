// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SPXSubscriptionManager+RACSignalSupport.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductsInfoProvider.h>
#import <Bazaar/BZRProductsManager.h>
#import <Bazaar/BZRReceiptModel.h>
#import <Bazaar/NSErrorCodes+Bazaar.h>

SpecBegin(SPXSubscriptionManager_RACSignalSupport)

__block id<BZRProductsInfoProvider> productsInfoProvider;
__block id<BZRProductsManager> productsManager;
__block SPXSubscriptionManager *manager;

beforeEach(^{
  productsInfoProvider = OCMProtocolMock(@protocol(BZRProductsInfoProvider));
  productsManager = OCMProtocolMock(@protocol(BZRProductsManager));
  manager = [[SPXSubscriptionManager alloc] initWithProductsInfoProvider:productsInfoProvider
                                                         productsManager:productsManager];
  manager = OCMPartialMock(manager);
});

context(@"fetching products info", ^{
  __block NSSet<NSString *> *productIdentifiers;

  beforeEach(^{
    productIdentifiers = @[@"foo"].lt_set;
  });

  it(@"should err if completion block invoked with error", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMExpect([manager fetchProductsInfo:productIdentifiers
                       completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null], error, nil])]);

    auto recorder = [[manager fetchProductsInfo:productIdentifiers] testRecorder];

    OCMVerifyAll(manager);
    expect(recorder).will.sendError(error);
  });

  it(@"should deliver products info if completion block invoked with products info", ^{
    NSDictionary<NSString *, BZRProduct *> *productsInfo = @{
      @"foo": OCMClassMock([BZRProduct class])
    };
    OCMExpect([manager fetchProductsInfo:productIdentifiers completionHandler:
               ([OCMArg invokeBlockWithArgs:productsInfo, [NSNull null], nil])]);

    auto recorder = [[manager fetchProductsInfo:productIdentifiers] testRecorder];

    OCMVerifyAll(manager);
    expect(recorder).will.complete();
    expect(recorder).to.sendValues(@[productsInfo]);
  });

  it(@"should complete without sending value if products info was not provided", ^{
    OCMExpect([manager fetchProductsInfo:productIdentifiers completionHandler:
               ([OCMArg invokeBlockWithArgs:[NSNull null], [NSNull null], nil])]);

    auto recorder = [[manager fetchProductsInfo:productIdentifiers] testRecorder];

    OCMVerifyAll(manager);
    expect(recorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });
});

context(@"purchasing subscription product", ^{
  it(@"should err if completion block invoked with error", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMExpect([manager purchaseSubscription:@"foo" completionHandler:
               ([OCMArg invokeBlockWithArgs:[NSNull null], error, nil])]);

    auto recorder = [[manager purchaseSubscription:@"foo"] testRecorder];

    OCMVerifyAll(manager);
    expect(recorder).will.sendError(error);
  });

  it(@"should deliver subscription info if completion block invoked with subscription info", ^{
    BZRReceiptSubscriptionInfo *subscriptionInfo = OCMClassMock([BZRReceiptSubscriptionInfo class]);
    OCMExpect([manager purchaseSubscription:@"foo" completionHandler:
               ([OCMArg invokeBlockWithArgs:subscriptionInfo, [NSNull null], nil])]);

    auto recorder = [[manager purchaseSubscription:@"foo"] testRecorder];

    OCMVerifyAll(manager);
    expect(recorder).will.complete();
    expect(recorder).to.sendValues(@[subscriptionInfo]);
  });

  it(@"should complete without sending value if error indicates cancellation", ^{
    auto error = [NSError lt_errorWithCode:BZRErrorCodeOperationCancelled];
    OCMExpect([manager purchaseSubscription:@"foo" completionHandler:
               ([OCMArg invokeBlockWithArgs:[NSNull null], error, nil])]);

    auto recorder = [[manager purchaseSubscription:@"foo"] testRecorder];

    OCMVerifyAll(manager);
    expect(recorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should complete without sending value if error indicates not allowed purchase", ^{
    auto error = [NSError lt_errorWithCode:BZRErrorCodePurchaseNotAllowed];
    OCMExpect([manager purchaseSubscription:@"foo" completionHandler:
               ([OCMArg invokeBlockWithArgs:[NSNull null], error, nil])]);

    auto recorder = [[manager purchaseSubscription:@"foo"] testRecorder];

    OCMVerifyAll(manager);
    expect(recorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should complete without sending value if subscription info was not provided", ^{
    OCMExpect([manager purchaseSubscription:@"foo" completionHandler:
               ([OCMArg invokeBlockWithArgs:[NSNull null], [NSNull null], nil])]);

    auto recorder = [[manager purchaseSubscription:@"foo"] testRecorder];

    OCMVerifyAll(manager);
    expect(recorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });
});

context(@"restoring purchases", ^{
  it(@"should err if completion block invoked with error", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMExpect([manager restorePurchasesWithCompletionHandler:
               ([OCMArg invokeBlockWithArgs:[NSNull null], error, nil])]);

    auto recorder = [[manager restorePurchases] testRecorder];

    OCMVerifyAll(manager);
    expect(recorder).will.sendError(error);
  });

  it(@"should deliver receipt info if completion block invoked with receipt info", ^{
    BZRReceiptInfo *receiptInfo = OCMClassMock([BZRReceiptInfo class]);
    OCMExpect([manager restorePurchasesWithCompletionHandler:
               ([OCMArg invokeBlockWithArgs:receiptInfo, [NSNull null], nil])]);

    auto recorder = [[manager restorePurchases] testRecorder];

    OCMVerifyAll(manager);
    expect(recorder).will.complete();
    expect(recorder).to.sendValues(@[receiptInfo]);
  });

  it(@"should complete without sending value if error indicates cancellation", ^{
    auto error = [NSError lt_errorWithCode:BZRErrorCodeOperationCancelled];
    OCMExpect([manager restorePurchasesWithCompletionHandler:
               ([OCMArg invokeBlockWithArgs:[NSNull null], error, nil])]);

    auto recorder = [[manager restorePurchases] testRecorder];

    OCMVerifyAll(manager);
    expect(recorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should complete without sending value if receipt info was not provided", ^{
    OCMExpect([manager restorePurchasesWithCompletionHandler:
               ([OCMArg invokeBlockWithArgs:[NSNull null], [NSNull null], nil])]);

    auto recorder = [[manager restorePurchases] testRecorder];

    OCMVerifyAll(manager);
    expect(recorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });
});

context(@"delegate signals", ^{
  __block id<SPXSubscriptionManagerDelegate> delegate;

  beforeEach(^{
    delegate = OCMProtocolMock(@protocol(SPXSubscriptionManagerDelegate));
    manager.delegate = delegate;
  });

  context(@"alert requested signal", ^{
    it(@"should deliver value when delegate is requsted to present an alert", ^{
      id<SPXAlertViewModel> viewModel = OCMProtocolMock(@protocol(SPXAlertViewModel));

      auto recorder = [manager.alertRequested testRecorder];
      expect(recorder).to.sendValuesWithCount(0);

      [manager.delegate presentAlertWithViewModel:viewModel];

      expect(recorder).to.sendValues(@[viewModel]);
    });

    it(@"should complete when the manager is deallocated", ^{
      __weak SPXSubscriptionManager *weakManager;
      LLSignalTestRecorder *recorder;

      @autoreleasepool {
        auto manager = [[SPXSubscriptionManager alloc]
                        initWithProductsInfoProvider:productsInfoProvider
                        productsManager:productsManager];
        recorder = [[manager alertRequested] testRecorder];
        weakManager = manager;
      }

      expect(weakManager).to.beNil();
      expect(recorder).to.complete();
    });
  });

  context(@"feedback mail composer requested signal", ^{
    it(@"should deliver value when delegate is requsted to present an alert", ^{
      LTVoidBlock completionBlock = ^{};

      auto recorder = [manager.feedbackMailComposerRequested testRecorder];
      expect(recorder).to.sendValuesWithCount(0);

      [manager.delegate presentFeedbackMailComposerWithCompletionHandler:completionBlock];

      expect(recorder).to.sendValues(@[completionBlock]);
    });

    it(@"should complete when the manager is deallocated", ^{
      __weak SPXSubscriptionManager *weakManager;
      LLSignalTestRecorder *recorder;

      @autoreleasepool {
        auto manager = [[SPXSubscriptionManager alloc]
                        initWithProductsInfoProvider:productsInfoProvider
                        productsManager:productsManager];
        recorder = [[manager feedbackMailComposerRequested] testRecorder];
        weakManager = manager;
      }

      expect(weakManager).to.beNil();
      expect(recorder).to.complete();
    });
  });
});

SpecEnd
