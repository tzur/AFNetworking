// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRFallbackContentFetcher.h"

#import "BZRCompositeContentFetcher.h"
#import "BZRContentFetcherParameters.h"
#import "BZRDummyContentFetcher.h"
#import "BZRProduct.h"
#import "BZRProductContentFetcher.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRFallbackContentFetcher)

__block BZRContentFetcherParameters *firstFetcherParameters;
__block BZRContentFetcherParameters *secondFetcherParameters;
__block BZRCompositeContentFetcher *compositeContentFetcher;
__block BZRFallbackContentFetcher *fallbackContentFetcher;
__block BZRProduct *product;

beforeEach(^{
  compositeContentFetcher = OCMClassMock([BZRCompositeContentFetcher class]);
  fallbackContentFetcher =
      [[BZRFallbackContentFetcher alloc] initWithCompositeContentFetcher:compositeContentFetcher];

  firstFetcherParameters = OCMClassMock([BZRContentFetcherParameters class]);
  secondFetcherParameters = OCMClassMock([BZRContentFetcherParameters class]);
  auto fetchersParameters = @[firstFetcherParameters, secondFetcherParameters];

  BZRFallbackContentFetcherParameters *parameters =
      OCMClassMock([BZRFallbackContentFetcherParameters class]);
  OCMStub([parameters fetchersParameters]).andReturn(fetchersParameters);

  product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
});

context(@"fetching content", ^{
  it(@"should send error for invalid content fetcher parameters", ^{
    BZRContentFetcherParameters *parameters = OCMClassMock([BZRContentFetcherParameters class]);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"foo", parameters);

    auto recorder = [[fallbackContentFetcher fetchProductContent:product] testRecorder];

    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidContentFetcherParameters;
    });
  });

  it(@"should send error if the fetchers parameters list is empty", ^{
    BZRFallbackContentFetcherParameters *parameters =
        OCMClassMock([BZRFallbackContentFetcherParameters class]);
    OCMStub([parameters fetchersParameters]).andReturn(@[]);
    product = BZRProductWithIdentifierAndParameters(@"foo", parameters);

    auto recorder = [[fallbackContentFetcher fetchProductContent:product] testRecorder];

    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidContentFetcherParameters;
    });
  });

  it(@"should err if all the fetching attempts failed", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMExpect([compositeContentFetcher fetchProductContent:
        [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
          return product.contentFetcherParameters == firstFetcherParameters;
        }]]).andReturn([RACSignal error:error]);
    OCMExpect([compositeContentFetcher fetchProductContent:
        [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
          return product.contentFetcherParameters == secondFetcherParameters;
        }]]).andReturn([RACSignal error:error]);

    auto recorder = [[fallbackContentFetcher fetchProductContent:product] testRecorder];

    expect(recorder).will.sendError(error);
    OCMVerifyAll(compositeContentFetcher);
  });

  it(@"should not call the next fetcher if the first fetcher has completed successfully", ^{
    auto progress = [[LTProgress alloc] initWithProgress:0.1];
    OCMExpect([compositeContentFetcher fetchProductContent:
        [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
          return product.contentFetcherParameters == firstFetcherParameters;
        }]]).andReturn([RACSignal return:progress]);
    OCMReject([compositeContentFetcher fetchProductContent:OCMOCK_ANY]);

    auto recorder = [[fallbackContentFetcher fetchProductContent:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[progress]);
    OCMVerifyAll(compositeContentFetcher);
  });

  it(@"should call the next fetcher if the first fetcher sent error", ^{
    OCMExpect([compositeContentFetcher fetchProductContent:
        [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
          return product.contentFetcherParameters == firstFetcherParameters;
        }]]).andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
    auto progress = [[LTProgress alloc] initWithProgress:0.1];
    OCMExpect([compositeContentFetcher fetchProductContent:
        [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
          return product.contentFetcherParameters == secondFetcherParameters;
        }]]).andReturn([RACSignal return:progress]);

    auto recorder = [[fallbackContentFetcher fetchProductContent:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[progress]);
    OCMVerifyAll(compositeContentFetcher);
  });
});

