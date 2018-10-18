// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionViewModel.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductPriceInfo.h>
#import <Bazaar/BZRProductsInfoProvider.h>
#import <Bazaar/BZRReceiptModel.h>
#import <Bazaar/BZRSubscriptionIntroductoryDiscount.h>
#import <Bazaar/NSErrorCodes+Bazaar.h>
#import <LTKit/NSArray+Functional.h>

#import "SPXAlertViewModel.h"
#import "SPXColorScheme.h"
#import "SPXPurchaseSubscriptionEvent.h"
#import "SPXRestorePurchasesButtonPressedEvent.h"
#import "SPXRestorePurchasesEvent.h"
#import "SPXSubscriptionButtonPressedEvent.h"
#import "SPXSubscriptionDescriptor.h"
#import "SPXSubscriptionManager.h"
#import "SPXSubscriptionTermsViewModel.h"
#import "SPXSubscriptionVideoPageViewModel.h"

SpecBegin(SPXSubscriptionViewModel)

__block SPXSubscriptionViewModel *viewModel;
__block SPXSubscriptionManager *subscriptionManager;
__block SPXSubscriptionTermsViewModel *termsViewModel;
__block SPXColorScheme *colorScheme;
__block NSArray<NSString *> *requestedProductIdentifiers;
__block NSArray<SPXSubscriptionDescriptor *> *descriptors;

beforeEach(^{
  id<BZRProductsInfoProvider> productsInfoProvider =
      OCMProtocolMock(@protocol(BZRProductsInfoProvider));
  subscriptionManager = OCMClassMock([SPXSubscriptionManager class]);
  termsViewModel = OCMClassMock([SPXSubscriptionTermsViewModel class]);
  colorScheme = OCMClassMock([SPXColorScheme class]);
  requestedProductIdentifiers = @[@"foo1", @"foo2"];
  auto pageViewModels = @[
      OCMProtocolMock(@protocol(SPXSubscriptionVideoPageViewModel)),
      OCMProtocolMock(@protocol(SPXSubscriptionVideoPageViewModel))
    ];

  descriptors = [requestedProductIdentifiers
      lt_map:^SPXSubscriptionDescriptor *(NSString *productIdentifier) {
        return [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:productIdentifier
                                                         discountPercentage:0
                                                       productsInfoProvider:productsInfoProvider];
      }];
  viewModel = [[SPXSubscriptionViewModel alloc] initWithSubscriptionDescriptors:descriptors
      preferredProductIndex:0 pageViewModels:pageViewModels termsViewModel:termsViewModel
      colorScheme:colorScheme subscriptionManager:subscriptionManager];
});

it(@"should raise if the preferred button index is greater than the number of buttons", ^{
  expect(^{
    viewModel = [[SPXSubscriptionViewModel alloc] initWithSubscriptionDescriptors:descriptors
    preferredProductIndex:@2 pageViewModels:@[] termsViewModel:termsViewModel
    colorScheme:colorScheme subscriptionManager:subscriptionManager];
  }).to.raise(NSInvalidArgumentException);
});

