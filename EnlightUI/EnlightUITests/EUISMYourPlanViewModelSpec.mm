// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMYourPlanViewModel.h"

#import <Bazaar/BZRBillingPeriod.h>

SpecBegin(EUISMYourPlanViewModel)

__block RACSubject<EUISMModel *> *modelSubject;
__block EUISMYourPlanViewModel *viewModel;

beforeEach(^{
  modelSubject = [RACSubject<EUISMModel *> subject];
  viewModel = [[EUISMYourPlanViewModel alloc] initWithModelSignal:modelSubject];
});

context(@"title", ^{
  it(@"should set title to application's full name when subscriptionType is single application", ^{
    auto model =
        [EUISMModel modelWithSingleAppSubscriptionForApplication:$(EUISMApplicationPhotofox)];

    [modelSubject sendNext:model];

    expect(viewModel.title).to.equal($(EUISMApplicationPhotofox).fullName);
  });

  it(@"should set title to eco system title when subscriptionType is eco system", ^{
    auto model = [EUISMModel modelWithEcoSystemSubscription];

    [modelSubject sendNext:model];

    expect(viewModel.title).to.equal(@"Enlight PRO Suite");
  });

  it(@"should update title when model subscription type changes", ^{
    auto photofoxModel =
        [EUISMModel modelWithSingleAppSubscriptionForApplication:$(EUISMApplicationPhotofox)];
    auto ecoSystemModel = [EUISMModel modelWithEcoSystemSubscription];
    [modelSubject sendNext:photofoxModel];
    LLSignalTestRecorder *recorder = [RACObserve(viewModel, title) testRecorder];

    [modelSubject sendNext:ecoSystemModel];

    expect(recorder).to.sendValues(@[$(EUISMApplicationPhotofox).fullName, @"Enlight PRO Suite"]);
  });
});

context(@"subtitle", ^{
  __block BZRBillingPeriod *monthlyBillingPeriod;
  __block BZRBillingPeriod *biyearlyBillingPeriod;
  __block BZRBillingPeriod *yearlyBillingPeriod;
  auto monthlyBillingPeriodDictionary = @{
    @"unit": $(BZRBillingPeriodUnitMonths),
    @"unitCount": @(1)
  };
  auto biyearlyBillingPeriodDictionary = @{
    @"unit": $(BZRBillingPeriodUnitMonths),
    @"unitCount": @(6)
  };
  auto yearlyBillingPeriodDictionary = @{
    @"unit": $(BZRBillingPeriodUnitYears),
    @"unitCount": @(1)
  };

  beforeEach(^{
    monthlyBillingPeriod = [[BZRBillingPeriod alloc]
                            initWithDictionary:monthlyBillingPeriodDictionary error:nil];
    biyearlyBillingPeriod = [[BZRBillingPeriod alloc]
                             initWithDictionary:biyearlyBillingPeriodDictionary error:nil];
    yearlyBillingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:yearlyBillingPeriodDictionary
                                                                 error:nil];
  });

  it(@"should set monthly subtitle when subscription is monthly and not expired", ^{
    auto model = [EUISMModel modelWithBillingPeriod:monthlyBillingPeriod expired:NO];

    [modelSubject sendNext:model];

    expect(viewModel.subtitle).to.equal(@"You are a Monthly member");
  });

  it(@"should set biyearly subtitle when subscription is biyearly and not expired", ^{
    auto model = [EUISMModel modelWithBillingPeriod:biyearlyBillingPeriod expired:NO];

    [modelSubject sendNext:model];

    expect(viewModel.subtitle).to.equal(@"You are a Biyearly member");
  });

  it(@"should set yearly subtitle when subscription is yearly and not expired", ^{
    auto model = [EUISMModel modelWithBillingPeriod:yearlyBillingPeriod expired:NO];

   [modelSubject sendNext:model];

    expect(viewModel.subtitle).to.equal(@"You are a Yearly member");
  });

  it(@"should set member subtitle when subscription period is unknown and not expired", ^{
    auto model = [EUISMModel modelWithBillingPeriod:[[BZRBillingPeriod alloc] init] expired:NO];

    [modelSubject sendNext:model];

    expect(viewModel.subtitle).to.equal(@"You are a member");
  });

  it(@"should set subtitle to expired monthly when subscription is monthly and expired", ^{
    auto model = [EUISMModel modelWithBillingPeriod:monthlyBillingPeriod expired:YES];

    [modelSubject sendNext:model];

    expect(viewModel.subtitle).to.equal([viewModel.title stringByAppendingString:@" - 1 Month"]);
  });

  it(@"should set subtitle to expired biyearly when subscription is biyearly and expired", ^{
    auto model = [EUISMModel modelWithBillingPeriod:biyearlyBillingPeriod expired:YES];

    [modelSubject sendNext:model];

    expect(viewModel.subtitle).to.equal([viewModel.title stringByAppendingString:@" - 6 Months"]);
  });

  it(@"should set subtitle to expired yearly when subscription is yearly and expired", ^{
    auto model = [EUISMModel modelWithBillingPeriod:yearlyBillingPeriod expired:YES];

    [modelSubject sendNext:model];

    expect(viewModel.subtitle).to.equal([viewModel.title stringByAppendingString:@" - 1 Year"]);
  });

  it(@"should set expired subtitle when subscription period is unknown and expired", ^{
    auto model = [EUISMModel modelWithBillingPeriod:[[BZRBillingPeriod alloc] init] expired:YES];

    [modelSubject sendNext:model];

    expect(viewModel.subtitle).to.equal(viewModel.title);
  });

  it(@"should set not a member subtitle when not subscribed", ^{
    auto model = [EUISMModel modelWithNoSubscription];

    [modelSubject sendNext:model];

    expect(viewModel.subtitle).to.equal(@"You are not a member yet");
  });

  it(@"should update subtitle when model subscription status changes", ^{
    auto unsubscribedModel = [EUISMModel modelWithNoSubscription];
    auto subscribedModel = [EUISMModel modelWithBillingPeriod:[[BZRBillingPeriod alloc] init]
                                                      expired:NO];
    [modelSubject sendNext:unsubscribedModel];
    LLSignalTestRecorder *recorder = [RACObserve(viewModel, subtitle) testRecorder];

    [modelSubject sendNext:subscribedModel];

    expect(recorder).to.sendValues(@[@"You are not a member yet", @"You are a member"]);
  });
});

