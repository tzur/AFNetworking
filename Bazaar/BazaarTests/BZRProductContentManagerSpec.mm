// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentManager.h"

#import "BZRFileArchiver.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

/// Category for testing, exposes the method that creates \c NSBundle.
@interface BZRProductContentManager (ForTesting)

/// Returns a new \c NSBundle with the given \c pathToContent.
- (NSBundle *)bundleWithPath:(LTPath *)pathToContent;

@end

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
  __block NSBundle *bundle;

  beforeEach(^{
    archivePath = [LTPath pathWithPath:@"bar"];
    bundle = OCMClassMock([NSBundle class]);
    manager = OCMPartialMock(manager);
  });

  it(@"should send error when previous content directory deletion failed", ^{
    NSError *error = OCMClassMock([NSError class]);
    RACSignal *errorSignal = [RACSignal error:error];
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn(errorSignal);
    OCMStub([fileManager bzr_createDirectoryAtPathIfNotExists:OCMOCK_ANY])
        .andReturn([RACSignal empty]);
    OCMStub([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:OCMOCK_ANY])
        .andReturn([RACSignal empty]);
    OCMStub([fileManager bzr_moveItemAtPath:OCMOCK_ANY toPath:OCMOCK_ANY])
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
    OCMStub([fileManager bzr_moveItemAtPath:OCMOCK_ANY toPath:OCMOCK_ANY])
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
    OCMStub([fileManager bzr_moveItemAtPath:OCMOCK_ANY toPath:OCMOCK_ANY])
        .andReturn([RACSignal empty]);

    RACSignal *signal = [manager extractContentOfProduct:productIdentifier fromArchive:archivePath];

    expect(signal).will.sendError(error);
  });

  it(@"should filter progress without result from archiver", ^{
    OCMStub([manager bundleWithPath:OCMOCK_ANY]).andReturn(bundle);
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([fileManager bzr_createDirectoryAtPathIfNotExists:OCMOCK_ANY])
        .andReturn([RACSignal empty]);
    BZRFileArchivingProgress *progress = [[LTProgress alloc] init];
    RACSignal *progressSignal = [RACSignal return:progress];
    OCMStub([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:OCMOCK_ANY])
        .andReturn(progressSignal);
    OCMStub([fileManager bzr_moveItemAtPath:OCMOCK_ANY toPath:OCMOCK_ANY])
        .andReturn([RACSignal empty]);

    LLSignalTestRecorder *recorder = [[manager extractContentOfProduct:productIdentifier
                                                           fromArchive:archivePath] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[bundle]);
  });

  it(@"should send bundle when content was extracted successfully", ^{
    OCMStub([manager bundleWithPath:OCMOCK_ANY]).andReturn(bundle);
    OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([fileManager bzr_createDirectoryAtPathIfNotExists:OCMOCK_ANY])
        .andReturn([RACSignal empty]);
    OCMStub([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:OCMOCK_ANY])
        .andReturn([RACSignal empty]);
    OCMStub([fileManager bzr_moveItemAtPath:OCMOCK_ANY toPath:OCMOCK_ANY])
        .andReturn([RACSignal empty]);

    LLSignalTestRecorder *recorder =
        [[manager extractContentOfProduct:productIdentifier fromArchive:archivePath] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[bundle]);
  });

  context(@"extracting product content to the correct path", ^{
    __block LTPath *bazaarContentPath;

    beforeEach(^{
      OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY]).andReturn([RACSignal empty]);
      OCMStub([fileManager bzr_createDirectoryAtPathIfNotExists:OCMOCK_ANY])
          .andReturn([RACSignal empty]);
      OCMStub([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:OCMOCK_ANY])
          .andReturn([RACSignal empty]);
      OCMStub([fileManager bzr_moveItemAtPath:OCMOCK_ANY toPath:OCMOCK_ANY])
          .andReturn([RACSignal empty]);
      bazaarContentPath = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryApplicationSupport
                                         andRelativePath:@"Bazaar/ProductsContent/"];
    });

    it(@"should extract to the product temporary directory path", ^{
      OCMStub([manager bundleWithPath:OCMOCK_ANY]).andReturn(bundle);
      [[manager extractContentOfProduct:productIdentifier fromArchive:archivePath] testRecorder];

      auto tempDirectoryName = [@"_" stringByAppendingString:productIdentifier];
      auto tempPath = [bazaarContentPath pathByAppendingPathComponent:tempDirectoryName].path;
      OCMVerify([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:tempPath]);
    });

    it(@"should extract to the product directory path concatenated with a temp directory", ^{
      OCMStub([manager bundleWithPath:OCMOCK_ANY]).andReturn(bundle);
      [[manager extractContentOfProduct:productIdentifier fromArchive:archivePath
                          intoDirectory:@"versionDirectory"] testRecorder];

      auto productContentPath = [bazaarContentPath pathByAppendingPathComponent:productIdentifier];
      auto tempPath = [productContentPath pathByAppendingPathComponent:@"_versionDirectory"];
      OCMVerify([fileArchiver unarchiveArchiveAtPath:OCMOCK_ANY toDirectory:tempPath.path]);
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
