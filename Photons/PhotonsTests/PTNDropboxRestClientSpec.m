// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxRestClient.h"

#import "PTNDropboxFakeDBRestClient.h"
#import "PTNDropboxPathProvider.h"
#import "PTNDropboxTestUtils.h"
#import "PTNProgress.h"
#import "NSError+Photons.h"
#import "PTNDropboxRestClientProvider.h"

SpecBegin(PTNDropboxRestClient)

static NSString * const kDropboxPath = @"/foo/bar";
static NSString * const kRevision = @"baz";
static NSString * const kSizeName = @"xs";
static const PTNDropboxThumbnailSize kSize = PTNDropboxThumbnailSizeExtraSmall;

__block PTNDropboxFakeDBRestClient *dbRestClient;
__block id<PTNDropboxPathProvider> pathProvider;
__block PTNDropboxRestClient *restClient;
__block id<PTNDropboxRestClientProvider> clientProvider;
__block NSError *errorWithPath;
__block NSString *localPath;

beforeEach(^{
  dbRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
  pathProvider = [[PTNDropboxPathProvider alloc] init];
  clientProvider = OCMProtocolMock(@protocol(PTNDropboxRestClientProvider));
  OCMStub([clientProvider ptn_restClient]).andReturn(dbRestClient);
  restClient = [[PTNDropboxRestClient alloc] initWithRestClientProvider:clientProvider
                                                           pathProvider:pathProvider];

  errorWithPath = PTNDropboxErrorWithPathInfo(kDropboxPath);
});

context(@"metadata fetching", ^{
  __block id metadata;

  beforeEach(^{
    metadata = PTNDropboxCreateMetadata(kDropboxPath, kRevision);
  });

  it(@"should fetch metadata", ^{
    RACSignal *values = [restClient fetchMetadata:kDropboxPath revision:kRevision];
    LLSignalTestRecorder *recorder = [values testRecorder];

    expect([dbRestClient didRequestMetadataAtPath:kDropboxPath revision:kRevision]).to.beTruthy();

    [dbRestClient deliverMetadata:metadata];
    expect(recorder).will.sendValues(@[metadata]);
    expect(recorder).will.complete();
  });

  it(@"should fetch metadata again for every subscription", ^{
    clientProvider = OCMProtocolMock(@protocol(PTNDropboxRestClientProvider));
    restClient = [[PTNDropboxRestClient alloc] initWithRestClientProvider:clientProvider
                                                             pathProvider:pathProvider];
    PTNDropboxFakeDBRestClient *firstDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
    PTNDropboxFakeDBRestClient *secondDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];

    RACSignal *values = [restClient fetchMetadata:kDropboxPath revision:kRevision];

    OCMExpect([clientProvider ptn_restClient]).andReturn(firstDBRestClient);
    [values subscribeNext:^(id __unused x) { }];
    expect([firstDBRestClient didRequestMetadataAtPath:kDropboxPath revision:kRevision])
        .to.beTruthy();

    OCMExpect([clientProvider ptn_restClient]).andReturn(secondDBRestClient);
    [values subscribeNext:^(id __unused x) { }];
    expect([secondDBRestClient didRequestMetadataAtPath:kDropboxPath revision:kRevision])
        .to.beTruthy();
  });

  it(@"should not mix metadata requests with the equal parameters", ^{
    clientProvider = OCMProtocolMock(@protocol(PTNDropboxRestClientProvider));
    restClient = [[PTNDropboxRestClient alloc] initWithRestClientProvider:clientProvider
                                                             pathProvider:pathProvider];
    PTNDropboxFakeDBRestClient *firstDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
    PTNDropboxFakeDBRestClient *secondDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];

    RACSignal *values = [restClient fetchMetadata:kDropboxPath revision:kRevision];

    OCMExpect([clientProvider ptn_restClient]).andReturn(firstDBRestClient);
    LLSignalTestRecorder *firstRecorder = [values testRecorder];

    OCMExpect([clientProvider ptn_restClient]).andReturn(secondDBRestClient);
    LLSignalTestRecorder *secondRecorder = [values testRecorder];

    DBMetadata *firstMetadata = PTNDropboxCreateFileMetadata(kDropboxPath, kRevision);
    DBMetadata *secondMetadata = PTNDropboxCreateFileMetadata(kDropboxPath, kRevision);
    [firstDBRestClient deliverMetadata:firstMetadata];
    [secondDBRestClient deliverMetadata:secondMetadata];

    expect(firstRecorder).will.sendValues(@[firstMetadata]);
    expect(secondRecorder).will.sendValues(@[secondMetadata]);
  });

  it(@"should not fetch metadata of other requests", ^{
    NSString *otherPath = @"/bar/baz";
    DBMetadata *otherMetadata = PTNDropboxCreateMetadata(otherPath, kRevision);
    RACSignal *values = [restClient fetchMetadata:kDropboxPath revision:kRevision];
    LLSignalTestRecorder *recorder = [values testRecorder];
    RACSignal *otherValues = [restClient fetchMetadata:otherPath revision:kRevision];
    LLSignalTestRecorder *otherRecorder = [otherValues testRecorder];

    expect([dbRestClient didRequestMetadataAtPath:kDropboxPath revision:kRevision]).to.beTruthy();
    expect([dbRestClient didRequestMetadataAtPath:otherPath revision:kRevision]).to.beTruthy();

    [dbRestClient deliverMetadata:otherMetadata];
    expect(otherRecorder).will.sendValues(@[otherMetadata]);
    expect(otherRecorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should err on metadata fetching failure", ^{
    RACSignal *values = [restClient fetchMetadata:kDropboxPath revision:kRevision];
    LLSignalTestRecorder *recorder = [values testRecorder];
    expect([dbRestClient didRequestMetadataAtPath:kDropboxPath revision:kRevision]).to.beTruthy();

    [dbRestClient deliverMetadataError:errorWithPath];
    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
    });
  });

  it(@"should not err on metadata fetching failure of other requests", ^{
    NSString *otherPath = @"/bar/baz";
    NSError *errorWithOtherPath = PTNDropboxErrorWithPathInfo(otherPath);
    RACSignal *values = [restClient fetchMetadata:kDropboxPath revision:kRevision];
    LLSignalTestRecorder *recorder = [values testRecorder];
    RACSignal *otherValues = [restClient fetchMetadata:otherPath revision:kRevision];
    LLSignalTestRecorder *otherRecorder = [otherValues testRecorder];

    expect([dbRestClient didRequestMetadataAtPath:kDropboxPath revision:kRevision]).to.beTruthy();
    expect([dbRestClient didRequestMetadataAtPath:otherPath revision:kRevision]).to.beTruthy();

    [dbRestClient deliverMetadataError:errorWithOtherPath];
    expect(otherRecorder).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
    });
    expect(recorder).toNot.matchError(^BOOL(NSError * __unused error) {
      return YES;
    });
  });
});