context(@"body", ^{
  it(@"should set expired body when subscription expired", ^{
    auto model = [EUISMModel modelWithBillingPeriod:[[BZRBillingPeriod alloc] init] expired:YES];

    [modelSubject sendNext:model];

    expect(viewModel.body).to.startWith(@"Expired ");
  });

  it(@"should set renews body when subscription renews", ^{
    auto model = [EUISMModel modelWithAutoRenewal:YES];

    [modelSubject sendNext:model];

    expect(viewModel.body).to.startWith(@"Renews ");
  });

  it(@"should set ends body when subscription doesn't renew", ^{
    auto model = [EUISMModel modelWithAutoRenewal:NO];

    [modelSubject sendNext:model];

    expect(viewModel.body).to.startWith(@"Ends ");
  });

  it(@"should set empty body not subscribed", ^{
    auto model = [EUISMModel modelWithNoSubscription];

    [modelSubject sendNext:model];

    expect(viewModel.body).to.beEmpty();
  });

  it(@"should set body that ends with the expiration time", ^{
    auto expirationTime = [NSDate dateWithTimeIntervalSince1970:0];
    auto model = [EUISMModel modelWithExpirationTime:expirationTime];

    [modelSubject sendNext:model];

    expect(viewModel.body).to.endWith(@"Jan 1, 1970");
  });

  it(@"should update body when model subscription status changes", ^{
    auto unsubscribedModel = [EUISMModel modelWithNoSubscription];
    auto renewingModel = [EUISMModel modelWithAutoRenewal:YES];
    [modelSubject sendNext:unsubscribedModel];
    LLSignalTestRecorder *recorder = [RACObserve(viewModel, body) testRecorder];

    [modelSubject sendNext:renewingModel];

    expect(recorder).to.matchValue(0, ^(NSString *body){
      return !body.length;
    });
    expect(recorder).to.matchValue(1, ^(NSString *body){
      return [body hasPrefix:@"Renews "];
    });
  });
});

context(@"status icon", ^{
  it(@"should set statusIconURL to exclamation mark when there are billing issues", ^{
    auto model = [EUISMModel modelWithBillingIssues:YES];

    [modelSubject sendNext:model];

    expect(viewModel.statusIconURL).to.equal([NSURL URLWithString:@"exclamationMark"]);
  });

  it(@"should set statusIconURL to nil when there are no billing issues", ^{
    auto model = [EUISMModel modelWithBillingIssues:NO];

    [modelSubject sendNext:model];

    expect(viewModel.statusIconURL).to.beNil();
  });

  it(@"should update statusIconURL when model subscription status changes", ^{
    auto billingIssuesModel = [EUISMModel modelWithBillingIssues:YES];
    auto noBillingIssuesModel = [EUISMModel modelWithBillingIssues:NO];
    [modelSubject sendNext:billingIssuesModel];
    LLSignalTestRecorder *recorder = [RACObserve(viewModel, statusIconURL) testRecorder];

    [modelSubject sendNext:noBillingIssuesModel];

    expect(recorder).to.sendValues(@[nn([NSURL URLWithString:@"exclamationMark"]), [NSNull null]]);
  });
});

it(@"should set current app thumbnail URL to current application's thumbnail URL", ^{
  auto model =
      [EUISMModel modelWithSingleAppSubscriptionForApplication:$(EUISMApplicationVideoleap)];

  [modelSubject sendNext:model];

  expect(viewModel.currentAppThumbnailURL).to.equal($(EUISMApplicationVideoleap).thumbnailURL);
});

it(@"should initialize with default values", ^{
  expect(viewModel.title).to.beEmpty();
  expect(viewModel.subtitle).to.beEmpty();
  expect(viewModel.body).to.beEmpty();
  expect(viewModel.currentAppThumbnailURL).to.beNil();
  expect(viewModel.statusIconURL).to.beNil();
});

it(@"should not throw when model signal sends nil", ^{
  [modelSubject sendNext:nil];
});

it(@"should deallocate even when model signal has not completed", ^{
  __weak EUISMYourPlanViewModel *weakViewModel = nil;
  @autoreleasepool {
    auto viewModel = [[EUISMYourPlanViewModel alloc] initWithModelSignal:modelSubject];
    weakViewModel = viewModel;
  }
  expect(weakViewModel).to.beNil();
});

SpecEnd
