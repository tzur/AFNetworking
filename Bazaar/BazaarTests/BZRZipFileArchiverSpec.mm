// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRZipFileArchiver.h"

#import "BZRZipArchiveFactory.h"
#import "BZRZipArchiver.h"
#import "BZRZipUnarchiver.h"
#import "NSFileManager+Bazaar.h"

typedef RACSignal *(^BZRZipArchivingBlock)(BZRZipFileArchiver *archiver);

static NSString * const kBZRZipArchivingExamples = @"BZRZipArchivingExamples";
static NSString * const kBZRZipArchivingArchiverBlockKey = @"BZRZipArchivingArchiverBlock";
static NSString * const kBZRZipArchivingExpectedArchiveFileKey =
    @"BZRZipFileArchivingExpectedArchiveFile";
static NSString * const kBZRZipArchivingExpectedFilesToArchiveKey =
    @"BZRZipFileArchivingFilesToArchive";
static NSString * const kBZRZipArchivingExpectedArchivedNamesKey =
    @"BZRZipFileArchivingArchivedNames";

SpecBegin(BZRZipFileArchiver)

__block id zipArchiver;
__block id archiveFactory;
__block id fileManager;

beforeEach(^{
  zipArchiver = OCMProtocolMock(@protocol(BZRZipArchiver));
  archiveFactory = OCMClassMock([BZRZipArchiveFactory class]);
  fileManager = OCMClassMock([NSFileManager class]);
});

context(@"initialization", ^{
  it(@"should initialize with the default initializer", ^{
    BZRZipFileArchiver *archiver = [[BZRZipFileArchiver alloc] init];
    expect(archiver).toNot.beNil();
  });

  it(@"should initialize with the given arguments", ^{
    BZRZipFileArchiver *archiver = [[BZRZipFileArchiver alloc] initWithFileManager:fileManager
                                                                    archiveFactory:archiveFactory];
    expect(archiver).toNot.beNil();
  });
});

