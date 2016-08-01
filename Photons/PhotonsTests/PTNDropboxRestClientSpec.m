// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxRestClient.h"

#import "NSError+Photons.h"
#import "PTNDropboxFakeDBRestClient.h"
#import "PTNDropboxFakeRestClientProvider.h"
#import "PTNDropboxPathProvider.h"
#import "PTNDropboxRestClientProvider.h"
#import "PTNDropboxTestUtils.h"
#import "PTNDropboxThumbnail.h"
#import "PTNProgress.h"

SpecBegin(PTNDropboxRestClient)

static NSString * const kDropboxPath = @"/foo/bar";
static NSString * const kRevision = @"baz";

__block PTNDropboxFakeDBRestClient *dbRestClient;
__block id<PTNDropboxPathProvider> pathProvider;
__block PTNDropboxRestClient *restClient;
__block PTNDropboxFakeRestClientProvider *clientProvider;
__block NSError *errorWithPath;
__block NSString *localPath;

beforeEach(^{
  dbRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
  pathProvider = [[PTNDropboxPathProvider alloc] init];
  clientProvider = [[PTNDropboxFakeRestClientProvider alloc] initWithClient:dbRestClient];
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
    PTNDropboxFakeDBRestClient *firstDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
    PTNDropboxFakeDBRestClient *secondDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];

    RACSignal *values = [restClient fetchMetadata:kDropboxPath revision:kRevision];

    clientProvider.restClient = firstDBRestClient;
    [values subscribeNext:^(id __unused x) { }];
    expect([firstDBRestClient didRequestMetadataAtPath:kDropboxPath revision:kRevision])
        .to.beTruthy();

    clientProvider.restClient = secondDBRestClient;
    [values subscribeNext:^(id __unused x) { }];
    expect([secondDBRestClient didRequestMetadataAtPath:kDropboxPath revision:kRevision])
        .to.beTruthy();
  });

  it(@"should not mix metadata requests with the equal parameters", ^{
    PTNDropboxFakeDBRestClient *firstDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
    PTNDropboxFakeDBRestClient *secondDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];

    RACSignal *values = [restClient fetchMetadata:kDropboxPath revision:kRevision];

    clientProvider.restClient = firstDBRestClient;
    LLSignalTestRecorder *firstRecorder = [values testRecorder];

    clientProvider.restClient = secondDBRestClient;
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

  it(@"should err when not authorized", ^{
    clientProvider.isLinked = NO;
    restClient = [[PTNDropboxRestClient alloc] initWithRestClientProvider:clientProvider
                                                             pathProvider:pathProvider];

    LLSignalTestRecorder *values =
        [[restClient fetchMetadata:kDropboxPath revision:kRevision] testRecorder];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeNotAuthorized;
    });
    expect([dbRestClient didRequestMetadataAtPath:kDropboxPath revision:kRevision]).to.beFalsy();
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
    PTNDropboxFakeDBRestClient *firstDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
    PTNDropboxFakeDBRestClient *secondDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];

    RACSignal *values = [restClient fetchFile:kDropboxPath revision:kRevision];

    clientProvider.restClient = firstDBRestClient;
    [values subscribeNext:^(id __unused x) { }];
    expect([firstDBRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).to.beTruthy();

    clientProvider.restClient = secondDBRestClient;
    [values subscribeNext:^(id __unused x) { }];
    expect([secondDBRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).to.beTruthy();
  });

  it(@"should not mix file requests with the equal parameters", ^{
    PTNDropboxFakeDBRestClient *firstDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
    PTNDropboxFakeDBRestClient *secondDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];

    RACSignal *values = [restClient fetchFile:kDropboxPath revision:kRevision];

    clientProvider.restClient = firstDBRestClient;
    LLSignalTestRecorder *firstRecorder = [values testRecorder];

    clientProvider.restClient = secondDBRestClient;
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

  it(@"should err when not authorized", ^{
    clientProvider.isLinked = NO;
    restClient = [[PTNDropboxRestClient alloc] initWithRestClientProvider:clientProvider
                                                             pathProvider:pathProvider];

    LLSignalTestRecorder *values =
        [[restClient fetchFile:kDropboxPath revision:kRevision] testRecorder];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeNotAuthorized;
    });
    expect([dbRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).to.beFalsy();
  });
});

