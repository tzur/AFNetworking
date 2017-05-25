// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRCompositeContentFetcher.h"

#import "BZRContentFetcherParameters.h"
#import "BZRProduct.h"
#import "BZRProductContentFetcher.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRCompositeContentFetcher)

__block id<BZRProductContentFetcher> contentFetcher;
__block BZRContentFetchersDictionary *contentFetchers;
__block BZRCompositeContentFetcher *compositeContentFetcher;

beforeEach(^{
  contentFetcher = OCMProtocolMock(@protocol(BZRProductContentFetcher));
  contentFetchers = @{
    @"mockedContentFetcher": contentFetcher
  };
  compositeContentFetcher =
      [[BZRCompositeContentFetcher alloc] initWithContentFetchers:contentFetchers];
});

it(@"should send the bundle of the product content with the right fetcher", ^{
  BZRProduct *product = BZRProductWithIdentifierAndContent(@"foo");
  OCMStub([product.contentFetcherParameters type]).andReturn(@"mockedContentFetcher");

  NSBundle *bundle = OCMClassMock([NSBundle class]);
  OCMStub([contentFetchers[@"mockedContentFetcher"] contentBundleForProduct:product])
      .andReturn([RACSignal return:bundle]);

  LLSignalTestRecorder *recorder = [[contentFetcher contentBundleForProduct:product] testRecorder];

  expect(recorder).to.complete();
  expect(recorder).to.sendValues(@[bundle]);
});

context(@"fetching content", ^{
  it(@"should err when contentFetcherParameters type is not registered", ^{
    BZRProduct *product = BZRProductWithIdentifierAndContent(@"foo");
    OCMStub(product.contentFetcherParameters.type).andReturn(@"notRegisteredContentFetcher");

    LLSignalTestRecorder *recorder = [[compositeContentFetcher fetchProductContent:product]
                                      testRecorder];

    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeProductContentFetcherNotRegistered;
    });
  });

  context(@"product has content", ^{
    __block BZRProduct *product;

    beforeEach(^{
      product = BZRProductWithIdentifierAndContent(@"foo");
      OCMStub(product.contentFetcherParameters.type).andReturn(@"mockedContentFetcher");
    });

    it(@"should return bundle provided by content fetcher after fetching completes", ^{
      NSBundle *bundle = OCMClassMock([NSBundle class]);
      LTProgress *progress = [[LTProgress alloc] initWithResult:bundle];
      OCMStub([contentFetcher fetchProductContent:product]).andReturn([RACSignal return:progress]);

      LLSignalTestRecorder *recorder = [[compositeContentFetcher fetchProductContent:product]
                                        testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[progress]);
    });

    it(@"should err when product content fetcher errs", ^{
      NSError *fetchContentError = OCMClassMock([NSError class]);
      OCMStub([contentFetcher fetchProductContent:OCMOCK_ANY])
          .andReturn([RACSignal error:fetchContentError]);

      RACSignal *fetchingContent = [compositeContentFetcher fetchProductContent:product];

      expect(fetchingContent).will.sendError(fetchContentError);
    });
  });
});

SpecEnd
