// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRRemoteContentFetcher.h"

#import <Fiber/FBRHTTPClient.h>
#import <FiberTestUtils/FBRHTTPTestUtils.h>
#import <LTKit/LTProgress.h>

#import "BZRProduct.h"
#import "BZRProductContentManager.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

/// Category for testing, exposes the method that creates the inner bundle in
/// \c contentBundleForProduct.
@interface BZRRemoteContentFetcher (ForTesting)

/// Returns a new \c NSBundle with the given \c pathToContent.
- (NSBundle *)bundleWithPath:(LTPath *)pathToContent;

@end

SpecBegin(BZRRemoteContentFetcher)

context(@"expected parameters class", ^{
  it(@"should return the class BZRRemoteContentFetcherParameters from expectedParametersClass", ^{
    expect([BZRRemoteContentFetcher expectedParametersClass]).notTo.beNil();
  });
});

context(@"fetching product", ^{
  __block NSURL *URL;
  __block NSFileManager *fileManager;
  __block BZRProductContentManager *contentManager;
  __block FBRHTTPClient *HTTPClient;
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
      auto response = FBRFakeHTTPResponse(URL.absoluteString, 200, nil, [NSData data]);
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
      auto response = FBRFakeHTTPResponse(URL.absoluteString, 200, nil, [NSData data]);
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
    auto response = FBRFakeHTTPResponse(URL.absoluteString, 200, nil, [NSData data]);
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

context(@"getting bundle of the product content", ^{
  __block NSFileManager *fileManager;
  __block BZRProductContentManager *contentManager;
  __block FBRHTTPClient *HTTPClient;
  __block BZRRemoteContentFetcher *fetcher;
  __block BZRProduct *product;

  beforeEach(^{
    fileManager = OCMClassMock([NSFileManager class]);
    contentManager = OCMClassMock([BZRProductContentManager class]);
    HTTPClient = OCMClassMock([FBRHTTPClient class]);
    fetcher = [[BZRRemoteContentFetcher alloc] initWithFileManager:fileManager
                                                    contentManager:contentManager
                                                        HTTPClient:HTTPClient];

    BZRRemoteContentFetcherParameters *parameters =
        OCMClassMock([BZRRemoteContentFetcherParameters class]);
    OCMStub([parameters URL]).andReturn([NSURL URLWithString:@"http://bar.zip"]);
    product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
  });

  it(@"should send bundle with the content path if the content exists", ^{
    LTPath *contentPath = [LTPath pathWithPath:@"foo"];
    OCMStub([contentManager pathToContentDirectoryOfProduct:product.identifier])
        .andReturn(contentPath);

    NSBundle *bundle = OCMClassMock([NSBundle class]);
    fetcher = OCMPartialMock(fetcher);
    OCMStub([fetcher bundleWithPath:[contentPath pathByAppendingPathComponent:@"bar"]])
        .andReturn(bundle);

    auto recorder = [[fetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).to.sendValues(@[bundle]);
  });

  it(@"should send nil if the content does not exist", ^{
    OCMStub([contentManager pathToContentDirectoryOfProduct:product.identifier]);

    auto recorder = [[fetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).to.sendValues(@[[NSNull null]]);
  });

  it(@"should send nil for invalid content fetcher parameters", ^{
    BZRContentFetcherParameters *parameters = OCMClassMock([BZRContentFetcherParameters class]);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"foo", parameters);

    auto recorder = [[fetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).to.sendValues(@[[NSNull null]]);
  });
});

SpecEnd

SpecBegin(BZRRemoteContentFetcherParameters)

__block NSURL *remoteFileURL;

beforeEach(^{
  remoteFileURL = [NSURL URLWithString:@"http://foo.bar/file.zip"];
});

it(@"should correctly convert BZRRemoteContentFetcherParameters instance to JSON dictionary", ^{
  auto dictionaryValue = @{
    @instanceKeypath(BZRRemoteContentFetcherParameters, type): @"BZRRemoteContentFetcher",
    @instanceKeypath(BZRRemoteContentFetcherParameters, URL): remoteFileURL
  };

  NSError *error;
  auto parameters = [[BZRRemoteContentFetcherParameters alloc] initWithDictionary:dictionaryValue
                                                                            error:&error];
  expect(error).to.beNil();

  auto JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:parameters];
  expect(JSONDictionary[@instanceKeypath(BZRRemoteContentFetcherParameters, URL)]).to
      .equal(remoteFileURL.absoluteString);
});

it(@"should correctly convert from JSON dictionary to BZRRemoteContentFetcherParameters", ^{
  auto JSONDictionary = @{
    @"type": @"BZRRemoteContentFetcher",
    @"URL": remoteFileURL.absoluteString
  };

  NSError *error;
  BZRRemoteContentFetcherParameters *parameters =
      [MTLJSONAdapter modelOfClass:[BZRRemoteContentFetcherParameters class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(parameters.URL).to.equal(remoteFileURL);
});

SpecEnd