sharedExamplesFor(kBZRZipArchivingExamples, ^(NSDictionary *data) {
  __block NSString *archiveFile;
  __block NSArray<NSString *> *filesToArchive;
  __block NSArray<NSString *> *archivedNames;
  __block BZRZipArchivingBlock archivingBlock;

  __block BZRZipFileArchiver *archiver;

  beforeEach(^{
    archiveFile = data[kBZRZipArchivingExpectedArchiveFileKey];
    filesToArchive = data[kBZRZipArchivingExpectedFilesToArchiveKey];
    archivedNames = data[kBZRZipArchivingExpectedArchivedNamesKey];
    archivingBlock = data[kBZRZipArchivingArchiverBlockKey];

    archiver = [[BZRZipFileArchiver alloc] initWithFileManager:fileManager
                                                archiveFactory:archiveFactory];
  });

  context(@"overwriting existing archive", ^{
    it(@"should delete the archive file if it already exists", ^{
      OCMExpect([fileManager bzr_deleteItemAtPathIfExists:archiveFile])
          .andReturn([RACSignal empty]);
      LLSignalTestRecorder __unused *recorder = [archivingBlock(archiver) testRecorder];

      OCMVerifyAllWithDelay(fileManager, 1);
    });

    it(@"should err if failed to delete existing archive", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([fileManager bzr_deleteItemAtPathIfExists:OCMOCK_ANY])
          .andReturn([RACSignal error:error]);
      LLSignalTestRecorder *recorder = [archivingBlock(archiver) testRecorder];

      expect(recorder).will.matchError(^BOOL(NSError *signalError) {
        return [signalError isEqual:error];
      });
    });
  });

  context(@"creating archive", ^{
    beforeEach(^{
      OCMStub([fileManager bzr_deleteItemAtPathIfExists:archiveFile])
          .andReturn([RACSignal empty]);
    });

    it(@"should use the factory to create an archive object for archiving", ^{
      LLSignalTestRecorder *recorder = [archivingBlock(archiver) testRecorder];

      expect(recorder).will.finish();
      OCMVerify([archiveFactory zipArchiverAtPath:archiveFile withPassword:nil
                                            error:[OCMArg anyObjectRef]]);
    });

    it(@"should err if failed to create an archive object", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([archiveFactory zipArchiverAtPath:OCMOCK_ANY withPassword:OCMOCK_ANY
                                          error:[OCMArg setTo:error]]);
      LLSignalTestRecorder *recorder = [archivingBlock(archiver) testRecorder];

      expect(recorder).will.sendError(error);
    });
  });

  context(@"archiving", ^{
    beforeEach(^{
      OCMStub([fileManager bzr_deleteItemAtPathIfExists:archiveFile])
          .andReturn([RACSignal empty]);
      OCMStub([archiveFactory zipArchiverAtPath:archiveFile withPassword:nil
                                          error:[OCMArg anyObjectRef]]).andReturn(zipArchiver);
    });

    it(@"should send all the files for archiving", ^{
      OCMExpect([zipArchiver archiveFilesAtPaths:filesToArchive withArchivedNames:archivedNames
                                     fileManager:fileManager progress:OCMOCK_ANY
                                      completion:OCMOCK_ANY]);
      LLSignalTestRecorder __unused *recorder = [archivingBlock(archiver) testRecorder];

      OCMVerifyAllWithDelay(zipArchiver, 1);
    });

    it(@"should err if the archiver object completes with error", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([zipArchiver archiveFilesAtPaths:filesToArchive withArchivedNames:archivedNames
                                   fileManager:fileManager progress:OCMOCK_ANY
                                    completion:([OCMArg invokeBlockWithArgs:@NO, error, nil])]);
      LLSignalTestRecorder *recorder = [archivingBlock(archiver) testRecorder];

      expect(recorder).will.sendError(error);
    });

    it(@"should complete if archiving completes successfully", ^{
      NSNull *null = [NSNull null];
      OCMStub([zipArchiver archiveFilesAtPaths:filesToArchive withArchivedNames:archivedNames
                                   fileManager:fileManager progress:OCMOCK_ANY
                                    completion:([OCMArg invokeBlockWithArgs:@YES, null, nil])]);
      LLSignalTestRecorder *recorder = [archivingBlock(archiver) testRecorder];

      expect(recorder).will.complete();
      expect([recorder.values lastObject]).to
          .equal([[LTProgress alloc] initWithResult:archiveFile]);
    });

    it(@"should report progress as archiving progress", ^{
      OCMStub([zipArchiver archiveFilesAtPaths:filesToArchive withArchivedNames:archivedNames
                                   fileManager:fileManager progress:[OCMArg isNotNil]
                                    completion:[OCMArg isNotNil]])
          .andDo(^(NSInvocation *invocation) {
            BZRZipArchiveProgressBlock __unsafe_unretained progressBlock;
            [invocation getArgument:&progressBlock atIndex:5];
            progressBlock(@100, @0);
            progressBlock(@100, @50);
            progressBlock(@100, @100);
          });
      LLSignalTestRecorder *recorder = [archivingBlock(archiver) testRecorder];

      expect(recorder).will.sendValues(@[
        [[LTProgress alloc] initWithProgress:0],
        [[LTProgress alloc] initWithProgress:0.5],
        [[LTProgress alloc] initWithProgress:1]
      ]);
    });

    it(@"should indicate cancellation via progress block when subscription is disposed", ^{
      __block BZRZipArchiveProgressBlock progressBlock;
      __block RACDisposable *disposable;

      waitUntil(^(DoneCallback done) {
        OCMStub([zipArchiver archiveFilesAtPaths:filesToArchive withArchivedNames:archivedNames
                                     fileManager:fileManager progress:[OCMArg isNotNil]
                                      completion:[OCMArg isNotNil]])
            .andDo(^(NSInvocation *invocation) {
              BZRZipArchiveProgressBlock __unsafe_unretained _progressBlock;
              [invocation getArgument:&_progressBlock atIndex:5];
              progressBlock = [_progressBlock copy];
              done();
            });

        RACSignal *signal = archivingBlock(archiver);
        RACSubject *subject = [RACSubject subject];
        disposable = [signal subscribe:subject];
      });

      expect(progressBlock).toNot.beNil();

      BOOL shouldContinueArchving = progressBlock(@100, @50);
      expect(shouldContinueArchving).to.beTruthy();

      [disposable dispose];
      shouldContinueArchving = progressBlock(@100, @50);
      expect(shouldContinueArchving).to.beFalsy();
    });
  });
});

