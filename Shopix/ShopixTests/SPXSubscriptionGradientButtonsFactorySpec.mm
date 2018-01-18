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
  id<BZRProductsInfoProvider> productsInfoProvider =
      OCMProtocolMock(@protocol(BZRProductsInfoProvider));
  descriptor = [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo"
                                                         discountPercentage:0
                                                       productsInfoProvider:productsInfoProvider];
  OCMStub([formatter billingPeriodTextForSubscription:descriptor monthlyFormat:YES])
      .andReturn(subscriptionPeriod);
  OCMStub([formatter joinedPriceTextForSubscription:descriptor
                                      monthlyFormat:YES]).andReturn(subscriptionPrice);

  buttonsFactory =
      [[SPXSubscriptionGradientButtonsFactory alloc]
       initWithBottomGradientColors:@[[UIColor whiteColor], [UIColor blackColor]]
       highlightedBottomGradientColors:@[[UIColor redColor], [UIColor grayColor]]
       formatter:formatter];
});

it(@"should set the button gradient colors", ^{
  auto button = (SPXSubscriptionGradientButton *)
      [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor atIndex:0
                                                                   outOf:1 isHighlighted:NO];

  expect(button.bottomGradientColors).to.equal(@[[UIColor whiteColor], [UIColor blackColor]]);
});

it(@"should set the highlighted button gradient colors", ^{
  auto button = (SPXSubscriptionGradientButton *)
      [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor atIndex:0
                                                                   outOf:1 isHighlighted:YES];

  expect(button.bottomGradientColors).to.equal(@[[UIColor redColor], [UIColor grayColor]]);
});

it(@"should set the button border color to the last color with additional 24% to brightness", ^{
  auto button = (SPXSubscriptionGradientButton *)
      [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor atIndex:0
                                                                   outOf:1 isHighlighted:YES];

  expect(button.borderColor).to.equal([UIColor colorWithRed:0.62 green:0.62 blue:0.62 alpha:1.0]);
});

it(@"should set the highlighted button colors to normal if no highlighted colors provided", ^{
  buttonsFactory =
      [[SPXSubscriptionGradientButtonsFactory alloc]
       initWithBottomGradientColors:@[[UIColor whiteColor], [UIColor blackColor]]
       highlightedBottomGradientColors:nil
       formatter:OCMClassMock([SPXSubscriptionButtonFormatter class])];
  auto button = (SPXSubscriptionGradientButton *)
      [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor atIndex:0
                                                                   outOf:1 isHighlighted:YES];

  expect(button.bottomGradientColors).to.equal(@[[UIColor whiteColor], [UIColor blackColor]]);
});

it(@"should set the button border color to nil if no highlighted colors provided", ^{
  buttonsFactory =
      [[SPXSubscriptionGradientButtonsFactory alloc]
       initWithBottomGradientColors:@[[UIColor whiteColor], [UIColor blackColor]]
       highlightedBottomGradientColors:nil
       formatter:OCMClassMock([SPXSubscriptionButtonFormatter class])];
  auto button = (SPXSubscriptionGradientButton *)
      [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor atIndex:0
                                                                   outOf:1 isHighlighted:NO];

  expect(button.borderColor).to.beNil();
});

it(@"should set the subscription period at the top of the new button", ^{
  auto button = (SPXSubscriptionGradientButton *)
      [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor atIndex:0
                                                                   outOf:1 isHighlighted:NO];

  expect([button.topText string]).to.equal(@"boo");
});

it(@"should set the subscription price and full price at the bottom of the new button", ^{
  auto button = (SPXSubscriptionGradientButton *)
      [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor atIndex:0
                                                                   outOf:1 isHighlighted:NO];
  descriptor.priceInfo = OCMClassMock([BZRProductPriceInfo class]);

  expect([button.bottomText string]).will.equal(@"10");
});

it(@"should disable the button until the price is set", ^{
  auto button = [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor
                                                                           atIndex:0 outOf:1
                                                                     isHighlighted:NO];

  expect([button isEnabled]).to.beFalsy();
  descriptor.priceInfo = OCMClassMock([BZRProductPriceInfo class]);
  expect([button isEnabled]).to.beTruthy();
});

it(@"should not hold the button strongly", ^{
  __weak UIControl *button;

  @autoreleasepool {
    UIControl *strongButton =
        [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor atIndex:0
                                                                     outOf:1 isHighlighted:NO];
    button = strongButton;
  }

  expect(button).to.beNil();
});

SpecEnd
