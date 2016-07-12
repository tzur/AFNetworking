// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SKProductsRequest+RACSignalSupport.h"

#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(SKProductsRequest_RACSignalSupport)

context(@"request signal", ^{
  __block SKProductsRequest *request;
  __block LLSignalTestRecorder *recorder;

  beforeEach(^{
    request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:@"foo"]];
    recorder = [[request bzr_statusSignal] testRecorder];
  });

  it(@"should send the products response when the matching delegate method is invoked", ^{
    id response = OCMClassMock([SKProductsResponse class]);
    [request.delegate productsRequest:request didReceiveResponse:response];

    expect(recorder).will.sendValues(@[response]);
  });

  it(@"should err when the matching delegate method is invoked", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    [request.delegate request:request didFailWithError:error];

    expect(recorder).will.matchError(^BOOL(NSError *signalError) {
      return signalError.lt_isLTDomain &&
          signalError.code == BZRErrorCodeProductsMetadataFetchingFailed &&
          signalError.bzr_productsRequest == request &&
          [signalError.lt_underlyingError isEqual:error];
    });
    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should complete when the matching delegate method is invoked", ^{
    [request.delegate requestDidFinish:request];

    expect(recorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should complete when the request is being deallocated", ^{
    SKProductsRequest __weak *weakRequest;
    @autoreleasepool {
      SKProductsRequest *request =
          [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:@"foo"]];
      weakRequest = request;
      recorder = [[request bzr_statusSignal] testRecorder];
    };

    expect(weakRequest).to.beNil();
    expect(recorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });
});

SpecEnd
