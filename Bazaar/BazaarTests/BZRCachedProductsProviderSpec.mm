// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedProductsProvider.h"

#import "BZRProduct.h"
#import "BZRTestUtils.h"

SpecBegin(BZRCachedProductsProvider)

__block id<BZRProductsProvider> underlyingProvider;
__block RACSubject *underlyingProviderErrorsSubject;
__block BZRCachedProductsProvider *productsProvider;
__block BZRProduct *product;

beforeEach(^{
  underlyingProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  underlyingProviderErrorsSubject = [RACSubject subject];
  OCMStub([underlyingProvider nonCriticalErrorsSignal]).andReturn(underlyingProviderErrorsSubject);
  productsProvider =
      [[BZRCachedProductsProvider alloc] initWithUnderlyingProvider:underlyingProvider];
  product = BZRProductWithIdentifier(@"foo");
});

context(@"fetching product list", ^{
  it(@"should err when underlying products provider errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMExpect([underlyingProvider fetchProductList]).andReturn([RACSignal error:error]);

    LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];
    expect(recorder).will.sendError(error);
  });

  it(@"should send non critical error when underlying provider sends non critical error", ^{
    LLSignalTestRecorder *recorder = [productsProvider.nonCriticalErrorsSignal testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];
    [underlyingProviderErrorsSubject sendNext:error];

    expect(recorder).will.sendValues(@[error]);
  });

  it(@"should return list fetched by underlying provider", ^{
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);

    LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@[product]]);
  });

  it(@"should cache the fetched product list", ^{
    OCMExpect([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
    OCMReject([productsProvider fetchProductList]);

    LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];
    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@[product]]);

    recorder = [[productsProvider fetchProductList] testRecorder];
    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@[product]]);
  });

  it(@"should refetch product list if an error occurred during first fetch", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMExpect([underlyingProvider fetchProductList]).andReturn([RACSignal error:error]);
    OCMExpect([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);

    LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];
    expect(recorder).will.sendError(error);

    recorder = [[productsProvider fetchProductList] testRecorder];
    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@[product]]);
  });

  it(@"should not fetch product list twice when two fetch calls are invoked simultaneously", ^{
    OCMExpect([underlyingProvider fetchProductList])
        .andReturn([[RACSignal return:@[product]] deliverOn:[RACScheduler scheduler]]);
    OCMReject([underlyingProvider fetchProductList]);

    LLSignalTestRecorder *firstRecorder = [[productsProvider fetchProductList] testRecorder];
    LLSignalTestRecorder *secondRecorder = [[productsProvider fetchProductList] testRecorder];

    expect(firstRecorder).will.complete();
    expect(firstRecorder).will.sendValues(@[@[product]]);
    expect(secondRecorder).will.complete();
    expect(secondRecorder).will.sendValues(@[@[product]]);
  });

  it(@"should refetech if subscription was disposed while fetching", ^{
    OCMExpect([underlyingProvider fetchProductList])
        .andReturn([[RACSignal return:@[product]] deliverOn:[RACScheduler scheduler]]);
    OCMExpect([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);

    RACDisposable *disposable = [[productsProvider fetchProductList] subscribeNext:^(id) {}];
    [disposable dispose];
    LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@[product]]);
  });
});

SpecEnd
