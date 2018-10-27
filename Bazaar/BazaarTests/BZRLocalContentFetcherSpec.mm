// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalContentFetcher.h"

#import "BZRProduct.h"
#import "BZRProductContentManager.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

/// Category for testing, exposes the method that creates the inner bundle in
/// \c contentBundleForProduct.
@interface BZRLocalContentFetcher (ForTesting)

/// Returns a new \c NSBundle with the given \c pathToContent.
- (NSBundle *)bundleWithPath:(LTPath *)pathToContent;

@end

SpecBegin(BZRLocalContentFetcher)

context(@"expected parameters class", ^{
  it(@"should return a non-nil class from expectedParametersClass", ^{
    expect([BZRLocalContentFetcher expectedParametersClass]).notTo.beNil();
  });
});

context(@"fetching product", ^{
  __block NSURL *URL;
  __block NSFileManager *fileManager;
  __block BZRLocalContentFetcher *fetcher;
  __block BZRProductContentManager *contentManager;
  __block BZRProduct *product;
  __block BZRLocalContentFetcherParameters *parameters;

  beforeEach(^{
    fileManager = OCMClassMock([NSFileManager class]);
    contentManager = contentManager = OCMClassMock([BZRProductContentManager class]);
    fetcher = [[BZRLocalContentFetcher alloc] initWithFileManager:fileManager
                                                   contentManager:contentManager];

    parameters = OCMClassMock([BZRLocalContentFetcherParameters class]);
    URL = [NSURL URLWithString:@"file:///local/path/toContent/content.zip"];
    OCMStub([parameters URL]).andReturn(URL);
    product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
  });

  it(@"should send error for invalid content fetcher parameters", ^{
    BZRContentFetcherParameters *parameters = OCMClassMock([BZRContentFetcherParameters class]);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"foo", parameters);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidContentFetcherParameters;
    });
  });

  it(@"should send error if URL does not reference a local file", ^{
    BZRLocalContentFetcherParameters *parameters =
        OCMClassMock([BZRLocalContentFetcherParameters class]);
    OCMStub([parameters URL]).andReturn([NSURL URLWithString:@"http://remote/content.zip"]);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"foo", parameters);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidContentFetcherParameters;
    });
  });

  it(@"should send error when file deletion failed", ^{
    id errorMock = OCMClassMock([NSError class]);
    RACSignal *errorSignal = [RACSignal error:errorMock];
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn(errorSignal);
    OCMStub([contentManager extractContentOfProduct:OCMOCK_ANY fromArchive:OCMOCK_ANY
                                      intoDirectory:OCMOCK_ANY]).andReturn([RACSignal empty]);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.sendError(errorMock);
  });

  it(@"should send error when copy file failed", ^{
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
    id errorMock = OCMClassMock([NSError class]);
    OCMStub([fileManager copyItemAtURL:OCMOCK_ANY toURL:OCMOCK_ANY error:[OCMArg setTo:errorMock]]);
    OCMStub([contentManager extractContentOfProduct:OCMOCK_ANY fromArchive:OCMOCK_ANY
                                      intoDirectory:OCMOCK_ANY]).andReturn([RACSignal empty]);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeCopyProductContentFailed;
    });
  });

  it(@"should err when content manager errs", ^{
    NSError *extractContentError = OCMClassMock([NSError class]);
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([fileManager copyItemAtURL:OCMOCK_ANY toURL:OCMOCK_ANY error:nil]);
    OCMStub([contentManager extractContentOfProduct:OCMOCK_ANY fromArchive:OCMOCK_ANY
                                      intoDirectory:OCMOCK_ANY])
        .andReturn([RACSignal error:extractContentError]);

    RACSignal *fetchingContent = [fetcher fetchProductContent:product];

    expect(fetchingContent).will.sendError(extractContentError);
  });

  it(@"should fetch and extract content if content directory doesn't exist", ^{
    NSString *contentFilename = [[URL absoluteString] lastPathComponent];
    LTPath *targetPath = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
                                       andRelativePath:contentFilename];
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([fileManager copyItemAtURL:OCMOCK_ANY toURL:OCMOCK_ANY error:nil]);
    NSBundle *contentBundle = [NSBundle mainBundle];
    OCMStub([contentManager extractContentOfProduct:product.identifier fromArchive:targetPath
                                      intoDirectory:OCMOCK_ANY])
        .andReturn([RACSignal return:contentBundle]);

    LLSignalTestRecorder *recorder = [[fetcher fetchProductContent:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[[[LTProgress alloc] initWithResult:contentBundle]]);
  });
});

context(@"getting bundle of the product content", ^{
  __block NSFileManager *fileManager;
  __block BZRProductContentManager *contentManager;
  __block BZRLocalContentFetcher *fetcher;
  __block BZRProduct *product;

  beforeEach(^{
    fileManager = OCMClassMock([NSFileManager class]);
    contentManager = contentManager = OCMClassMock([BZRProductContentManager class]);
    fetcher = [[BZRLocalContentFetcher alloc] initWithFileManager:fileManager
                                                   contentManager:contentManager];
    BZRLocalContentFetcherParameters *parameters =
        OCMClassMock([BZRLocalContentFetcherParameters class]);
    OCMStub([parameters URL]).andReturn([NSURL URLWithString:@"file://bar.zip"]);
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

SpecBegin(BZRLocalContentFetcherParameters)

__block NSString *localFilePath;
__block NSURL *localFileURL;

beforeEach(^{
  localFilePath = @"file:///foo/file.zip";
  localFileURL = [NSURL URLWithString:localFilePath];
});

it(@"should correctly convert BZRLocalContentFetcherParameters instance to JSON dictionary", ^{
  auto dictionaryValue = @{
    @instanceKeypath(BZRLocalContentFetcherParameters, type): @"BZRLocalContentFetcher",
    @instanceKeypath(BZRLocalContentFetcherParameters, URL): localFileURL,
  };

  NSError *error;
  auto *parameters = [[BZRLocalContentFetcherParameters alloc] initWithDictionary:dictionaryValue
                                                                            error:&error];
  expect(error).to.beNil();

  auto JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:parameters];
  expect(JSONDictionary[@instanceKeypath(BZRLocalContentFetcherParameters, URL)]).to
      .equal(localFilePath);
});

it(@"should correctly convert from JSON dictionary to BZRLocalContentFetcherParameters", ^{
  auto JSONDictionary = @{
    @"type": @"BZRLocalContentFetcher",
    @"URL": localFilePath
  };

  NSError *error;
  BZRLocalContentFetcherParameters *parameters =
      [MTLJSONAdapter modelOfClass:[BZRLocalContentFetcherParameters class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(parameters.URL).to.equal(localFileURL);
});

SpecEnd
