// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxAtomicRestClient.h"

#import "NSError+Photons.h"
#import "PTNDropboxFakeDBRestClient.h"
#import "PTNDropboxFakeRestClientProvider.h"
#import "PTNDropboxPathProvider.h"
#import "PTNDropboxRestClientProvider.h"
#import "PTNDropboxTestUtils.h"
#import "PTNDropboxThumbnail.h"
#import "PTNProgress.h"

SpecBegin(PTNDropboxAtomicRestClient)

__block PTNDropboxAtomicRestClient *client;
__block PTNDropboxFakeRestClientProvider *restClientProvider;
__block id<PTNDropboxPathProvider> pathProvider;
__block id fileManager;
__block PTNDropboxFakeDBRestClient *dropboxRestClient;

static NSString * const kPath = @"foo";
static NSString * const kRevision = @"bar";

beforeEach(^{
  dropboxRestClient = [[PTNDropboxFakeDBRestClient alloc] init];
  restClientProvider = [[PTNDropboxFakeRestClientProvider alloc] initWithClient:dropboxRestClient];
  pathProvider = [[PTNDropboxPathProvider alloc] init];
  fileManager = OCMClassMock([NSFileManager class]);
  client = [[PTNDropboxAtomicRestClient alloc] initWithRestClientProvider:restClientProvider
                                                             pathProvider:pathProvider
                                                              fileManager:fileManager];
});

context(@"metadata", ^{
  it(@"should deliver metadata like regular rest client", ^{
    LLSignalTestRecorder *values = [[client fetchMetadata:kPath revision:kRevision] testRecorder];
    expect([dropboxRestClient didRequestMetadataAtPath:kPath revision:kRevision]).to.beTruthy();

    DBMetadata *metadata = PTNDropboxCreateMetadata(kPath, kRevision);
    [dropboxRestClient deliverMetadata:metadata];
    expect(values).to.sendValues(@[metadata]);
  });
  
  it(@"should err if not authorized", ^{
    restClientProvider.isLinked = NO;

    expect([[client fetchMetadata:kPath revision:kRevision] testRecorder])
        .will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeNotAuthorized;
    });
  });
});

context(@"files", ^{
  it(@"should request files in unique paths", ^{
    RACSignal *values = [client fetchFile:kPath revision:kRevision];
    [values subscribeNext:^(id __unused x) {}];
    NSString *firstPath = [dropboxRestClient didRequestFileAtPath:kPath revision:kRevision];
    [values subscribeNext:^(id __unused x) {}];
    NSString *secondPath = [dropboxRestClient didRequestFileAtPath:kPath revision:kRevision];
    expect(secondPath).willNot.equal(firstPath);
  });

  it(@"should request files with a different path but return original path", ^{
    LLSignalTestRecorder *values = [[client fetchFile:kPath revision:kRevision] testRecorder];
    NSString *originalPath = [pathProvider localPathForFileInPath:kPath revision:kRevision];
    NSString *requestPath = [dropboxRestClient didRequestFileAtPath:kPath revision:kRevision];

    expect(requestPath).notTo.equal(originalPath);

    OCMExpect([fileManager moveItemAtPath:requestPath toPath:originalPath
        error:[OCMArg setTo:nil]]).andReturn(YES);

    [dropboxRestClient deliverFile:requestPath];
    expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:originalPath]]);
    OCMVerifyAll(fileManager);
  });

  it(@"should return error if moving file fails", ^{
    LLSignalTestRecorder *values = [[client fetchFile:kPath revision:kRevision] testRecorder];
    NSString *originalPath = [pathProvider localPathForFileInPath:kPath revision:kRevision];
    NSString *requestPath = [dropboxRestClient didRequestFileAtPath:kPath revision:kRevision];

    OCMExpect([fileManager moveItemAtPath:requestPath toPath:originalPath
        error:[OCMArg setTo:[NSError lt_errorWithCode:1337]]]).andReturn(NO);

    [dropboxRestClient deliverFile:requestPath];
    expect(values).will.matchError(^BOOL(NSError *error){
      return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError.code == 1337;
    });
    OCMVerifyAll(fileManager);
  });

  it(@"should replace file if destenation file existis", ^{
    LLSignalTestRecorder *values = [[client fetchFile:kPath revision:kRevision] testRecorder];
    NSString *originalPath = [pathProvider localPathForFileInPath:kPath revision:kRevision];
    NSString *requestPath = [dropboxRestClient didRequestFileAtPath:kPath revision:kRevision];

    expect(requestPath).notTo.equal(originalPath);

    OCMStub([fileManager fileExistsAtPath:originalPath]).andReturn(YES);
    OCMExpect([fileManager replaceItemAtURL:[NSURL fileURLWithPath:originalPath]
                              withItemAtURL:[NSURL fileURLWithPath:requestPath]
                             backupItemName:OCMOCK_ANY
                                    options:NSFileManagerItemReplacementUsingNewMetadataOnly
                           resultingItemURL:[OCMArg anyObjectRef] error:[OCMArg setTo:nil]])
        .andReturn(YES);

    [dropboxRestClient deliverFile:requestPath];
    expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:originalPath]]);
    OCMVerifyAll(fileManager);
  });

  it(@"should err if not authorized", ^{
    restClientProvider.isLinked = NO;

    expect([client fetchFile:kPath revision:kRevision]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeNotAuthorized;
    });
  });
});

