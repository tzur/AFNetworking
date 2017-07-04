// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRRemoteContentFetcher.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPResponse.h>
#import <LTKit/LTProgress.h>

#import "BZRProduct.h"
#import "BZRProductContentManager.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

SpecBegin(BZRRemoteContentFetcher)

context(@"expected parameters class", ^{
  it(@"should return the class BZRRemoteContentFetcherParameters from expectedParametersClass", ^{
    expect([BZRRemoteContentFetcher expectedParametersClass]).notTo.beNil();
  });
});

context(@"fetching product", ^{
  __block NSURL *URL;
  __block FBRHTTPClient *HTTPClient;
  __block NSFileManager *fileManager;
  __block BZRProductContentManager *contentManager;
  __block BZRRemoteContentFetcher *fetcher;
  __block BZRProduct *product;

  beforeEach(^{
    URL = [NSURL URLWithString:@"https://foo/bar/content.zip"];
    HTTPClient = OCMClassMock([FBRHTTPClient class]);
    fileManager = OCMClassMock([NSFileManager class]);
    contentManager = OCMClassMock([BZRProductContentManager class]);
    fetcher = [[BZRRemoteContentFetcher alloc] initWithFileManager:fileManager
                                                    contentManager:contentManager
                                                        HTTPClient:HTTPClient];
    BZRRemoteContentFetcherParameters *parameters =
        OCMClassMock([BZRRemoteContentFetcherParameters class]);
    OCMStub([parameters URL]).andReturn(URL);
    product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
  });

  context(@"error handling", ^{
    __block NSError *error;

    beforeEach(^{
      error = [NSError lt_errorWithCode:1337];
    });

    it(@"should send error for invalid content fetcher parameters", ^{
      BZRContentFetcherParameters *parameters = OCMClassMock([BZRContentFetcherParameters class]);
      BZRProduct *product = BZRProductWithIdentifierAndParameters(@"foo", parameters);

      RACSignal *signal = [fetcher fetchProductContent:product];

      expect(signal).will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidContentFetcherParameters;
      });
    });

    it(@"should send error if URL scheme is not HTTPS or HTTP", ^{
      BZRRemoteContentFetcherParameters *parameters =
      OCMClassMock([BZRRemoteContentFetcherParameters class]);
      OCMStub([parameters URL]).andReturn([NSURL URLWithString:@"ftp://remote/content.zip"]);
      BZRProduct *product = BZRProductWithIdentifierAndParameters(@"foo", parameters);

      RACSignal *signal = [fetcher fetchProductContent:product];

      expect(signal).will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidContentFetcherParameters;
      });
    });

    it(@"should send error when HTTP client failed to download", ^{
      OCMStub([HTTPClient GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:nil])
          .andReturn([RACSignal error:error]);
      OCMStub([contentManager extractContentOfProduct:OCMOCK_ANY fromArchive:OCMOCK_ANY
                                        intoDirectory:OCMOCK_ANY]).andReturn([RACSignal empty]);
      OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);

      RACSignal *signal = [fetcher fetchProductContent:product];

      expect(signal).will.sendError(error);
    });

    it(@"should send error when failed to extract the content", ^{
      FBRHTTPResponse *response = OCMClassMock([FBRHTTPResponse class]);
      OCMStub([response content]).andReturn([NSData data]);
      OCMStub([HTTPClient GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:nil])
          .andReturn([RACSignal return:[[LTProgress alloc] initWithResult:response]]);
      OCMStub([contentManager extractContentOfProduct:OCMOCK_ANY fromArchive:OCMOCK_ANY
                                        intoDirectory:OCMOCK_ANY])
          .andReturn([RACSignal error:error]);
      OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);

      RACSignal *signal = [fetcher fetchProductContent:product];

      expect(signal).will.sendError(error);
    });

    it(@"should send error when failed to delete the archive", ^{
      FBRHTTPResponse *response = OCMClassMock([FBRHTTPResponse class]);
      OCMStub([response content]).andReturn([NSData data]);
      OCMStub([HTTPClient GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:nil])
          .andReturn([RACSignal return:[[LTProgress alloc] initWithResult:response]]);
      OCMStub([contentManager extractContentOfProduct:OCMOCK_ANY fromArchive:OCMOCK_ANY
                                        intoDirectory:OCMOCK_ANY]).andReturn([RACSignal empty]);
      OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY])
          .andReturn([RACSignal error:error]);

      RACSignal *signal = [fetcher fetchProductContent:product];

      expect(signal).will.sendError(error);
    });
  });

  it(@"should send correct progress when the HTTP client sends progress without result", ^{
    OCMStub([contentManager extractContentOfProduct:OCMOCK_ANY fromArchive:OCMOCK_ANY
                                      intoDirectory:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([HTTPClient GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:nil])
        .andReturn([RACSignal return:[[LTProgress alloc] initWithProgress:0.5]]);

    LLSignalTestRecorder *recorder = [[fetcher fetchProductContent:product] testRecorder];

    expect(recorder).will.sendValues(@[[[LTProgress alloc] initWithProgress:0.5]]);
  });

  it(@"should send progress with bundle when finished to extract the content", ^{
    NSBundle *bundle = OCMClassMock([NSBundle class]);
    FBRHTTPResponse *response = OCMClassMock([FBRHTTPResponse class]);
    OCMStub([response content]).andReturn([NSData data]);
    OCMStub([HTTPClient GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:nil])
        .andReturn([RACSignal return:[[LTProgress alloc] initWithResult:response]]);
    OCMStub([contentManager extractContentOfProduct:OCMOCK_ANY fromArchive:OCMOCK_ANY
                                      intoDirectory:OCMOCK_ANY])
        .andReturn([RACSignal return:bundle]);
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.sendValues(@[[[LTProgress alloc] initWithResult:bundle]]);
  });
});

SpecEnd
