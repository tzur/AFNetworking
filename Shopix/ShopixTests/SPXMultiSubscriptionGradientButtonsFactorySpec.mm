// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXMultiSubscriptionGradientButtonsFactory.h"

#import <Bazaar/BZRProductsInfoProvider.h>

#import "SPXSubscriptionButtonFormatter.h"
#import "SPXSubscriptionDescriptor.h"
#import "SPXSubscriptionGradientButton.h"

SpecBegin(SPXMultiSubscriptionGradientButtonsFactory)

__block id<BZRProductsInfoProvider> productsInfoProvider;
__block SPXMultiSubscriptionGradientButtonsFactory *buttonsFactory;

beforeEach(^{
  productsInfoProvider = OCMProtocolMock(@protocol(BZRProductsInfoProvider));
  buttonsFactory =
      [[SPXMultiSubscriptionGradientButtonsFactory alloc]
       initWithBottomGradientColors:@[[UIColor whiteColor], [UIColor blackColor]]
       multiAppBottomGradientColors:@[[UIColor redColor], [UIColor blueColor]]
       formatter:OCMClassMock([SPXSubscriptionButtonFormatter class])];
});

it(@"should return a button with regular gradient colors", ^{
  auto descriptor = [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo"
      discountPercentage:0 productsInfoProvider:productsInfoProvider];
  auto button = (SPXSubscriptionGradientButton *)
      [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor atIndex:0
                                                                   outOf:1 isHighlighted:NO];

  expect(button.bottomGradientColors).to.equal(@[[UIColor whiteColor], [UIColor whiteColor]]);
});

it(@"should return an highlighted button with regular gradient colors", ^{
  auto descriptor = [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo"
      discountPercentage:0 productsInfoProvider:productsInfoProvider];
  auto button = (SPXSubscriptionGradientButton *)
  [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor atIndex:0
                                                               outOf:1 isHighlighted:YES];

  expect(button.bottomGradientColors).to.equal(@[[UIColor whiteColor], [UIColor blackColor]]);
});

it(@"should return a button with multi-app gradient colors", ^{
  OCMStub([productsInfoProvider isMultiAppSubscription:@"foo"]).andReturn(YES);
  auto descriptor = [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo"
      discountPercentage:0 productsInfoProvider:productsInfoProvider];
  auto button = (SPXSubscriptionGradientButton *)
      [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor atIndex:0
                                                                   outOf:1 isHighlighted:NO];

  expect(button.bottomGradientColors).to.equal(@[[UIColor redColor], [UIColor redColor]]);
});

it(@"should return an highlighted button with multi-app gradient colors", ^{
  OCMStub([productsInfoProvider isMultiAppSubscription:@"foo"]).andReturn(YES);
  auto descriptor = [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo"
      discountPercentage:0 productsInfoProvider:productsInfoProvider];
  auto button = (SPXSubscriptionGradientButton *)
  [buttonsFactory createSubscriptionButtonWithSubscriptionDescriptor:descriptor atIndex:0
                                                               outOf:1 isHighlighted:YES];

  expect(button.bottomGradientColors).to.equal(@[[UIColor redColor], [UIColor blueColor]]);
});

SpecEnd