context(@"file fetching", ^{
  beforeEach(^{
    localPath = [pathProvider localPathForFileInPath:kDropboxPath revision:kRevision];
  });

  it(@"should fetch file", ^{
    RACSignal *values = [restClient fetchFile:kDropboxPath revision:kRevision];
    LLSignalTestRecorder *recorder = [values testRecorder];
    expect([dbRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).to.equal(localPath);

    [dbRestClient deliverFile:localPath];
    expect(recorder).will.sendValues(@[[[PTNProgress alloc] initWithResult:localPath]]);
    expect(recorder).will.complete();
  });

  it(@"should fetch file again for every subscription", ^{
    clientProvider = OCMProtocolMock(@protocol(PTNDropboxRestClientProvider));
    restClient = [[PTNDropboxRestClient alloc] initWithRestClientProvider:clientProvider
                                                             pathProvider:pathProvider];
    PTNDropboxFakeDBRestClient *firstDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
    PTNDropboxFakeDBRestClient *secondDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];

    RACSignal *values = [restClient fetchFile:kDropboxPath revision:kRevision];

    OCMExpect([clientProvider ptn_restClient]).andReturn(firstDBRestClient);
    [values subscribeNext:^(id __unused x) { }];
    expect([firstDBRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).to.beTruthy();

    OCMExpect([clientProvider ptn_restClient]).andReturn(secondDBRestClient);
    [values subscribeNext:^(id __unused x) { }];
    expect([secondDBRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).to.beTruthy();
  });

  it(@"should not mix file requests with the equal parameters", ^{
    clientProvider = OCMProtocolMock(@protocol(PTNDropboxRestClientProvider));
    restClient = [[PTNDropboxRestClient alloc] initWithRestClientProvider:clientProvider
                                                             pathProvider:pathProvider];
    PTNDropboxFakeDBRestClient *firstDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
    PTNDropboxFakeDBRestClient *secondDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];

    RACSignal *values = [restClient fetchFile:kDropboxPath revision:kRevision];

    OCMExpect([clientProvider ptn_restClient]).andReturn(firstDBRestClient);
    LLSignalTestRecorder *firstRecorder = [values testRecorder];

    OCMExpect([clientProvider ptn_restClient]).andReturn(secondDBRestClient);
    LLSignalTestRecorder *secondRecorder = [values testRecorder];

    NSString *firstFilePath = [pathProvider localPathForFileInPath:kDropboxPath revision:kRevision];
    NSString *secondFilePath =
        [pathProvider localPathForFileInPath:kDropboxPath revision:kRevision];
    [firstDBRestClient deliverFile:firstFilePath];
    [secondDBRestClient deliverFile:secondFilePath];

    expect(firstRecorder).will.sendValues(@[[[PTNProgress alloc] initWithResult:firstFilePath]]);
    expect(secondRecorder).will.sendValues(@[[[PTNProgress alloc] initWithResult:secondFilePath]]);
  });

  it(@"should not fetch files of other requests", ^{
    NSString *otherPath = @"/bar/baz";
    NSString *otherLocalPath = [pathProvider localPathForFileInPath:otherPath revision:kRevision];
    RACSignal *values = [restClient fetchFile:kDropboxPath revision:kRevision];
    LLSignalTestRecorder *recorder = [values testRecorder];
    RACSignal *otherValues = [restClient fetchFile:otherPath revision:kRevision];
    LLSignalTestRecorder *otherRecorder = [otherValues testRecorder];

    expect([dbRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).to.equal(localPath);
    expect([dbRestClient didRequestFileAtPath:otherPath revision:kRevision])
        .to.equal(otherLocalPath);

    [dbRestClient deliverFile:otherLocalPath];
    expect(otherRecorder).will.sendValues(@[[[PTNProgress alloc] initWithResult:otherLocalPath]]);
    expect(otherRecorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should deliver progress for requested file", ^{
    RACSignal *values = [restClient fetchFile:kDropboxPath revision:kRevision];
    LLSignalTestRecorder *recorder = [values testRecorder];
    expect([dbRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).to.equal(localPath);

    [dbRestClient deliverProgress:0.25 forFile:localPath];
    [dbRestClient deliverProgress:0.5 forFile:localPath];
    [dbRestClient deliverProgress:0.75 forFile:localPath];
    [dbRestClient deliverFile:localPath];
    expect(recorder).will.sendValues(@[
      [[PTNProgress alloc] initWithProgress:@0.25],
      [[PTNProgress alloc] initWithProgress:@0.5],
      [[PTNProgress alloc] initWithProgress:@0.75],
      [[PTNProgress alloc] initWithResult:localPath]
    ]);
    expect(recorder).will.complete();
  });

  it(@"should not deliver progress for files that that were not requested", ^{
    RACSignal *values = [restClient fetchFile:kDropboxPath revision:kRevision];
    LLSignalTestRecorder *recorder = [values testRecorder];
    expect([dbRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).to.equal(localPath);

    [dbRestClient deliverProgress:0.25 forFile:@"/bar/foo"];
    [dbRestClient deliverProgress:0.5 forFile:@"/bar/foo"];
    [dbRestClient deliverProgress:0.75 forFile:@"/bar/foo"];
    [dbRestClient deliverFile:localPath];
    expect(recorder).will.sendValues(@[[[PTNProgress alloc] initWithResult:localPath]]);
    expect(recorder).will.complete();
  });

  it(@"should err on file fetching failure", ^{
    RACSignal *values = [restClient fetchFile:kDropboxPath revision:kRevision];
    LLSignalTestRecorder *recorder = [values testRecorder];
    expect([dbRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).to.equal(localPath);

    [dbRestClient deliverFileError:errorWithPath];
    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
    });
  });

  it(@"should not err on file fetching failure of other requests", ^{
    NSString *otherPath = @"/bar/baz";
    NSError *errorWithOtherPath = PTNDropboxErrorWithPathInfo(otherPath);
    NSString *otherLocalPath = [pathProvider localPathForFileInPath:otherPath revision:kRevision];
    RACSignal *values = [restClient fetchFile:kDropboxPath revision:kRevision];
    LLSignalTestRecorder *recorder = [values testRecorder];
    RACSignal *otherValues = [restClient fetchFile:otherPath revision:kRevision];
    LLSignalTestRecorder *otherRecorder = [otherValues testRecorder];

    expect([dbRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).to.equal(localPath);
    expect([dbRestClient didRequestFileAtPath:otherPath revision:kRevision])
        .to.equal(otherLocalPath);

    [dbRestClient deliverFileError:errorWithOtherPath];
    expect(otherRecorder).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
    });
    expect(recorder).toNot.matchError(^BOOL(NSError * __unused error) {
      return YES;
    });
  });

  it(@"should cancel request upon disposal", ^{
    RACSignal *values = [restClient fetchFile:kDropboxPath revision:kRevision];

    RACDisposable *subscriber = [values subscribeNext:^(id __unused x) {}];
    expect([dbRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).will.beTruthy();

    [subscriber dispose];
    expect([dbRestClient didCancelRequestForFileAtPath:kDropboxPath revision:kRevision])
        .will.beTruthy();
  });
});

context(@"thumbnail fetching", ^{
  __block CGSize size;

  beforeEach(^{
    size = CGSizeMake(32, 32);
    localPath = [pathProvider localPathForThumbnailInPath:kDropboxPath size:size];
  });

  it(@"should fetch thumbnail", ^{
    RACSignal *values = [restClient fetchThumbnail:kDropboxPath size:kSize];
    LLSignalTestRecorder *recorder = [values testRecorder];
    expect([dbRestClient didRequestThumbnailAtPath:kDropboxPath size:kSizeName])
        .to.equal(localPath);

    [dbRestClient deliverThumbnail:localPath];
    expect(recorder).will.sendValues(@[localPath]);
    expect(recorder).will.complete();
  });

  it(@"should fetch thumbnail again for every subscription", ^{
    clientProvider = OCMProtocolMock(@protocol(PTNDropboxRestClientProvider));
    restClient = [[PTNDropboxRestClient alloc] initWithRestClientProvider:clientProvider
                                                             pathProvider:pathProvider];
    PTNDropboxFakeDBRestClient *firstDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
    PTNDropboxFakeDBRestClient *secondDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];

    RACSignal *values = [restClient fetchThumbnail:kDropboxPath size:kSize];

    OCMExpect([clientProvider ptn_restClient]).andReturn(firstDBRestClient);
    [values subscribeNext:^(id __unused x) { }];
    expect([firstDBRestClient didRequestThumbnailAtPath:kDropboxPath size:kSizeName]).to.beTruthy();

    OCMExpect([clientProvider ptn_restClient]).andReturn(secondDBRestClient);
    [values subscribeNext:^(id __unused x) { }];
    expect([secondDBRestClient didRequestThumbnailAtPath:kDropboxPath size:kSizeName])
        .to.beTruthy();
  });

  it(@"should not mix thumbnail requests with the equal parameters", ^{
    clientProvider = OCMProtocolMock(@protocol(PTNDropboxRestClientProvider));
    restClient = [[PTNDropboxRestClient alloc] initWithRestClientProvider:clientProvider
                                                             pathProvider:pathProvider];
    PTNDropboxFakeDBRestClient *firstDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
    PTNDropboxFakeDBRestClient *secondDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];

    RACSignal *values = [restClient fetchThumbnail:kDropboxPath size:kSize];

    OCMExpect([clientProvider ptn_restClient]).andReturn(firstDBRestClient);
    LLSignalTestRecorder *firstRecorder = [values testRecorder];

    OCMExpect([clientProvider ptn_restClient]).andReturn(secondDBRestClient);
    LLSignalTestRecorder *secondRecorder = [values testRecorder];

    NSString *firstThumbnailPath =
        [pathProvider localPathForThumbnailInPath:kDropboxPath size:size];
    NSString *secondThumbnailPath =
        [pathProvider localPathForThumbnailInPath:kDropboxPath size:size];
    [firstDBRestClient deliverThumbnail:firstThumbnailPath];
    [secondDBRestClient deliverThumbnail:secondThumbnailPath];

    expect(firstRecorder).will.sendValues(@[firstThumbnailPath]);
    expect(secondRecorder).will.sendValues(@[secondThumbnailPath]);
  });

  it(@"should not fetch thumbnail of other requests", ^{
    NSString *otherPath = @"/bar/baz";
    NSString *otherLocalPath = [pathProvider localPathForThumbnailInPath:otherPath size:size];
    RACSignal *values = [restClient fetchThumbnail:kDropboxPath size:kSize];
    LLSignalTestRecorder *recorder = [values testRecorder];
    RACSignal *otherValues = [restClient fetchThumbnail:otherPath size:kSize];
    LLSignalTestRecorder *otherRecorder = [otherValues testRecorder];

    expect([dbRestClient didRequestThumbnailAtPath:kDropboxPath size:kSizeName])
        .to.equal(localPath);
    expect([dbRestClient didRequestThumbnailAtPath:otherPath size:kSizeName])
        .to.equal(otherLocalPath);

    [dbRestClient deliverThumbnail:otherLocalPath];
    expect(otherRecorder).will.sendValues(@[otherLocalPath]);
    expect(otherRecorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should err on thumbnail fetching failure", ^{
    RACSignal *values = [restClient fetchThumbnail:kDropboxPath size:kSize];
    LLSignalTestRecorder *recorder = [values testRecorder];
    expect([dbRestClient didRequestThumbnailAtPath:kDropboxPath size:kSizeName])
        .to.equal(localPath);

    [dbRestClient deliverThumbnailError:errorWithPath];
    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
    });
  });

  it(@"should not err on file thumbnail failure of other requests", ^{
    NSString *otherPath = @"/bar/baz";
    NSError *errorWithOtherPath = PTNDropboxErrorWithPathInfo(otherPath);
    NSString *otherLocalPath = [pathProvider localPathForThumbnailInPath:otherPath size:size];
    RACSignal *values = [restClient fetchThumbnail:kDropboxPath size:kSize];
    LLSignalTestRecorder *recorder = [values testRecorder];
    RACSignal *otherValues = [restClient fetchThumbnail:otherPath size:kSize];
    LLSignalTestRecorder *otherRecorder = [otherValues testRecorder];

    expect([dbRestClient didRequestThumbnailAtPath:kDropboxPath size:kSizeName]).to.equal(localPath);
    expect([dbRestClient didRequestThumbnailAtPath:otherPath size:kSizeName])
        .to.equal(otherLocalPath);

    [dbRestClient deliverThumbnailError:errorWithOtherPath];
    expect(otherRecorder).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
    });
    expect(recorder).toNot.matchError(^BOOL(NSError * __unused error) {
      return YES;
    });
  });

  it(@"should cancel request upon disposal", ^{
    RACSignal *values = [restClient fetchThumbnail:kDropboxPath size:kSize];
    RACDisposable *subscriber = [values subscribeNext:^(id __unused x) {}];
    expect([dbRestClient didRequestThumbnailAtPath:kDropboxPath size:kSizeName]).will.beTruthy();
    
    [subscriber dispose];
    expect([dbRestClient didCancelRequestForThumbnailAtPath:kDropboxPath size:kSizeName])
        .will.beTruthy();
  });

  context(@"thumbnail sizes", ^{
    NSDictionary *sizeValueToSizeName = @{
      @(PTNDropboxThumbnailSizeExtraSmall): @"xs",
      @(PTNDropboxThumbnailSizeSmall): @"s",
      @(PTNDropboxThumbnailSizeMedium): @"m",
      @(PTNDropboxThumbnailSizeLarge): @"l",
      @(PTNDropboxThumbnailSizeExtraLarge): @"xl",
    };

    [sizeValueToSizeName enumerateKeysAndObjectsUsingBlock:^(NSNumber *size, NSString *sizeName,
                                                             BOOL * __unused stop) {
      it(@"hould correctly request thumbnail size", ^{
        [[restClient fetchThumbnail:kDropboxPath size:size.unsignedIntegerValue]
         subscribeNext:^(id __unused x) {}];
        expect([dbRestClient didRequestThumbnailAtPath:kDropboxPath size:sizeName]).to.beTruthy();
      });
    }];
  });
});

SpecEnd
