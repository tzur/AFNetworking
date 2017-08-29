// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SKReceiptRefreshRequest+RACSignalSupport.h"

#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(SKReceiptRefreshRequest_RACSignalSupport)

context(@"status signal", ^{
  __block SKReceiptRefreshRequest *request;
  __block LLSignalTestRecorder *recorder;

  beforeEach(^{
    request = [[SKReceiptRefreshRequest alloc] init];
    recorder = [[request statusSignal] testRecorder];
  });

  it(@"should err when the matching delegate method is invoked", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    [request.delegate request:request didFailWithError:error];

    expect(recorder).will.matchError(^BOOL(NSError *signalError) {
      return signalError.lt_isLTDomain &&
          signalError.code == BZRErrorCodeReceiptRefreshFailed &&
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
    SKReceiptRefreshRequest __weak *weakRequest;
    @autoreleasepool {
      SKReceiptRefreshRequest *request = [[SKReceiptRefreshRequest alloc] init];
      weakRequest = request;
      recorder = [[request statusSignal] testRecorder];
    };

    expect(weakRequest).to.beNil();
    expect(recorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });
});

SpecEnd
