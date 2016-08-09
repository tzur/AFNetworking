// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentMultiProvider.h"

#import "BZRContentProviderParameters.h"
#import "BZRProduct.h"
#import "BZRProductContentMultiProviderParameters.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

/// Creates a new \c BZRProductContentMultiProviderParameters with \c providerName as the key to an
/// entry of a provider in the collection of providers of \c BZRProductContentMultiProvider.
BZRProductContentMultiProviderParameters *BZRMultiProviderParametersWithUnderlyingProviderName
    (NSString *providerName) {
  NSDictionary<NSString *, NSObject *> *dictionaryValue = @{
    @instanceKeypath(BZRProductContentMultiProviderParameters, contentProviderName): providerName,
    @instanceKeypath(BZRProductContentMultiProviderParameters, parametersForContentProvider):
         OCMClassMock([BZRContentProviderParameters class])
  };

  return [BZRProductContentMultiProviderParameters modelWithDictionary:dictionaryValue error:nil];
}

SpecBegin(BZRProductContentMultiProvider)

context(@"expected parameters class", ^{
  it(@"should return a non-nil class from expectedParametersClass", ^{
    expect([BZRProductContentMultiProvider expectedParametersClass]).notTo.beNil();
  });
});

context(@"fetching with underlying content provider", ^{
  __block NSString *contentProviderName;
  __block NSDictionary<NSString *, id<BZRProductContentProvider>> *contentProviders;
  __block id<BZRProductContentProvider> underlyingContentProvider;
  __block BZRProductContentMultiProvider *multiProvider;

  beforeEach(^{
    contentProviderName = @"foo";
    underlyingContentProvider = OCMProtocolMock(@protocol(BZRProductContentProvider));
  });

  it(@"should raise exception for invalid content provider parameters", ^{
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"baz",
        OCMClassMock([BZRContentProviderParameters class]));
    multiProvider = [[BZRProductContentMultiProvider alloc] initWithContentProviders:@{}];
    expect(^{
      [multiProvider fetchContentForProduct:product];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should send error when content provider not found", ^{
    BZRProductContentMultiProviderParameters *multiProviderParameters =
        BZRMultiProviderParametersWithUnderlyingProviderName(contentProviderName);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"baz", multiProviderParameters);

    multiProvider = [[BZRProductContentMultiProvider alloc] initWithContentProviders:@{}];
    RACSignal *signal = [multiProvider fetchContentForProduct:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeProductContentProviderNotRegistered;
    });
  });

  it(@"should send error when underlying content provider parameters aren't valid", ^{
    NSError *underlyingError = OCMClassMock([NSError class]);
    BZRProduct *product = OCMClassMock([BZRProduct class]);
    OCMStub([product productWithContentProviderParameters:OCMOCK_ANY
                                                    error:[OCMArg setTo:underlyingError]]);
    BZRProductContentMultiProviderParameters *multiProviderParameters =
        BZRMultiProviderParametersWithUnderlyingProviderName(contentProviderName);
    OCMStub([product contentProviderParameters]).andReturn(multiProviderParameters);

    contentProviders = @{contentProviderName: underlyingContentProvider};
    multiProvider =
        [[BZRProductContentMultiProvider alloc] initWithContentProviders:contentProviders];
    RACSignal *signal = [multiProvider fetchContentForProduct:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain &&
          error.code == BZRErrorCodeInvalidUnderlyingContentProviderParameters &&
          error.lt_underlyingError == underlyingError;
    });
  });

  it(@"should send error when received underlying content provider parameters don't match the "
     "parameters' class expected by the underlying content provider", ^{
    BZRProductContentMultiProviderParameters *multiProviderParameters =
        BZRMultiProviderParametersWithUnderlyingProviderName(contentProviderName);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"baz", multiProviderParameters);

    contentProviders = @{contentProviderName: underlyingContentProvider};
    multiProvider =
        [[BZRProductContentMultiProvider alloc] initWithContentProviders:contentProviders];
    RACSignal *signal = [multiProvider fetchContentForProduct:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain &&
      error.code == BZRErrorCodeUnexpectedUnderlyingContentProviderParametersClass;
    });
  });

  it(@"should send same values as underlying content provider's signal", ^{
    BZRProductContentMultiProviderParameters *multiProviderParameters =
        BZRMultiProviderParametersWithUnderlyingProviderName(contentProviderName);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"baz", multiProviderParameters);
    RACSignal *signal = [RACSignal return:@"bar"];
    OCMStub([underlyingContentProvider fetchContentForProduct:OCMOCK_ANY])
        .andReturn(signal);
    OCMStub([underlyingContentProvider expectedParametersClass])
        .andReturn([OCMClassMock([BZRContentProviderParameters class]) class]);

    contentProviders = @{contentProviderName: underlyingContentProvider};
    multiProvider =
        [[BZRProductContentMultiProvider alloc] initWithContentProviders:contentProviders];
    LLSignalTestRecorder *recorder = [[multiProvider fetchContentForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@"bar"]);
  });

  it(@"should send complete when underlying content provider's signal completes", ^{
    BZRProductContentMultiProviderParameters *multiProviderParameters =
        BZRMultiProviderParametersWithUnderlyingProviderName(contentProviderName);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"baz", multiProviderParameters);
    OCMStub([underlyingContentProvider fetchContentForProduct:OCMOCK_ANY])
        .andReturn([RACSignal empty]);
    OCMStub([underlyingContentProvider expectedParametersClass])
        .andReturn([OCMClassMock([BZRContentProviderParameters class]) class]);

    contentProviders = @{contentProviderName: underlyingContentProvider};
    multiProvider =
        [[BZRProductContentMultiProvider alloc] initWithContentProviders:contentProviders];
    LLSignalTestRecorder *recorder = [[multiProvider fetchContentForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValuesWithCount(0);
  });

  it(@"should send error when underlying content provider's signal sends error", ^{
    BZRProductContentMultiProviderParameters *multiProviderParameters =
        BZRMultiProviderParametersWithUnderlyingProviderName(contentProviderName);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"baz", multiProviderParameters);
    NSError *error = OCMClassMock([NSError class]);
    RACSignal *signal = [RACSignal error:error];
    OCMStub([underlyingContentProvider fetchContentForProduct:OCMOCK_ANY])
        .andReturn(signal);
    OCMStub([underlyingContentProvider expectedParametersClass])
        .andReturn([OCMClassMock([BZRContentProviderParameters class]) class]);

    contentProviders = @{contentProviderName: underlyingContentProvider};
    multiProvider =
        [[BZRProductContentMultiProvider alloc] initWithContentProviders:contentProviders];
    LLSignalTestRecorder *recorder = [[multiProvider fetchContentForProduct:product] testRecorder];

    expect(recorder).will.sendError(error);
  });
});

SpecEnd