context(@"thumbnail fetching", ^{
  __block PTNDropboxThumbnailType *thumbnailType;

  beforeEach(^{
    thumbnailType = [PTNDropboxThumbnailType enumWithValue:PTNDropboxThumbnailTypeExtraSmall];
    localPath = [pathProvider localPathForThumbnailInPath:kDropboxPath size:thumbnailType.size];
  });

  it(@"should fetch thumbnail", ^{
    RACSignal *values = [restClient fetchThumbnail:kDropboxPath type:thumbnailType];
    LLSignalTestRecorder *recorder = [values testRecorder];
    expect([dbRestClient didRequestThumbnailAtPath:kDropboxPath size:thumbnailType.sizeName])
        .to.equal(localPath);

    [dbRestClient deliverThumbnail:localPath];
    expect(recorder).will.sendValues(@[localPath]);
    expect(recorder).will.complete();
  });

  it(@"should fetch thumbnail again for every subscription", ^{
    PTNDropboxFakeDBRestClient *firstDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
    PTNDropboxFakeDBRestClient *secondDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];

    RACSignal *values = [restClient fetchThumbnail:kDropboxPath type:thumbnailType];

    clientProvider.restClient = firstDBRestClient;
    [values subscribeNext:^(id __unused x) { }];
    expect([firstDBRestClient didRequestThumbnailAtPath:kDropboxPath size:thumbnailType.sizeName])
        .to.beTruthy();

    clientProvider.restClient = secondDBRestClient;
    [values subscribeNext:^(id __unused x) { }];
    expect([secondDBRestClient didRequestThumbnailAtPath:kDropboxPath size:thumbnailType.sizeName])
        .to.beTruthy();
  });

  it(@"should not mix thumbnail requests with the equal parameters", ^{
    PTNDropboxFakeDBRestClient *firstDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
    PTNDropboxFakeDBRestClient *secondDBRestClient = [[PTNDropboxFakeDBRestClient alloc] init];

    RACSignal *values = [restClient fetchThumbnail:kDropboxPath type:thumbnailType];

    clientProvider.restClient = firstDBRestClient;
    LLSignalTestRecorder *firstRecorder = [values testRecorder];

    clientProvider.restClient = secondDBRestClient;
    LLSignalTestRecorder *secondRecorder = [values testRecorder];

    NSString *firstThumbnailPath =
        [pathProvider localPathForThumbnailInPath:kDropboxPath size:thumbnailType.size];
    NSString *secondThumbnailPath =
        [pathProvider localPathForThumbnailInPath:kDropboxPath size:thumbnailType.size];
    [firstDBRestClient deliverThumbnail:firstThumbnailPath];
    [secondDBRestClient deliverThumbnail:secondThumbnailPath];

    expect(firstRecorder).will.sendValues(@[firstThumbnailPath]);
    expect(secondRecorder).will.sendValues(@[secondThumbnailPath]);
  });

  it(@"should not fetch thumbnail of other requests", ^{
    NSString *otherPath = @"/bar/baz";
    NSString *otherLocalPath = [pathProvider localPathForThumbnailInPath:otherPath
                                                                    size:thumbnailType.size];
    RACSignal *values = [restClient fetchThumbnail:kDropboxPath type:thumbnailType];
    LLSignalTestRecorder *recorder = [values testRecorder];
    RACSignal *otherValues = [restClient fetchThumbnail:otherPath type:thumbnailType];
    LLSignalTestRecorder *otherRecorder = [otherValues testRecorder];

    expect([dbRestClient didRequestThumbnailAtPath:kDropboxPath size:thumbnailType.sizeName])
        .to.equal(localPath);
    expect([dbRestClient didRequestThumbnailAtPath:otherPath size:thumbnailType.sizeName])
        .to.equal(otherLocalPath);

    [dbRestClient deliverThumbnail:otherLocalPath];
    expect(otherRecorder).will.sendValues(@[otherLocalPath]);
    expect(otherRecorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should err on thumbnail fetching failure", ^{
    RACSignal *values = [restClient fetchThumbnail:kDropboxPath type:thumbnailType];
    LLSignalTestRecorder *recorder = [values testRecorder];
    expect([dbRestClient didRequestThumbnailAtPath:kDropboxPath size:thumbnailType.sizeName])
        .to.equal(localPath);

    [dbRestClient deliverThumbnailError:errorWithPath];
    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
    });
  });

  it(@"should not err on file thumbnail failure of other requests", ^{
    NSString *otherPath = @"/bar/baz";
    NSError *errorWithOtherPath = PTNDropboxErrorWithPathInfo(otherPath);
    NSString *otherLocalPath = [pathProvider localPathForThumbnailInPath:otherPath
                                                                    size:thumbnailType.size];
    RACSignal *values = [restClient fetchThumbnail:kDropboxPath type:thumbnailType];
    LLSignalTestRecorder *recorder = [values testRecorder];
    RACSignal *otherValues = [restClient fetchThumbnail:otherPath type:thumbnailType];
    LLSignalTestRecorder *otherRecorder = [otherValues testRecorder];

    expect([dbRestClient didRequestThumbnailAtPath:kDropboxPath size:thumbnailType.sizeName])
        .to.equal(localPath);
    expect([dbRestClient didRequestThumbnailAtPath:otherPath size:thumbnailType.sizeName])
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
    RACSignal *values = [restClient fetchThumbnail:kDropboxPath type:thumbnailType];
    RACDisposable *subscriber = [values subscribeNext:^(id __unused x) {}];
    expect([dbRestClient didRequestThumbnailAtPath:kDropboxPath size:thumbnailType.sizeName])
        .will.beTruthy();

    [subscriber dispose];
    expect([dbRestClient didCancelRequestForThumbnailAtPath:kDropboxPath
        size:thumbnailType.sizeName]).will.beTruthy();
  });

  it(@"should err when not authorized", ^{
    clientProvider.isLinked = NO;
    restClient = [[PTNDropboxRestClient alloc] initWithRestClientProvider:clientProvider
                                                             pathProvider:pathProvider];

    LLSignalTestRecorder *values =
        [[restClient fetchThumbnail:kDropboxPath type:thumbnailType] testRecorder];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeNotAuthorized;
    });
    expect([dbRestClient didRequestFileAtPath:kDropboxPath revision:kRevision]).to.beFalsy();
  });

  context(@"thumbnail sizes", ^{
    [PTNDropboxThumbnailType enumerateEnumUsingBlock:^(PTNDropboxThumbnailType * _Nonnull type) {
      it(@"should correctly request thumbnail size", ^{
        [[restClient fetchThumbnail:kDropboxPath type:type] subscribeNext:^(id __unused x) {}];
        expect([dbRestClient didRequestThumbnailAtPath:kDropboxPath
            size:type.sizeName]).to.beTruthy();
      });
    }];
  });
});

SpecEnd
