// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionViewModel.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductPriceInfo.h>
#import <Bazaar/BZRReceiptModel.h>

#import "SPXAlertViewModel.h"
#import "SPXColorScheme.h"
#import "SPXSubscriptionDescriptor.h"
#import "SPXSubscriptionManager.h"
#import "SPXSubscriptionTermsViewModel.h"

SpecBegin(SPXSubscriptionViewModel)

__block SPXSubscriptionViewModel *viewModel;
__block SPXSubscriptionManager *subscriptionManager;
__block SPXSubscriptionTermsViewModel *termsViewModel;
__block SPXColorScheme *colorScheme;
__block NSArray<NSString *> *requestedProductIdentifiers;

beforeEach(^{
  subscriptionManager = OCMClassMock([SPXSubscriptionManager class]);
  termsViewModel = OCMClassMock([SPXSubscriptionTermsViewModel class]);
  colorScheme = OCMClassMock([SPXColorScheme class]);
  requestedProductIdentifiers = @[@"foo1", @"foo2"];

  viewModel = [[SPXSubscriptionViewModel alloc] initWithProducts:requestedProductIdentifiers
      preferredProductIndex:0 pageViewModels:@[] termsViewModel:termsViewModel
      colorScheme:colorScheme subscriptionManager:subscriptionManager];
});

it(@"should raise if the preferred button index is greater than the number of buttons", ^{
  expect(^{
      viewModel = [[SPXSubscriptionViewModel alloc] initWithProducts:requestedProductIdentifiers
      preferredProductIndex:@2 pageViewModels:@[] termsViewModel:termsViewModel
      colorScheme:colorScheme subscriptionManager:subscriptionManager];
  }).to.raise(NSInvalidArgumentException);
});

context(@"products fetching", ^{
  it(@"should show the activity indicator when fetch has started", ^{
    [viewModel fetchProductsInfo];
    expect(viewModel.shouldShowActivityIndicator).to.beTruthy();
  });

  it(@"should hide the activity indicator when fetch has finished successfully", ^{
    OCMStub([subscriptionManager fetchProductsInfo:[requestedProductIdentifiers lt_set]
                                 completionHandler:([OCMArg invokeBlockWithArgs:@{}, [NSNull null],
                                                     nil])]);
    [viewModel fetchProductsInfo];

    expect(viewModel.shouldShowActivityIndicator).to.beFalsy();
  });

  it(@"should request dismissal if failed to fetch products", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([subscriptionManager fetchProductsInfo:[requestedProductIdentifiers lt_set]
                                 completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null],
                                                     error, nil])]);
    auto recorder = [viewModel.dismissRequested testRecorder];
    [viewModel fetchProductsInfo];

    expect(recorder).to.sendValues(@[[RACUnit defaultUnit]]);
  });

  it(@"should set the product descriptors according to the product identifiers with prices", ^{
    BZRProduct *product1 = OCMClassMock([BZRProduct class]);
    BZRProduct *product2 = OCMClassMock([BZRProduct class]);
    OCMStub([product1 priceInfo]).andReturn(OCMClassMock([BZRProductPriceInfo class]));
    OCMStub([product2 priceInfo]).andReturn(OCMClassMock([BZRProductPriceInfo class]));
    NSDictionary<NSString *, BZRProduct *> *returnedProducts = @{
      @"foo1": product1,
      @"foo2": product2
    };
    OCMStub([subscriptionManager fetchProductsInfo:[requestedProductIdentifiers lt_set]
                                 completionHandler:([OCMArg invokeBlockWithArgs:returnedProducts,
                                                     [NSNull null], nil])]);

    [viewModel fetchProductsInfo];

    [viewModel.subscriptionDescriptors
     enumerateObjectsUsingBlock:^(SPXSubscriptionDescriptor *descriptor, NSUInteger index, BOOL *) {
       expect(descriptor.productIdentifier).to.equal(requestedProductIdentifiers[index]);
       expect(descriptor.priceInfo).to
          .equal(returnedProducts[descriptor.productIdentifier].priceInfo);
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

SpecEnd
