// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentManager.h"

#import "BZRFileArchiver.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

SpecBegin(BZRProductContentManager)

__block NSString *productIdentifier;
__block NSFileManager *fileManager;
__block id<BZRFileArchiver> fileArchiver;
__block BZRProductContentManager *manager;

beforeEach(^{
  productIdentifier = @"foo";
  fileManager = OCMClassMock([NSFileManager class]);
  fileArchiver = OCMProtocolMock(@protocol(BZRFileArchiver));

  manager = [[BZRProductContentManager alloc] initWithFileManager:fileManager
                                                     fileArchiver:fileArchiver];
});

context(@"extracting content file", ^{
  __block LTPath *archivePath;

  beforeEach(^{
    archivePath = [LTPath pathWithPath:@"bar"];
  });

  it(@"should send error when previous content directory deletion failed", ^{
    NSError *error = OCMClassMock([NSError class]);
    RACSignal *errorSignal = [RACSignal error:error];
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn(errorSignal);
    OCMStub([fileManager bzr_createDirectoryAtPathIfNotExists:OCMOCK_ANY])
        .andReturn([RACSignal empty]);
    OCMStub([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:OCMOCK_ANY])
        .andReturn([RACSignal empty]);

    RACSignal *signal = [manager extractContentOfProduct:productIdentifier fromArchive:archivePath];

    expect(signal).will.sendError(error);
  });

  it(@"should send error when directory creation failed", ^{
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([fileManager bzr_createDirectoryAtPathIfNotExists:OCMOCK_ANY])
        .andReturn([RACSignal error:error]);
    OCMStub([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:OCMOCK_ANY])
        .andReturn([RACSignal empty]);

    RACSignal *signal = [manager extractContentOfProduct:productIdentifier fromArchive:archivePath];

    expect(signal).will.sendError(error);
  });

  it(@"should send error when unarchiving failed", ^{
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([fileManager bzr_createDirectoryAtPathIfNotExists:OCMOCK_ANY])
        .andReturn([RACSignal empty]);
    NSError *error = OCMClassMock([NSError class]);
    RACSignal *errorSignal = [RACSignal error:error];
    OCMStub([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:OCMOCK_ANY])
        .andReturn(errorSignal);

    RACSignal *signal = [manager extractContentOfProduct:productIdentifier fromArchive:archivePath];

    expect(signal).will.sendError(error);
  });

  it(@"should filter progress without result from archiver", ^{
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([fileManager bzr_createDirectoryAtPathIfNotExists:OCMOCK_ANY])
        .andReturn([RACSignal empty]);
    LTProgress<NSString *> *progress = [[LTProgress alloc] init];
    RACSignal *progressSignal = [RACSignal return:progress];
    OCMStub([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:OCMOCK_ANY])
        .andReturn(progressSignal);

    LLSignalTestRecorder *recorder = [[manager extractContentOfProduct:productIdentifier
                                                           fromArchive:archivePath] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValuesWithCount(0);
  });

  it(@"should send path when content was extract successfully", ^{
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([fileManager bzr_createDirectoryAtPathIfNotExists:OCMOCK_ANY])
        .andReturn([RACSignal empty]);
    NSString *expectedPath = @"/baz";
    LTProgress<NSString *> *progress = [[LTProgress alloc] initWithResult:expectedPath];
    RACSignal *progressSignal = [RACSignal return:progress];
    OCMStub([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:OCMOCK_ANY])
        .andReturn(progressSignal);

    LLSignalTestRecorder *recorder = [[manager extractContentOfProduct:productIdentifier
                                                           fromArchive:archivePath] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValuesWithCount(1);
    expect(recorder).will.matchValue(0, ^BOOL(LTPath *actualPath) {
      return [actualPath.path isEqualToString:expectedPath];
    });
  });

  context(@"extracting product content to the correct path", ^{
    __block LTPath *productContentPath;

    beforeEach(^{
      OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
      OCMStub([fileManager bzr_createDirectoryAtPathIfNotExists:OCMOCK_ANY])
          .andReturn([RACSignal empty]);
      OCMStub([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:OCMOCK_ANY])
          .andReturn([RACSignal empty]);
      auto bazaarContentPath = @"Bazaar/ProductsContent/";
      auto relativePath = [bazaarContentPath stringByAppendingPathComponent:productIdentifier];
      productContentPath = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryApplicationSupport
                                         andRelativePath:relativePath];
    });

    it(@"should extract to the product directory path", ^{
      [[manager extractContentOfProduct:productIdentifier fromArchive:archivePath] testRecorder];

      OCMVerify([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY
                                         toDirectory:productContentPath.path]);
    });

    it(@"should extract to the product directory path concatenated with a given directory name", ^{
      [[manager extractContentOfProduct:productIdentifier fromArchive:archivePath
                          intoDirectory:@"versionDirectory"] testRecorder];

      auto expectedPath = [productContentPath pathByAppendingPathComponent:@"versionDirectory"];
      OCMVerify([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:expectedPath.path]);
    });
  });
});

context(@"deleting content directory", ^{
  it(@"should send error when deletion has failed", ^{
    NSError *error = OCMClassMock([NSError class]);
    RACSignal *signal = [RACSignal error:error];
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn(signal);

    expect([manager deleteContentDirectoryOfProduct:productIdentifier]).will.sendError(error);
  });

  it(@"should complete when deletion has succeeded", ^{
    RACSignal *signal = [RACSignal empty];
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn(signal);

    expect([manager deleteContentDirectoryOfProduct:productIdentifier]).will.complete();
  });
});

context(@"getting path to content", ^{
  it(@"should send null when content directory doesn't exist", ^{
    OCMStub([fileManager fileExistsAtPath:OCMOCK_ANY]).andReturn(NO);

    LTPath *path = [manager pathToContentDirectoryOfProduct:productIdentifier];

    expect(path).to.beNil();
  });

  it(@"should send path when content directory exists", ^{
    OCMStub([fileManager fileExistsAtPath:OCMOCK_ANY]).andReturn(YES);

    LTPath *path = [manager pathToContentDirectoryOfProduct:productIdentifier];

    expect(path).toNot.beNil();
  });
});

SpecEnd