context(@"getting content bundle", ^{
  it(@"should send nil if all the fetchers sent nil", ^{
    OCMExpect([compositeContentFetcher contentBundleForProduct:
        [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
          return product.contentFetcherParameters == firstFetcherParameters;
        }]]).andReturn([RACSignal return:nil]);
    OCMExpect([compositeContentFetcher contentBundleForProduct:
        [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
          return product.contentFetcherParameters == secondFetcherParameters;
        }]]).andReturn([RACSignal return:nil]);

    auto recorder = [[fallbackContentFetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).will.sendValues(@[[NSNull null]]);
    OCMVerifyAll(compositeContentFetcher);
  });

  it(@"should not call the next fetcher if the first fetcher sent a bundle", ^{
    BZRContentFetcherParameters *thirdFetcherParameters =
        OCMClassMock([BZRContentFetcherParameters class]);
    auto fetchersParameters = @[
        firstFetcherParameters,
        secondFetcherParameters,
        thirdFetcherParameters
    ];

    BZRFallbackContentFetcherParameters *parameters =
        OCMClassMock([BZRFallbackContentFetcherParameters class]);
    OCMStub([parameters fetchersParameters]).andReturn(fetchersParameters);

    product = BZRProductWithIdentifierAndParameters(@"foo", parameters);

    NSBundle *bundle = OCMClassMock([NSBundle class]);
    OCMExpect([compositeContentFetcher contentBundleForProduct:
        [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
          return product.contentFetcherParameters == firstFetcherParameters;
        }]]).andReturn([RACSignal return:bundle]);

    // Due to an issue with concat + take operators in ReactiveCocoa, the second signal will be
    // subscribed to even if the first one sent value. The expected behavior is that the second
    // signal be rejected as well.
    // @see https://github.com/ReactiveCocoa/ReactiveCocoa/pull/2548
    OCMExpect([compositeContentFetcher contentBundleForProduct:OCMOCK_ANY]);
    OCMReject([compositeContentFetcher contentBundleForProduct:OCMOCK_ANY]);

    auto recorder = [[fallbackContentFetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[bundle]);
    OCMVerifyAll(compositeContentFetcher);
  });

  it(@"should call the next fetcher if the first fetcher sent nil", ^{
    NSBundle *bundle = OCMClassMock([NSBundle class]);
    OCMExpect([compositeContentFetcher contentBundleForProduct:
        [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
          return product.contentFetcherParameters == firstFetcherParameters;
        }]]).andReturn([RACSignal return:nil]);
    OCMExpect([compositeContentFetcher contentBundleForProduct:
        [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
          return product.contentFetcherParameters == secondFetcherParameters;
        }]]).andReturn([RACSignal return:bundle]);

    auto recorder = [[fallbackContentFetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[bundle]);
    OCMVerifyAll(compositeContentFetcher);
  });
});

