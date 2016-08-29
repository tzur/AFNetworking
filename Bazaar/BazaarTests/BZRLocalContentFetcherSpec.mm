// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalContentFetcher.h"

#import "BZRLocalContentFetcherParameters.h"
#import "BZRProduct.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

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

  beforeEach(^{
    URL = [NSURL URLWithString:@"file://local/path/toContent/content.zip"];
    fileManager = OCMClassMock([NSFileManager class]);
    fetcher = [[BZRLocalContentFetcher alloc] initWithFileManager:fileManager];
  });

  it(@"should raise exception for invalid content fetcher parameters", ^{
    BZRContentFetcherParameters *parameters = OCMClassMock([BZRContentFetcherParameters class]);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
    expect(^{
      [fetcher fetchContentForProduct:product];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise exception if URL does not reference a local file", ^{
    BZRLocalContentFetcherParameters *parameters =
        OCMClassMock([BZRLocalContentFetcherParameters class]);
    OCMStub([parameters URL]).andReturn([NSURL URLWithString:@"http://remote/content.zip"]);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
    expect(^{
      [fetcher fetchContentForProduct:product];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should send error when file deletion failed", ^{
    BZRLocalContentFetcherParameters *parameters =
        OCMClassMock([BZRLocalContentFetcherParameters class]);
    OCMStub([parameters URL]).andReturn(URL);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
    id errorMock = OCMClassMock([NSError class]);
    RACSignal *errorSignal = [RACSignal error:errorMock];
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn(errorSignal);

    RACSignal *signal = [fetcher fetchContentForProduct:product];

    expect(signal).will.sendError(errorMock);
  });

  it(@"should send error when copy file failed", ^{
    BZRLocalContentFetcherParameters *parameters =
        OCMClassMock([BZRLocalContentFetcherParameters class]);
    OCMStub([parameters URL]).andReturn(URL);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
    id errorMock = OCMClassMock([NSError class]);
    OCMStub([fileManager copyItemAtURL:OCMOCK_ANY toURL:OCMOCK_ANY error:[OCMArg setTo:errorMock]]);

    RACSignal *signal = [fetcher fetchContentForProduct:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeCopyProductContentFailed;
    });
  });

  it(@"should send correct LTPath when file was copied successfuly", ^{
    BZRLocalContentFetcherParameters *parameters =
    OCMClassMock([BZRLocalContentFetcherParameters class]);
    OCMStub([parameters URL]).andReturn(URL);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([fileManager copyItemAtURL:OCMOCK_ANY toURL:OCMOCK_ANY error:[OCMArg setTo:nil]]);
    LTPath *ltPath = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
        andRelativePath:[[URL absoluteString] lastPathComponent]];

    LLSignalTestRecorder *recorder = [[fetcher fetchContentForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[ltPath]);
  });
});

SpecEnd