context(@"products fetching", ^{
  beforeEach(^{
    viewModel = [[SPXSubscriptionViewModel alloc] initWithSubscriptionDescriptors:descriptors
        preferredProductIndex:0 pageViewModels:@[] termsViewModel:termsViewModel
        colorScheme:colorScheme subscriptionManager:subscriptionManager];
  });

  it(@"should show the activity indicator when fetch has started", ^{
    [viewModel fetchProductsInfo];
    expect(viewModel.shouldShowActivityIndicator).to.beTruthy();
  });

  it(@"should hide the activity indicator when fetch has finished successfully", ^{
    OCMStub([subscriptionManager fetchProductsInfo:[requestedProductIdentifiers lt_set]
        completionHandler:([OCMArg invokeBlockWithArgs:@{}, [NSNull null], nil])]);

    [viewModel fetchProductsInfo];

    expect(viewModel.shouldShowActivityIndicator).to.beFalsy();
  });

  it(@"should request dismissal if failed to fetch products", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([subscriptionManager fetchProductsInfo:[requestedProductIdentifiers lt_set]
        completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null], error, nil])]);
    auto recorder = [viewModel.dismissRequested testRecorder];

    [viewModel fetchProductsInfo];

    expect(recorder).to.sendValues(@[[RACUnit defaultUnit]]);
  });

  it(@"should set the subscription descriptors prices when fetch is finished", ^{
    BZRProduct *product1 = OCMClassMock([BZRProduct class]);
    BZRProduct *product2 = OCMClassMock([BZRProduct class]);
    OCMStub([product1 priceInfo]).andReturn(OCMClassMock([BZRProductPriceInfo class]));
    OCMStub([product2 priceInfo]).andReturn(OCMClassMock([BZRProductPriceInfo class]));
    NSDictionary<NSString *, BZRProduct *> *returnedProducts = @{
      @"foo1": product1,
      @"foo2": product2
    };
    OCMStub([subscriptionManager fetchProductsInfo:[requestedProductIdentifiers lt_set]
        completionHandler:([OCMArg invokeBlockWithArgs:returnedProducts, [NSNull null], nil])]);

    [viewModel fetchProductsInfo];

    [viewModel.subscriptionDescriptors
     enumerateObjectsUsingBlock:^(SPXSubscriptionDescriptor *descriptor, NSUInteger index, BOOL *) {
       expect(descriptor.productIdentifier).to.equal(requestedProductIdentifiers[index]);
       expect(descriptor.priceInfo).to
          .equal(returnedProducts[descriptor.productIdentifier].priceInfo);
     }];
  });

  it(@"should set the subscription descriptors introductory discounts when fetch is finished", ^{
    BZRProduct *product1 = OCMClassMock([BZRProduct class]);
    BZRProduct *product2 = OCMClassMock([BZRProduct class]);
    OCMStub([product1 introductoryDiscount])
        .andReturn(OCMClassMock([BZRSubscriptionIntroductoryDiscount class]));
    OCMStub([product2 introductoryDiscount])
        .andReturn(OCMClassMock([BZRSubscriptionIntroductoryDiscount class]));
    NSDictionary<NSString *, BZRProduct *> *returnedProducts = @{
      @"foo1": product1,
      @"foo2": product2
    };
    OCMStub([subscriptionManager fetchProductsInfo:[requestedProductIdentifiers lt_set]
        completionHandler:([OCMArg invokeBlockWithArgs:returnedProducts, [NSNull null], nil])]);

    [viewModel fetchProductsInfo];

    [viewModel.subscriptionDescriptors
     enumerateObjectsUsingBlock:^(SPXSubscriptionDescriptor *descriptor, NSUInteger index, BOOL *) {
       expect(descriptor.productIdentifier).to.equal(requestedProductIdentifiers[index]);
       expect(descriptor.introductoryDiscount).to
          .equal(returnedProducts[descriptor.productIdentifier].introductoryDiscount);
     }];
  });
});

context(@"purchasing", ^{
  __block BZRReceiptSubscriptionInfo *subscriptionInformation;

  beforeEach(^{
    subscriptionInformation = OCMClassMock([BZRReceiptSubscriptionInfo class]);
  });

  it(@"should raise if the button index is greater than the number of buttons", ^{
    expect(^{
      [viewModel subscriptionButtonPressed:2];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should show the activity indicator when purchase has started", ^{
    [viewModel subscriptionButtonPressed:0];

    expect(viewModel.shouldShowActivityIndicator).to.beTruthy();
  });

  it(@"should hide the activity indicator when purchase has finished successfully", ^{
    OCMStub([subscriptionManager purchaseSubscription:@"foo1" completionHandler:
             ([OCMArg invokeBlockWithArgs:subscriptionInformation, [NSNull null], nil])]);
    [viewModel subscriptionButtonPressed:0];

    expect(viewModel.shouldShowActivityIndicator).to.beFalsy();
  });

  it(@"should request dismissal if purchase was successful", ^{
    OCMStub([subscriptionManager purchaseSubscription:@"foo1" completionHandler:
             ([OCMArg invokeBlockWithArgs:subscriptionInformation, [NSNull null], nil])]);
    auto recorder = [viewModel.dismissRequested testRecorder];
    [viewModel subscriptionButtonPressed:0];

    expect(recorder).to.sendValues(@[[RACUnit defaultUnit]]);
  });

  it(@"should not request dismissal if purchase was unsuccessful", ^{
    auto recorder = [viewModel.dismissRequested testRecorder];
    OCMStub([subscriptionManager purchaseSubscription:@"foo1"
                                    completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null],
                                                        [NSError lt_errorWithCode:1337], nil])]);
    [viewModel subscriptionButtonPressed:0];

    expect(recorder).to.sendValuesWithCount(0);
  });
});