context(@"archiving files", ^{
  static NSString * const kArchiveFile = @"/foo.zip";
  static NSArray<NSString *> * const kFilesToArchive = @[
    @"/foo/bar",
    @"/foo/baz"
  ];

  itShouldBehaveLike(kBZRZipArchivingExamples, @{
    kBZRZipArchivingExpectedArchiveFileKey: kArchiveFile,
    kBZRZipArchivingExpectedFilesToArchiveKey: kFilesToArchive,
    kBZRZipArchivingArchiverBlockKey: ^RACSignal *(BZRZipFileArchiver *archiver) {
      return [archiver archiveFiles:kFilesToArchive toArchiveAtPath:kArchiveFile];
    }
  });
});

context(@"archiving directory", ^{
  static NSString * const kArchiveFile = @"/foo.zip";
  static NSString * const kDirectoryPath = @"/foo";
  static NSArray<NSString *> * const kFilesToArchive = @[
    @"/foo/bar",
    @"/foo/baz",
    @"/foo/foo/bar"
  ];
  static NSArray<NSString *> * const kArchivedNames = @[
    @"bar",
    @"baz",
    @"foo/bar"
  ];

  beforeEach(^{
    RACSignal *enumerationSignal = [[[kArchivedNames rac_sequence] signal]
        map:^RACTuple *(NSString *fileName) {
          return RACTuplePack(kDirectoryPath, fileName);
        }];

    OCMStub([fileManager bzr_enumerateDirectoryAtPath:kDirectoryPath]).andReturn(enumerationSignal);
  });

  itShouldBehaveLike(kBZRZipArchivingExamples, @{
    kBZRZipArchivingExpectedArchiveFileKey: kArchiveFile,
    kBZRZipArchivingExpectedFilesToArchiveKey: kFilesToArchive,
    kBZRZipArchivingExpectedArchivedNamesKey: kArchivedNames,
    kBZRZipArchivingArchiverBlockKey: ^RACSignal *(BZRZipFileArchiver *archiver) {
      return [archiver archiveContentsOfDirectory:kDirectoryPath toArchiveAtPath:kArchiveFile];
    }
  });
});

