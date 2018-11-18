// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMYourPlanPromotionViewModel.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProduct.h>

SpecBegin(EUISMYourPlanPromotionViewModel)

__block RACSubject<EUISMModel *> *modelSubject;
__block EUISMYourPlanPromotionViewModel *viewModel;

beforeEach(^{
  modelSubject = [RACSubject<EUISMModel *> subject];
  viewModel = [[EUISMYourPlanPromotionViewModel alloc] initWithModelSignal:modelSubject];
});

context(@"promotionText", ^{
  it(@"should set promotionText with correct save percent if promoted product is available", ^{
    auto model = [EUISMModel modelWithPromotedProductSavePercent:30];

    [modelSubject sendNext:model];

    expect(viewModel.promotionText).to.equal(@"GO YEARLY AND SAVE 30%");
  });

  it(@"should set promotionText to empty string if promoted product is not available", ^{
    auto billingPeriodDictionary = @{@"unit": $(BZRBillingPeriodUnitMonths), @"unitCount": @(1)};
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:billingPeriodDictionary
                                                                error:nil];
    auto model = [EUISMModel modelWithBillingPeriod:billingPeriod expired:NO];

    [modelSubject sendNext:model];

    expect(viewModel.promotionText).to.beEmpty();
  });

  it(@"should set promotionText to empty string if save percent is not positive", ^{
     auto model = [EUISMModel modelWithPromotedProductSavePercent:0];

     [modelSubject sendNext:model];

     expect(viewModel.promotionText).to.beEmpty();
  });

  it(@"should update promotionText when save percent changes", ^{
    auto noPromotionModel = [EUISMModel modelWithPromotedProductSavePercent:0];
    auto promotionModel = [EUISMModel modelWithPromotedProductSavePercent:40];
    [modelSubject sendNext:noPromotionModel];
    LLSignalTestRecorder *recorder = [RACObserve(viewModel, promotionText) testRecorder];

    [modelSubject sendNext:promotionModel];

    expect(recorder).to.sendValues(@[@"", @"GO YEARLY AND SAVE 40%"]);
  });
});

context(@"upgrade signal", ^{
  __block RACSubject<RACUnit *> *upgradeRequestedSubject;

  beforeEach(^{
    upgradeRequestedSubject = [RACSubject<RACUnit *> subject];
    viewModel.upgradeRequested = upgradeRequestedSubject;
  });

  it(@"should fire when upgrade available and upgrade required signal fires", ^{
    auto model = [EUISMModel modelWithPromotedProductSavePercent:10];
    [modelSubject sendNext:model];
    LLSignalTestRecorder *recorder = [viewModel.upgradeSignal testRecorder];

    [upgradeRequestedSubject sendNext:RACUnit.defaultUnit];

    expect(recorder).to.sendValuesWithCount(1);
  });

  it(@"should ignore old upgrade required signal after setting a new one", ^{
    auto model = [EUISMModel modelWithPromotedProductSavePercent:10];
    [modelSubject sendNext:model];
    LLSignalTestRecorder *recorder = [viewModel.upgradeSignal testRecorder];
    viewModel.upgradeRequested = [RACSubject<RACUnit *> subject];

    [upgradeRequestedSubject sendNext:RACUnit.defaultUnit];

    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should deallocate even when upgrade signal has not completed", ^{
    __weak EUISMYourPlanPromotionViewModel *weakViewModel = nil;
    @autoreleasepool {
      auto viewModel = [[EUISMYourPlanPromotionViewModel alloc] initWithModelSignal:modelSubject];
      viewModel.upgradeRequested = upgradeRequestedSubject;
      weakViewModel = viewModel;
    }
    expect(weakViewModel).to.beNil();
  });
});

it(@"should initialize with default values", ^{
  expect(viewModel.promotionText).to.beEmpty();
  expect(viewModel.promotionTextColor).to.equal([UIColor grayColor]);
  expect(viewModel.upgradeButtonColor).to.equal([UIColor grayColor]);
});

it(@"should not throw when model signal fires nil", ^{
  [modelSubject sendNext:nil];
});

it(@"should deallocate even when model signal has not completed", ^{
  __weak EUISMYourPlanPromotionViewModel *weakViewModel = nil;
  @autoreleasepool {
    auto viewModel = [[EUISMYourPlanPromotionViewModel alloc] initWithModelSignal:modelSubject];
    weakViewModel = viewModel;
  }
  expect(weakViewModel).to.beNil();
});

SpecEnd