context(@"restoration", ^{
  __block BZRReceiptInfo *receiptInfo;
  __block BZRReceiptSubscriptionInfo *subscriptionInformation;

  beforeEach(^{
    receiptInfo = OCMClassMock([BZRReceiptInfo class]);
    subscriptionInformation = OCMClassMock([BZRReceiptSubscriptionInfo class]);
    OCMStub([receiptInfo subscription]).andReturn(subscriptionInformation);
  });

  it(@"should show the activity indicator when restoration started", ^{
    [viewModel restorePurchasesButtonPressed];

    expect(viewModel.shouldShowActivityIndicator).to.beTruthy();
  });

  it(@"should hide the activity indicator when restoration has finished", ^{
    OCMStub([subscriptionManager
             restorePurchasesWithCompletionHandler:([OCMArg invokeBlockWithArgs:receiptInfo,
                                                     [NSNull null], nil])]);
    [viewModel restorePurchasesButtonPressed];

    expect(viewModel.shouldShowActivityIndicator).to.beFalsy();
  });

  it(@"should request dismissal if restoration was successful and a subscription is active", ^{
    OCMStub([subscriptionInformation isExpired]).andReturn(NO);
    OCMStub([subscriptionManager
             restorePurchasesWithCompletionHandler:([OCMArg invokeBlockWithArgs:receiptInfo,
                                                     [NSNull null], nil])]);
    auto recorder = [viewModel.dismissRequested testRecorder];
    [viewModel restorePurchasesButtonPressed];

    expect(recorder).to.sendValues(@[[RACUnit defaultUnit]]);
  });

  it(@"should not request dismissal if restoration was successful and a subscription is expired", ^{
    OCMStub([subscriptionInformation isExpired]).andReturn(YES);
    OCMStub([subscriptionManager
             restorePurchasesWithCompletionHandler:([OCMArg invokeBlockWithArgs:receiptInfo,
                                                     [NSNull null], nil])]);
    auto recorder = [viewModel.dismissRequested testRecorder];
    [viewModel restorePurchasesButtonPressed];

    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should not request dismissal if restoration was unsuccessful", ^{
    auto recorder = [viewModel.dismissRequested testRecorder];
    OCMStub([subscriptionManager
             restorePurchasesWithCompletionHandler:([OCMArg invokeBlockWithArgs:[NSNull null],
                                                     [NSError lt_errorWithCode:1337], nil])]);
    [viewModel restorePurchasesButtonPressed];

    expect(recorder).to.sendValuesWithCount(0);
  });
});

context(@"paging view", ^{
  it(@"should send scroll request to the next page when video playback has finished", ^{
    auto recorder = [viewModel.pagingViewScrollRequested testRecorder];

    [viewModel activePageDidFinishVideoPlayback];

    expect(recorder).to.sendValues(@[@1]);
  });

  it(@"should send scroll request to the first page if the last page video has finished", ^{
    auto recorder = [viewModel.pagingViewScrollRequested testRecorder];
    [viewModel pagingViewScrolledToPosition:1];

    [viewModel activePageDidFinishVideoPlayback];

    expect(recorder).to.sendValues(@[@0]);
  });
});

context(@"subscription manager delegate", ^{
  beforeEach(^{
    OCMStub([subscriptionManager delegate]).andReturn(viewModel);
  });

  it(@"should send alert view model when requested to present an alert from the delegate", ^{
    SPXAlertViewModel *alertViewModel = OCMClassMock([SPXAlertViewModel class]);
    auto recorder = [viewModel.alertRequested testRecorder];

    [subscriptionManager.delegate presentAlertWithViewModel:alertViewModel];

    expect(recorder).to.sendValues(@[alertViewModel]);
  });

  it(@"should send completion handler when requested to present mail composer from the delegate", ^{
    auto voidBlock = ^{};
    auto recorder = [viewModel.feedbackComposerRequested testRecorder];

    [subscriptionManager.delegate presentFeedbackMailComposerWithCompletionHandler:voidBlock];

    expect(recorder).to.sendValues(@[voidBlock]);
  });
});

