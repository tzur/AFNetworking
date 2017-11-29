// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionGradientButtonsFactory.h"

#import <Bazaar/BZRProductPriceInfo.h>

#import "SPXSubscriptionButtonFormatter.h"
#import "SPXSubscriptionDescriptor.h"
#import "SPXSubscriptionGradientButton.h"

SpecBegin(SPXSubscriptionGradientButtonsFactory)

__block SPXSubscriptionDescriptor *descriptor;
__block SPXSubscriptionGradientButtonsFactory *buttonsFactory;

beforeEach(^{
  SPXSubscriptionButtonFormatter *formatter = OCMClassMock([SPXSubscriptionButtonFormatter class]);
  auto subscriptionPeriod = ([[NSAttributedString alloc] initWithString:@"boo"]);
  auto subscriptionPrice = ([[NSAttributedString alloc] initWithString:@"10"]);
  OCMStub([formatter periodTextForSubscription:@"foo" monthlyFormat:YES])
      .andReturn(subscriptionPeriod);
  OCMStub([formatter joinedPriceTextForSubscription:@"foo" priceInfo:[OCMArg any]
                                      monthlyFormat:YES]).andReturn(subscriptionPrice);

  descriptor = [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo"];
  buttonsFactory =
      [[SPXSubscriptionGradientButtonsFactory alloc]
       initWithBottomGradientColors:@[[UIColor whiteColor], [UIColor blackColor]]
       formatter:formatter];
});

it(@"should set the button gradient colors", ^{
  auto button = (SPXSubscriptionGradientButton *)
      [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor];

  expect(button.bottomGradientColors).to.equal(@[[UIColor whiteColor], [UIColor blackColor]]);
});

it(@"should set the subscription period at the top of the new button", ^{
  auto button = (SPXSubscriptionGradientButton *)
      [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor];

  expect([button.topText string]).to.equal(@"boo");
});

it(@"should set the subscription price and full price at the bottom of the new button", ^{
  auto button = (SPXSubscriptionGradientButton *)
      [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor];
  descriptor.priceInfo = OCMClassMock([BZRProductPriceInfo class]);

  expect([button.bottomText string]).will.equal(@"10");
});

it(@"should not hold the button strongly", ^{
  __weak UIButton *button;

  @autoreleasepool {
    UIButton *strongButton =
        [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor];
    button = strongButton;
  }

  expect(button).to.beNil();
});

SpecEnd