context(@"thumbnails", ^{
  __block PTNDropboxThumbnailType *thumbnailType;

  beforeEach(^{
    thumbnailType = [PTNDropboxThumbnailType enumWithValue:PTNDropboxThumbnailTypeMedium];
  });

  it(@"should request thumbnails in unique paths", ^{
    [[client fetchThumbnail:kPath type:thumbnailType] subscribeNext:^(id __unused x) {}];
    NSString *firstPath = [dropboxRestClient didRequestFileAtPath:kPath revision:kRevision];
    [[client fetchThumbnail:kPath type:thumbnailType] subscribeNext:^(id __unused x) {}];
    expect([dropboxRestClient didRequestThumbnailAtPath:kPath size:thumbnailType.sizeName])
        .notTo.equal(firstPath);
  });

  it(@"should request thumbnails with a different path but return original path", ^{
    LLSignalTestRecorder *values = [[client fetchThumbnail:kPath type:thumbnailType] testRecorder];
    NSString *requestPath = [dropboxRestClient didRequestThumbnailAtPath:kPath
                                                                    size:thumbnailType.sizeName];
    NSString *originalPath = [pathProvider localPathForThumbnailInPath:kPath
                                                                  size:thumbnailType.size];

    expect(requestPath).notTo.equal(originalPath);

    OCMExpect([fileManager moveItemAtPath:requestPath toPath:originalPath
              error:[OCMArg setTo:nil]]).andReturn(YES);

    [dropboxRestClient deliverThumbnail:requestPath];
    expect(values).will.sendValues(@[originalPath]);
    OCMVerifyAll(fileManager);
  });

  it(@"should return error if moving file fails", ^{
    LLSignalTestRecorder *values = [[client fetchThumbnail:kPath type:thumbnailType] testRecorder];
    NSString *requestPath = [dropboxRestClient didRequestThumbnailAtPath:kPath
                                                                    size:thumbnailType.sizeName];
    NSString *originalPath = [pathProvider localPathForThumbnailInPath:kPath
                                                                  size:thumbnailType.size];

    OCMExpect([fileManager moveItemAtPath:requestPath toPath:originalPath
        error:[OCMArg setTo:[NSError lt_errorWithCode:1337]]]).andReturn(NO);

    [dropboxRestClient deliverThumbnail:requestPath];
    expect(values).will.matchError(^BOOL(NSError *error){
      return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError.code == 1337;
    });
    OCMVerifyAll(fileManager);
  });

  it(@"should replace file if destenation file existis", ^{
    LLSignalTestRecorder *values = [[client fetchThumbnail:kPath type:thumbnailType] testRecorder];
    NSString *requestPath = [dropboxRestClient didRequestThumbnailAtPath:kPath
                                                                    size:thumbnailType.sizeName];
    NSString *originalPath = [pathProvider localPathForThumbnailInPath:kPath
                                                                  size:thumbnailType.size];

    expect(requestPath).notTo.equal(originalPath);

    OCMStub([fileManager fileExistsAtPath:originalPath]).andReturn(YES);
    OCMExpect([fileManager replaceItemAtURL:[NSURL fileURLWithPath:originalPath]
                              withItemAtURL:[NSURL fileURLWithPath:requestPath]
                             backupItemName:OCMOCK_ANY
                                    options:NSFileManagerItemReplacementUsingNewMetadataOnly
                           resultingItemURL:[OCMArg anyObjectRef] error:[OCMArg setTo:nil]])
        .andReturn(YES);

    [dropboxRestClient deliverThumbnail:requestPath];
    expect(values).will.sendValues(@[originalPath]);
    OCMVerifyAll(fileManager);
  });

  it(@"should err if not authorized", ^{
    restClientProvider.isLinked = NO;

    expect([client fetchThumbnail:kPath type:thumbnailType]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeNotAuthorized;
    });
  });
});

SpecEnd
