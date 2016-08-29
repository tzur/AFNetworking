// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentMultiFetcher.h"

#import "BZRContentFetcherParameters.h"
#import "BZRProduct.h"
#import "BZRProductContentMultiFetcherParameters.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

/// Creates a new \c BZRProductContentMultiFetcherParameters with \c fetcherName as the key to an
/// entry of a fetcher in the collection of fetchers of \c BZRProductContentMultiFetcher.
BZRProductContentMultiFetcherParameters *BZRMultiFetcherParametersWithUnderlyingFetcherName
    (NSString *fetcherName) {
  NSDictionary<NSString *, NSObject *> *dictionaryValue = @{
    @instanceKeypath(BZRProductContentMultiFetcherParameters, contentFetcherName): fetcherName,
    @instanceKeypath(BZRProductContentMultiFetcherParameters, parametersForContentFetcher):
         OCMClassMock([BZRContentFetcherParameters class])
  };

  return [BZRProductContentMultiFetcherParameters modelWithDictionary:dictionaryValue error:nil];
}

SpecBegin(BZRProductContentMultiFetcher)

context(@"expected parameters class", ^{
  it(@"should return a non-nil class from expectedParametersClass", ^{
    expect([BZRProductContentMultiFetcher expectedParametersClass]).notTo.beNil();
  });
});

context(@"fetching with underlying content fetcher", ^{
  __block NSString *contentFetcherName;
  __block NSDictionary<NSString *, id<BZRProductContentFetcher>> *contentFetchers;
  __block id<BZRProductContentFetcher> underlyingContentFetcher;
  __block BZRProductContentMultiFetcher *multiFetcher;

  beforeEach(^{
    contentFetcherName = @"foo";
    underlyingContentFetcher = OCMProtocolMock(@protocol(BZRProductContentFetcher));
  });

  it(@"should raise exception for invalid content fetcher parameters", ^{
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"baz",
        OCMClassMock([BZRContentFetcherParameters class]));
    multiFetcher = [[BZRProductContentMultiFetcher alloc] initWithContentFetchers:@{}];
    expect(^{
      [multiFetcher fetchContentForProduct:product];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should send error when content fetcher not found", ^{
    BZRProductContentMultiFetcherParameters *multiFetcherParameters =
        BZRMultiFetcherParametersWithUnderlyingFetcherName(contentFetcherName);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"baz", multiFetcherParameters);

    multiFetcher = [[BZRProductContentMultiFetcher alloc] initWithContentFetchers:@{}];
    RACSignal *signal = [multiFetcher fetchContentForProduct:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeProductContentFetcherNotRegistered;
    });
  });

  it(@"should send error when underlying content fetcher parameters aren't valid", ^{
    NSError *underlyingError = OCMClassMock([NSError class]);
    BZRProduct *product = OCMClassMock([BZRProduct class]);
    OCMStub([product productWithContentFetcherParameters:OCMOCK_ANY
                                                    error:[OCMArg setTo:underlyingError]]);
    BZRProductContentMultiFetcherParameters *multiFetcherParameters =
        BZRMultiFetcherParametersWithUnderlyingFetcherName(contentFetcherName);
    OCMStub([product contentFetcherParameters]).andReturn(multiFetcherParameters);

    contentFetchers = @{contentFetcherName: underlyingContentFetcher};
    multiFetcher =
        [[BZRProductContentMultiFetcher alloc] initWithContentFetchers:contentFetchers];
    RACSignal *signal = [multiFetcher fetchContentForProduct:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain &&
          error.code == BZRErrorCodeInvalidUnderlyingContentFetcherParameters &&
          error.lt_underlyingError == underlyingError;
    });
  });

  it(@"should send error when received underlying content fetcher parameters don't match the "
     "parameters' class expected by the underlying content fetcher", ^{
    BZRProductContentMultiFetcherParameters *multiFetcherParameters =
        BZRMultiFetcherParametersWithUnderlyingFetcherName(contentFetcherName);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"baz", multiFetcherParameters);

    contentFetchers = @{contentFetcherName: underlyingContentFetcher};
    multiFetcher =
        [[BZRProductContentMultiFetcher alloc] initWithContentFetchers:contentFetchers];
    RACSignal *signal = [multiFetcher fetchContentForProduct:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain &&
      error.code == BZRErrorCodeUnexpectedUnderlyingContentFetcherParametersClass;
    });
  });

  it(@"should send same values as underlying content fetcher's signal", ^{
    BZRProductContentMultiFetcherParameters *multiFetcherParameters =
        BZRMultiFetcherParametersWithUnderlyingFetcherName(contentFetcherName);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"baz", multiFetcherParameters);
    RACSignal *signal = [RACSignal return:@"bar"];
    OCMStub([underlyingContentFetcher fetchContentForProduct:OCMOCK_ANY])
        .andReturn(signal);
    OCMStub([underlyingContentFetcher expectedParametersClass])
        .andReturn([OCMClassMock([BZRContentFetcherParameters class]) class]);

    contentFetchers = @{contentFetcherName: underlyingContentFetcher};
    multiFetcher =
        [[BZRProductContentMultiFetcher alloc] initWithContentFetchers:contentFetchers];
    LLSignalTestRecorder *recorder = [[multiFetcher fetchContentForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@"bar"]);
  });

  it(@"should send complete when underlying content fetcher's signal completes", ^{
    BZRProductContentMultiFetcherParameters *multiFetcherParameters =
        BZRMultiFetcherParametersWithUnderlyingFetcherName(contentFetcherName);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"baz", multiFetcherParameters);
    OCMStub([underlyingContentFetcher fetchContentForProduct:OCMOCK_ANY])
        .andReturn([RACSignal empty]);
    OCMStub([underlyingContentFetcher expectedParametersClass])
        .andReturn([OCMClassMock([BZRContentFetcherParameters class]) class]);

    contentFetchers = @{contentFetcherName: underlyingContentFetcher};
    multiFetcher =
        [[BZRProductContentMultiFetcher alloc] initWithContentFetchers:contentFetchers];
    LLSignalTestRecorder *recorder = [[multiFetcher fetchContentForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValuesWithCount(0);
  });

  it(@"should send error when underlying content fetcher's signal sends error", ^{
    BZRProductContentMultiFetcherParameters *multiFetcherParameters =
        BZRMultiFetcherParametersWithUnderlyingFetcherName(contentFetcherName);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"baz", multiFetcherParameters);
    NSError *error = OCMClassMock([NSError class]);
    RACSignal *signal = [RACSignal error:error];
    OCMStub([underlyingContentFetcher fetchContentForProduct:OCMOCK_ANY])
        .andReturn(signal);
    OCMStub([underlyingContentFetcher expectedParametersClass])
        .andReturn([OCMClassMock([BZRContentFetcherParameters class]) class]);

    contentFetchers = @{contentFetcherName: underlyingContentFetcher};
    multiFetcher =
        [[BZRProductContentMultiFetcher alloc] initWithContentFetchers:contentFetchers];
    LLSignalTestRecorder *recorder = [[multiFetcher fetchContentForProduct:product] testRecorder];

    expect(recorder).will.sendError(error);
  });
});

SpecEnd
