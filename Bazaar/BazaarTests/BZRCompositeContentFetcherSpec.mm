// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRCompositeContentFetcher.h"

#import "BZRContentFetcherParameters.h"
#import "BZREvent.h"
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
  OCMStub([contentFetcher eventsSignal]).andReturn([RACSignal empty]);
  contentFetchers = @{
    @"mockedContentFetcher": contentFetcher
  };
  compositeContentFetcher =
      [[BZRCompositeContentFetcher alloc] initWithContentFetchers:contentFetchers];
});

context(@"getting bundle of the product content", ^{
  it(@"should send nil if the underlying fetcher is not registered", ^{
    BZRProduct *product = BZRProductWithIdentifierAndContent(@"foo");
    OCMStub([product.contentFetcherParameters type]).andReturn(@"InvalidContentFetcher");

    auto recorder = [[compositeContentFetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[[NSNull null]]);
  });

  it(@"should send the bundle of the product content with the right fetcher", ^{
    BZRProduct *product = BZRProductWithIdentifierAndContent(@"foo");
    OCMStub([product.contentFetcherParameters type]).andReturn(@"mockedContentFetcher");

    NSBundle *bundle = OCMClassMock([NSBundle class]);
    OCMStub([contentFetchers[@"mockedContentFetcher"] contentBundleForProduct:product])
        .andReturn([RACSignal return:bundle]);

    auto recorder = [[compositeContentFetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[bundle]);
  });
});

context(@"fetching content", ^{
  it(@"should err when contentFetcherParameters type is not registered", ^{
    BZRProduct *product = BZRProductWithIdentifierAndContent(@"foo");
    OCMStub(product.contentFetcherParameters.type).andReturn(@"notRegisteredContentFetcher");

    auto recorder = [[compositeContentFetcher fetchProductContent:product] testRecorder];

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

      auto recorder = [[compositeContentFetcher fetchProductContent:product] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[progress]);
    });

    it(@"should err when the underlying content fetcher errs", ^{
      NSError *fetchContentError = OCMClassMock([NSError class]);
      OCMStub([contentFetcher fetchProductContent:OCMOCK_ANY])
          .andReturn([RACSignal error:fetchContentError]);

      RACSignal *fetchingContent = [compositeContentFetcher fetchProductContent:product];

      expect(fetchingContent).will.sendError(fetchContentError);
    });

    it(@"should send event when the underlying content fetcher errs", ^{
      NSError *fetchContentError = [NSError lt_errorWithCode:1337];
      OCMStub([contentFetcher fetchProductContent:OCMOCK_ANY])
          .andReturn([RACSignal error:fetchContentError]);

      auto recorder = [compositeContentFetcher.eventsSignal testRecorder];
      RACSignal *fetchingContent = [compositeContentFetcher fetchProductContent:product];

      expect(fetchingContent).will.sendError(fetchContentError);
      expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
        return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] &&
            event.eventError.code == BZRErrorCodeFetchingProductContentFailed &&
            event.eventError.lt_underlyingError.code == 1337;
      });
    });
  });
});

SpecEnd