context(@"events", ^{
  __block BZRReceiptSubscriptionInfo *subscriptionInformation;

  beforeEach(^{
    subscriptionInformation = OCMClassMock([BZRReceiptSubscriptionInfo class]);
  });

  context(@"purchase subscription", ^{
    __block BZRProductPriceInfo *priceInfo;

    beforeEach(^{
      priceInfo = OCMClassMock([BZRProductPriceInfo class]);
      BZRProduct *product = OCMClassMock([BZRProduct class]);
      OCMStub([product priceInfo]).andReturn(priceInfo);
      NSDictionary<NSString *, BZRProduct *> *returnedProducts = @{
        @"foo2": product
      };
      OCMStub([subscriptionManager fetchProductsInfo:[requestedProductIdentifiers lt_set]
                                   completionHandler:([OCMArg invokeBlockWithArgs:returnedProducts,
                                                       [NSNull null], nil])]);
      [viewModel fetchProductsInfo];
    });

    it(@"should sends subscription button pressed event", ^{
      auto eventsRecorder = [viewModel.events testRecorder];
      [viewModel subscriptionButtonPressed:1];

      expect(eventsRecorder).to.matchValue(0, ^BOOL(SPXSubscriptionButtonPressedEvent *event) {
        return [event.productIdentifier isEqualToString:@"foo2"] && event.price == priceInfo.price;
      });
    });

    it(@"should sends successful subscription purchased event", ^{
      auto eventsRecorder = [viewModel.events testRecorder];

      OCMStub([subscriptionManager purchaseSubscription:@"foo2" completionHandler:
               ([OCMArg invokeBlockWithArgs:subscriptionInformation, [NSNull null], nil])]);

      [viewModel subscriptionButtonPressed:1];

      expect(eventsRecorder).to.matchValue(1, ^BOOL(SPXPurchaseSubscriptionEvent *event) {
        return [event.productIdentifier isEqualToString:@"foo2"] && event.price == priceInfo.price
            && event.localeIdentifier == priceInfo.localeIdentifier && event.successfulPurchase;
      });
    });

    it(@"should sends unsuccessful subscription purchased event", ^{
      auto eventsRecorder = [viewModel.events testRecorder];

      auto error = [NSError lt_errorWithCode:BZRErrorCodePurchaseFailed];
      OCMStub([subscriptionManager purchaseSubscription:@"foo2"
                                      completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null],
                                                          error, nil])]);

      [viewModel subscriptionButtonPressed:1];

      expect(eventsRecorder).to.matchValue(1, ^BOOL(SPXPurchaseSubscriptionEvent *event) {
        return [event.productIdentifier isEqualToString:@"foo2"] &&
            event.price == priceInfo.price &&
            event.localeIdentifier == priceInfo.localeIdentifier && !event.successfulPurchase &&
            [event.failureDescription isEqualToString:@"BZRErrorCodePurchaseFailed"];
      });
    });
  });

  context(@"restore purchases", ^{
    __block BZRReceiptInfo *receiptInfo;

    beforeEach(^{
      receiptInfo = OCMClassMock([BZRReceiptInfo class]);
      OCMStub([receiptInfo subscription]).andReturn(subscriptionInformation);
    });

    it(@"should sends restore purchases button pressed event", ^{
      auto eventsRecorder = [viewModel.events testRecorder];
      [viewModel restorePurchasesButtonPressed];

      expect(eventsRecorder).to.sendValues(@[[[SPXRestorePurchasesButtonPressedEvent alloc] init]]);
    });

    it(@"should sends successful restore purchases event", ^{
      auto eventsRecorder = [viewModel.events testRecorder];

      OCMStub([subscriptionInformation isExpired]).andReturn(NO);
      OCMStub([subscriptionManager
               restorePurchasesWithCompletionHandler:([OCMArg invokeBlockWithArgs:receiptInfo,
                                                       [NSNull null], nil])]);

      [viewModel restorePurchasesButtonPressed];

      expect(eventsRecorder).to.matchValue(1, ^BOOL(SPXRestorePurchasesEvent *event) {
        return event.successfulRestore && event.isSubscriber;
      });
    });

    it(@"should sends unsuccessful restore purchases event", ^{
      auto eventsRecorder = [viewModel.events testRecorder];

      auto error = [NSError lt_errorWithCode:BZRErrorCodeRestorePurchasesFailed];
      OCMStub([subscriptionInformation isExpired]).andReturn(YES);
      OCMStub([subscriptionManager
               restorePurchasesWithCompletionHandler:([OCMArg invokeBlockWithArgs:[NSNull null],
                                                       error, nil])]);

      [viewModel restorePurchasesButtonPressed];

      expect(eventsRecorder).to.matchValue(1, ^BOOL(SPXRestorePurchasesEvent *event) {
        return !event.successfulRestore && !event.isSubscriber &&
            [event.failureDescription isEqualToString:@"BZRErrorCodeRestorePurchasesFailed"];
      });
    });
  });
});

SpecEnd