context(@"unarchiving", ^{
  static NSString * const kArchiveFile = @"/foo.zip";
  static NSString * const kTargetDirectory = @"/foo";

  __block id zipUnarchiver;
  __block BZRZipFileArchiver *archiver;

  beforeEach(^{
    zipUnarchiver = OCMProtocolMock(@protocol(BZRZipUnarchiver));
    archiver = [[BZRZipFileArchiver alloc] initWithFileManager:fileManager
                                                archiveFactory:archiveFactory];
  });

  context(@"creating archive", ^{
    it(@"should use the factory to create an archive object for unarchiving", ^{
      OCMExpect([archiveFactory zipUnarchiverAtPath:kArchiveFile withPassword:nil
                                              error:[OCMArg anyObjectRef]])
          .andReturn(zipUnarchiver);
      LLSignalTestRecorder __unused *recorder =
          [[archiver unarchiveArchiveAtPath:kArchiveFile toDirectory:kTargetDirectory]
           testRecorder];

      OCMVerifyAllWithDelay(archiveFactory, 1);
    });

    it(@"should err if failed to create an archive object", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([archiveFactory zipUnarchiverAtPath:OCMOCK_ANY withPassword:OCMOCK_ANY
                                            error:[OCMArg setTo:error]]);
      LLSignalTestRecorder *recorder =
          [[archiver unarchiveArchiveAtPath:kArchiveFile toDirectory:kTargetDirectory]
           testRecorder];

      expect(recorder).will.sendError(error);
    });
  });

  context(@"unarchiving", ^{
    beforeEach(^{
      OCMStub([archiveFactory zipUnarchiverAtPath:kArchiveFile withPassword:nil
                                            error:[OCMArg anyObjectRef]]).andReturn(zipUnarchiver);
    });

    it(@"should unarchive the archive file to the specified path", ^{
      OCMExpect([zipUnarchiver unarchiveFilesToPath:kTargetDirectory progress:[OCMArg isNotNil]
                                         completion:[OCMArg isNotNil]]);
      LLSignalTestRecorder __unused *recorder =
          [[archiver unarchiveArchiveAtPath:kArchiveFile toDirectory:kTargetDirectory]
           testRecorder];

      OCMVerifyAllWithDelay(zipUnarchiver, 1);
    });

    it(@"should complete when archive reports completion", ^{
      NSNull *null = [NSNull null];
      OCMStub([zipUnarchiver unarchiveFilesToPath:kTargetDirectory progress:[OCMArg isNotNil]
                                       completion:([OCMArg invokeBlockWithArgs:@YES, null, nil])]);
      LLSignalTestRecorder *recorder =
          [[archiver unarchiveArchiveAtPath:kArchiveFile toDirectory:kTargetDirectory]
           testRecorder];

      expect(recorder).will.complete();
      expect([recorder.values lastObject]).to
          .equal([[LTProgress alloc] initWithResult:kTargetDirectory]);
    });

    it(@"should err if archive reports error", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([zipUnarchiver unarchiveFilesToPath:kTargetDirectory progress:[OCMArg isNotNil]
                                       completion:([OCMArg invokeBlockWithArgs:@NO, error, nil])]);
      LLSignalTestRecorder *recorder =
          [[archiver unarchiveArchiveAtPath:kArchiveFile toDirectory:kTargetDirectory]
           testRecorder];

      expect(recorder).will.sendError(error);
    });

    it(@"should report progress as archiving progress", ^{
      OCMStub([zipUnarchiver unarchiveFilesToPath:kTargetDirectory progress:[OCMArg isNotNil]
                                       completion:[OCMArg isNotNil]])
          .andDo(^(NSInvocation *invocation) {
            BZRZipArchiveProgressBlock __unsafe_unretained progressBlock;
            [invocation getArgument:&progressBlock atIndex:3];
            progressBlock(@100, @0);
            progressBlock(@100, @50);
            progressBlock(@100, @100);
          });
      LLSignalTestRecorder *recorder =
          [[archiver unarchiveArchiveAtPath:kArchiveFile toDirectory:kTargetDirectory]
           testRecorder];

      expect(recorder).will.sendValues(@[
        [[LTProgress alloc] initWithProgress:0],
        [[LTProgress alloc] initWithProgress:0.5],
        [[LTProgress alloc] initWithProgress:1]
      ]);
    });

    it(@"should indicate cancellation via progress block when subscription is disposed", ^{
      __block BZRZipArchiveProgressBlock progressBlock;
      __block RACDisposable *disposable;

      waitUntil(^(DoneCallback done) {
        OCMStub([zipUnarchiver unarchiveFilesToPath:kTargetDirectory progress:[OCMArg isNotNil]
                                         completion:[OCMArg isNotNil]])
            .andDo(^(NSInvocation *invocation) {
              BZRZipArchiveProgressBlock __unsafe_unretained _progressBlock;
              [invocation getArgument:&_progressBlock atIndex:3];
              progressBlock = [_progressBlock copy];
              done();
            });

        RACSignal *signal =
            [archiver unarchiveArchiveAtPath:kArchiveFile toDirectory:kTargetDirectory];
        RACSubject *subject = [RACSubject subject];
        disposable = [signal subscribe:subject];
      });

      expect(progressBlock).toNot.beNil();

      BOOL shouldContinueArchving = progressBlock(@100, @50);
      expect(shouldContinueArchving).to.beTruthy();

      [disposable dispose];
      shouldContinueArchving = progressBlock(@100, @50);
      expect(shouldContinueArchving).to.beFalsy();
    });
  });
});
SpecEnd
