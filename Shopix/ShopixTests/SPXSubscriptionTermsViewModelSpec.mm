// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionTermsViewModel.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProductPriceInfo.h>
#import <Bazaar/BZRProductsInfoProvider.h>

#import "SPXSubscriptionDescriptor.h"

SpecBegin(SPXSubscriptionTermsViewModelSpec)

__block SPXSubscriptionTermsViewModel *termsViewModel;
__block id<BZRProductsInfoProvider> productsInfoProvider;
__block BZRProductPriceInfo *priceInfo;

beforeEach(^{
  auto url = [[NSURL alloc] initWithString:@"http://foo"];
  termsViewModel = [[SPXSubscriptionTermsViewModel alloc] initWithFullTerms:url privacyPolicy:url];
  productsInfoProvider = OCMProtocolMock(@protocol(BZRProductsInfoProvider));
  priceInfo = [[BZRProductPriceInfo alloc] initWithDictionary:@{
    @instanceKeypath(BZRProductPriceInfo, price): [NSDecimalNumber decimalNumberWithString:@"10"],
    @instanceKeypath(BZRProductPriceInfo, localeIdentifier): @"en_US"
  } error:nil];
});

context(@"terms gist", ^{
  it(@"should default to nil", ^{
    expect(termsViewModel.termsGistText).to.beNil();
  });

  it(@"should not add billed in one-payment text if received nil", ^{
    [termsViewModel updateTermsGistWithSubscriptions:nil];

    expect(termsViewModel.termsGistText).to.beNil();
  });

  it(@"should be KVO complaint", ^{
    auto yearlySubscription =
        [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo.1Y" discountPercentage:0
                                                productsInfoProvider:productsInfoProvider];
    auto recorder = [RACObserve(termsViewModel, termsGistText) testRecorder];

    [termsViewModel updateTermsGistWithSubscriptions:@[yearlySubscription]];

    expect(recorder).to.matchValue(2, ^BOOL(NSAttributedString * _Nullable termsGistText) {
      return [termsGistText.string isEqual:[NSString stringWithFormat:@"* %@",
                                            SPXSubscriptionTermsViewModel.defaultTermsGist]];
    });
  });

  it(@"should add billed in one-payment text if a bi-yearly subscription was found", ^{
    auto biYearlySubscription =
        [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo.6M" discountPercentage:0
                                                productsInfoProvider:productsInfoProvider];

    [termsViewModel updateTermsGistWithSubscriptions:@[biYearlySubscription]];

    expect(termsViewModel.termsGistText.string).to.equal([NSString stringWithFormat:@"* %@",
        SPXSubscriptionTermsViewModel.defaultTermsGist]);
  });

  it(@"should add billed in one-payment text if a yearly subscription was found", ^{
    auto yearlySubscription =
        [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo.1Y" discountPercentage:0
                                                productsInfoProvider:productsInfoProvider];

    [termsViewModel updateTermsGistWithSubscriptions:@[yearlySubscription]];

    expect(termsViewModel.termsGistText.string).to.equal([NSString stringWithFormat:@"* %@",
        SPXSubscriptionTermsViewModel.defaultTermsGist]);
  });

  it(@"should not add billed in one-payment text for a monthly subscription", ^{
    auto yearlySubscription =
        [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo.1M" discountPercentage:0
                                                productsInfoProvider:productsInfoProvider];

    [termsViewModel updateTermsGistWithSubscriptions:@[yearlySubscription]];

    expect(termsViewModel.termsGistText).to.beNil();
  });

  it(@"should update the terms gist text when yearly subscription prices becomes available", ^{
    auto yearlySubscription =
        [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo.1Y" discountPercentage:0
                                                productsInfoProvider:productsInfoProvider];

    [termsViewModel updateTermsGistWithSubscriptions:@[yearlySubscription]];
    yearlySubscription.priceInfo = priceInfo;

    auto expectedTermsGist =
        [@"* " stringByAppendingFormat:SPXSubscriptionTermsViewModel.defaultTermsGistWithPrice,
         @"$10.00"];
    expect(termsViewModel.termsGistText.string).to.equal(expectedTermsGist);
  });

  it(@"should unbind a subscription price observation when called to update terms gist again", ^{
    auto yearlySubscription =
      [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo.1Y" discountPercentage:0
                                              productsInfoProvider:productsInfoProvider];

    [termsViewModel updateTermsGistWithSubscriptions:@[yearlySubscription]];
    [termsViewModel updateTermsGistWithSubscriptions:nil];
    yearlySubscription.priceInfo = priceInfo;

    expect(termsViewModel.termsGistText).to.beNil();
  });
});

SpecEnd
