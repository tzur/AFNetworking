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

  it(@"should err with cancelation error when request fails with error that indicates "
     "cancellation", ^{
    NSError *underlyingRefreshReceiptError =
        [NSError errorWithDomain:@"AKAuthenticationError" code:-7003 userInfo:@{}];
    NSError *RefreshReceiptError =
        [NSError errorWithDomain:@"SSErrorDomain" code:16
                        userInfo:@{NSUnderlyingErrorKey: underlyingRefreshReceiptError}];

    [request.delegate request:request didFailWithError:RefreshReceiptError];

    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeOperationCancelled &&
          error.lt_underlyingError == RefreshReceiptError;
    });
    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should err with refresh error when request fails with non-cancellation error", ^{
    NSError *underlyingError = [NSError lt_errorWithCode:1337];

    [request.delegate request:request didFailWithError:underlyingError];

    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeReceiptRefreshFailed &&
          error.lt_underlyingError == underlyingError;
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