context(@"content fetcher parameters specify a single content fetcher", ^{
  beforeEach(^{
    auto fetchersParameters = @[firstFetcherParameters];
    BZRFallbackContentFetcherParameters *parameters =
        OCMClassMock([BZRFallbackContentFetcherParameters class]);
    OCMStub([parameters fetchersParameters]).andReturn(fetchersParameters);
    product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
  });

  context(@"fetching content", ^{
    it(@"should fetch content with the fetcher parameters", ^{
      auto progress = [[LTProgress alloc] initWithProgress:0.1];
      OCMExpect([compositeContentFetcher fetchProductContent:
          [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
            return product.contentFetcherParameters == firstFetcherParameters;
          }]]).andReturn([RACSignal return:progress]);
      OCMReject([compositeContentFetcher fetchProductContent:OCMOCK_ANY]);

      auto recorder = [[fallbackContentFetcher fetchProductContent:product] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[progress]);
      OCMVerifyAll(compositeContentFetcher);
    });

    it(@"should err if the underlying fetcher errs", ^{
      auto error = [NSError lt_errorWithCode:1337];
      OCMExpect([compositeContentFetcher fetchProductContent:
          [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
            return product.contentFetcherParameters == firstFetcherParameters;
          }]]).andReturn([RACSignal error:error]);
      OCMReject([compositeContentFetcher fetchProductContent:OCMOCK_ANY]);

      auto recorder = [[fallbackContentFetcher fetchProductContent:product] testRecorder];

      expect(recorder).will.sendError(error);
      OCMVerifyAll(compositeContentFetcher);
    });
  });

  context(@"getting content bundle", ^{
    it(@"should send bundle sent by the underlying fetcher", ^{
      NSBundle *bundle = OCMClassMock([NSBundle class]);
      OCMExpect([compositeContentFetcher contentBundleForProduct:
          [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
            return product.contentFetcherParameters == firstFetcherParameters;
          }]]).andReturn([RACSignal return:bundle]);
      OCMReject([compositeContentFetcher contentBundleForProduct:OCMOCK_ANY]);

      auto recorder = [[fallbackContentFetcher contentBundleForProduct:product] testRecorder];

      expect(recorder).will.sendValues(@[bundle]);
      OCMVerifyAll(compositeContentFetcher);
    });
  });
});

SpecEnd

SpecBegin(BZRFallbackContentFetcherParameters)

__block NSDictionary<NSString *, NSString *> *fooFetcherParametersDictionary;
__block NSDictionary<NSString *, NSString *> *barFetcherParametersDictionary;
__block BZRDummyContentFetcherParameters *fooFetcherParameters;
__block BZRDummyContentFetcherParameters *barFetcherParameters;
__block NSArray<BZRContentFetcherParameters *> *fetchersParameters;

beforeEach(^{
  fooFetcherParametersDictionary = @{@"type": @"BZRDummyContentFetcher", @"value": @"foo"};
  barFetcherParametersDictionary = @{@"type": @"BZRDummyContentFetcher", @"value": @"bar"};
  fooFetcherParameters = [[BZRDummyContentFetcherParameters alloc] initWithValue:@"foo"];
  barFetcherParameters = [[BZRDummyContentFetcherParameters alloc] initWithValue:@"bar"];
  fetchersParameters = @[fooFetcherParameters, barFetcherParameters];
});

it(@"should correctly convert BZRFallbackContentFetcherParameters instance to JSON dictionary", ^{
  auto dictionaryValue = @{
    @instanceKeypath(BZRFallbackContentFetcherParameters, type): @"BZRFallbackContentFetcher",
    @instanceKeypath(BZRFallbackContentFetcherParameters, fetchersParameters): fetchersParameters
  };

  NSError *error;
  auto parameters = [[BZRFallbackContentFetcherParameters alloc] initWithDictionary:dictionaryValue
                                                                              error:&error];
  expect(error).to.beNil();

  auto JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:parameters];
  expect(JSONDictionary[@instanceKeypath(BZRFallbackContentFetcherParameters, fetchersParameters)])
      .to.equal(@[fooFetcherParametersDictionary, barFetcherParametersDictionary]);
});

it(@"should correctly convert from JSON dictionary to BZRFallbackContentFetcherParameters", ^{
  auto JSONDictionary = @{
    @"type": @"BZRFallbackContentFetcher",
    @"fetchersParameters": @[fooFetcherParametersDictionary, barFetcherParametersDictionary]
  };

  NSError *error;
  BZRFallbackContentFetcherParameters *parameters =
      [MTLJSONAdapter modelOfClass:[BZRFallbackContentFetcherParameters class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(parameters.fetchersParameters).to.equal(@[fooFetcherParameters, barFetcherParameters]);
});

SpecEnd
