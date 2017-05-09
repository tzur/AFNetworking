// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentMultiFetcher.h"

#import "BZRDummyContentFetcherParameters.h"
#import "BZRProduct.h"
#import "BZRProductContentMultiFetcherParameters.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

/// Dummy concrete implementation of \c BZRProductContentFetcher used for testing.
@interface BZRDummyContentFetcher : NSObject <BZRProductContentFetcher>
@end

@implementation BZRDummyContentFetcher

- (RACSignal *)fetchContentForProduct:(BZRProduct * __unused)product {
  return [RACSignal empty];
}

+ (Class)expectedParametersClass {
  return [BZRDummyContentFetcherParameters class];
}

@end

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
  __block BZRProduct *product;
  __block id<BZRProductContentFetcher> underlyingContentFetcher;
  __block NSDictionary<NSString *, id<BZRProductContentFetcher>> *contentFetchers;
  __block BZRProductContentMultiFetcher *multiFetcher;

  beforeEach(^{
    contentFetcherName = @"foo";
    BZRProductContentMultiFetcherParameters *multiFetcherParameters =
        BZRMultiFetcherParametersWithUnderlyingFetcherName(contentFetcherName);
    product = BZRProductWithIdentifierAndParameters(@"baz", multiFetcherParameters);

    underlyingContentFetcher = OCMClassMock([BZRDummyContentFetcher class]);
    contentFetchers = @{contentFetcherName: underlyingContentFetcher};
    multiFetcher = [[BZRProductContentMultiFetcher alloc] initWithContentFetchers:contentFetchers];
  });

  it(@"should send error when content fetcher parameters is invalid", ^{
    BZRProduct *productWithInvalidParameters = BZRProductWithIdentifierAndParameters(@"baz",
        OCMClassMock([BZRContentFetcherParameters class]));
    multiFetcher = [[BZRProductContentMultiFetcher alloc] initWithContentFetchers:@{}];
    RACSignal *signal = [multiFetcher fetchContentForProduct:productWithInvalidParameters];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain &&
          error.code == BZRErrorCodeUnexpectedContentFetcherParametersClass;
    });
  });

  it(@"should send error when content fetcher not found", ^{
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

    RACSignal *signal = [multiFetcher fetchContentForProduct:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidContentFetcherParameters &&
          error.lt_underlyingError == underlyingError;
    });
  });

  it(@"should send error when received underlying content fetcher parameters don't match the "
     "parameters' class expected by the underlying content fetcher", ^{
    RACSignal *signal = [multiFetcher fetchContentForProduct:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain &&
          error.code == BZRErrorCodeUnexpectedContentFetcherParametersClass;
    });
  });

  it(@"should send same values as underlying content fetcher's signal", ^{
    OCMStub([underlyingContentFetcher fetchContentForProduct:OCMOCK_ANY])
        .andReturn([RACSignal return:@"bar"]);
    OCMStub([underlyingContentFetcher expectedParametersClass])
        .andReturn([OCMClassMock([BZRContentFetcherParameters class]) class]);

    LLSignalTestRecorder *recorder = [[multiFetcher fetchContentForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@"bar"]);
  });

  it(@"should send error when underlying content fetcher's signal sends error", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingContentFetcher fetchContentForProduct:OCMOCK_ANY])
        .andReturn([RACSignal error:error]);
    OCMStub([underlyingContentFetcher expectedParametersClass])
        .andReturn([OCMClassMock([BZRContentFetcherParameters class]) class]);

    LLSignalTestRecorder *recorder = [[multiFetcher fetchContentForProduct:product] testRecorder];

    expect(recorder).will.sendError(error);
  });
});

SpecEnd
