// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRZipArchiver.h"

#import <ZipArchive/SSZipArchive.h>

#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

SpecBegin(BZRZipArchiver)

__block id underlyingArchive;

beforeEach(^{
  underlyingArchive = OCMClassMock([SSZipArchive class]);
});

context(@"initialization with underlying archive", ^{
  __block NSString *archivePath;
  __block NSString *password;
  __block BZRZipArchiver *archiver;

  beforeEach(^{
    archivePath = @"/foo.zip";
    password = @"foobar";
  });

  it(@"should initialize correctly", ^{
    archiver = [[BZRZipArchiver alloc] initWithArchive:underlyingArchive atPath:archivePath
                                             password:password archivingQueue:nil];
    expect(archiver).toNot.beNil();
    expect(archiver.path).to.equal(archivePath);
    expect(archiver.password).to.equal(password);
    expect(archiver.archivingQueue).toNot.beNil();
  });

  it(@"should close the archive upon destruction", ^{
    BZRZipArchiver __weak *weakArchiver;
    @autoreleasepool {
      BZRZipArchiver *archiver = [[BZRZipArchiver alloc] initWithArchive:underlyingArchive
                                                                  atPath:archivePath
                                                                password:password
                                                          archivingQueue:nil];
      weakArchiver = archiver;
    }

    expect(weakArchiver).to.beNil();
    OCMVerify([(SSZipArchive *)underlyingArchive close]);
  });
});

context(@"archiving", ^{
  __block NSString *archivePath;
  __block NSString *password;
  __block BZRZipArchiver *archiver;
  __block NSArray<NSString *> *filesToArchive;
  __block NSFileManager *fileManager;
  __block long long totalSizeOfFilesToArchive;

  beforeEach(^{
    archivePath = @"/foo.zip";
    password = @"foobar";
    archiver = [[BZRZipArchiver alloc] initWithArchive:underlyingArchive atPath:archivePath
                                              password:password archivingQueue:nil];

    filesToArchive = @[
      @"/foo/bar",
      @"/foo/baz"
    ];
    totalSizeOfFilesToArchive = filesToArchive.count * 1337;
    fileManager = OCMClassMock([NSFileManager class]);
    RACSignal *fileSizesSignal =
        [[[filesToArchive rac_sequence] signal] map:^RACTuple *(NSString *filePath) {
          return [RACTuple tupleWithObjects:filePath, @((long long)1337), nil];
        }];
    OCMStub([fileManager bzr_retrieveFilesSizes:filesToArchive]).andReturn(fileSizesSignal);
  });

  it(@"should raise exception if count of files to archive and archived names does not match", ^{
    NSArray<NSString *> *archivedNames = [filesToArchive arrayByAddingObject:@"foobar"];
    expect(^{
      [archiver archiveFilesAtPaths:filesToArchive withArchivedNames:archivedNames
                        fileManager:fileManager progress:nil completion:^(BOOL, NSError *) {}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should write the specified files to the underlying archive", ^{
    for (NSString *file in filesToArchive) {
      OCMExpect([underlyingArchive writeFileAtPath:file withFileName:file withPassword:password])
          .andReturn(YES);
    }
    [archiver archiveFilesAtPaths:filesToArchive withArchivedNames:filesToArchive
                      fileManager:fileManager progress:nil completion:^(BOOL, NSError *) {}];

    OCMVerifyAllWithDelay(underlyingArchive, 1);
  });

  it(@"should report completion when completed writing all files", ^{
    for (NSString *file in filesToArchive) {
      OCMStub([underlyingArchive writeFileAtPath:file withFileName:file withPassword:password])
          .andReturn(YES);
    }

    __block BOOL completionStatus = NO;
    __block NSError *completionError = nil;

    waitUntil(^(DoneCallback done) {
      [archiver archiveFilesAtPaths:filesToArchive withArchivedNames:filesToArchive
                        fileManager:fileManager progress:nil
                         completion:^(BOOL success, NSError *error) {
                           completionStatus = success;
                           completionError = error;
                           done();
                         }];
    });

    expect(completionStatus).to.beTruthy();
    expect(completionError).to.beNil();
  });

  it(@"should report error if failed to archive any of the files", ^{
    OCMStub([underlyingArchive writeFileAtPath:filesToArchive[0] withFileName:filesToArchive[0]
                                  withPassword:password]).andReturn(NO);
    OCMReject([underlyingArchive writeFileAtPath:filesToArchive[1] withFileName:filesToArchive[1]
                                  withPassword:password]);

    __block BOOL completionStatus = NO;
    __block NSError *completionError = nil;
    waitUntil(^(DoneCallback done) {
      [archiver archiveFilesAtPaths:filesToArchive withArchivedNames:filesToArchive
                        fileManager:fileManager progress:nil
                         completion:^(BOOL success, NSError *error) {
                           completionStatus = success;
                           completionError = error;
                           done();
                         }];
    });

    expect(completionStatus).to.beFalsy();
    expect(completionError).toNot.beNil();
  });

  it(@"should report progress as archiving progress", ^{
    for (NSString *file in filesToArchive) {
      OCMStub([underlyingArchive writeFileAtPath:file withFileName:file withPassword:password])
          .andReturn(YES);
    }

    NSMutableArray<NSNumber *> *reportedTotalBytes = [NSMutableArray array];
    NSMutableArray<NSNumber *> *reportedProcessedBytes = [NSMutableArray array];
    waitUntil(^(DoneCallback done) {
      [archiver archiveFilesAtPaths:filesToArchive withArchivedNames:filesToArchive
                        fileManager:fileManager
                           progress:^BOOL(NSNumber *totalBytes, NSNumber *bytesProcessed) {
                             [reportedTotalBytes addObject:totalBytes];
                             [reportedProcessedBytes addObject:bytesProcessed];
                             return YES;
                           } completion:^(BOOL, NSError *) {
                             done();
                           }];
    });

    expect(reportedTotalBytes).to.equal(@[
      @(totalSizeOfFilesToArchive),
      @(totalSizeOfFilesToArchive),
      @(totalSizeOfFilesToArchive)
    ]);
    expect(reportedProcessedBytes).to.equal(@[
      @0,
      @(totalSizeOfFilesToArchive / 2),
      @(totalSizeOfFilesToArchive)
    ]);
  });

  context(@"cancellation", ^{
    beforeEach(^{
      OCMStub([underlyingArchive writeFileAtPath:filesToArchive[0] withFileName:filesToArchive[0]
                                    withPassword:password]).andReturn(YES);
      OCMReject([underlyingArchive writeFileAtPath:filesToArchive[1] withFileName:filesToArchive[1]
                                      withPassword:password]);
    });

    it(@"should not start archiving if progress block return NO on first invocation", ^{
      NSMutableArray<NSNumber *> *reportedTotalBytes = [NSMutableArray array];
      NSMutableArray<NSNumber *> *reportedProcessedBytes = [NSMutableArray array];
      waitUntil(^(DoneCallback done) {
        [archiver archiveFilesAtPaths:filesToArchive withArchivedNames:filesToArchive
                          fileManager:fileManager
                             progress:^BOOL(NSNumber *totalBytes, NSNumber *bytesProcessed) {
                               [reportedTotalBytes addObject:totalBytes];
                               [reportedProcessedBytes addObject:bytesProcessed];
                               return NO;
                             } completion:^(BOOL, NSError *) {
                               done();
                             }];
      });

      expect(reportedTotalBytes).to.equal(@[@(totalSizeOfFilesToArchive)]);
      expect(reportedProcessedBytes).to.equal(@[@0]);
    });

    it(@"should stop archiving if progress block returns NO", ^{
      NSMutableArray<NSNumber *> *reportedTotalBytes = [NSMutableArray array];
      NSMutableArray<NSNumber *> *reportedProcessedBytes = [NSMutableArray array];
      waitUntil(^(DoneCallback done) {
        [archiver archiveFilesAtPaths:filesToArchive withArchivedNames:filesToArchive
                          fileManager:fileManager
                             progress:^BOOL(NSNumber *totalBytes, NSNumber *bytesProcessed) {
                               [reportedTotalBytes addObject:totalBytes];
                               [reportedProcessedBytes addObject:bytesProcessed];
                               return [bytesProcessed longLongValue] <
                                   (totalSizeOfFilesToArchive / 2);
                             } completion:^(BOOL, NSError *) {
                               done();
                             }];
      });

      expect(reportedTotalBytes).to.equal(@[
        @(totalSizeOfFilesToArchive),
        @(totalSizeOfFilesToArchive)
      ]);
      expect(reportedProcessedBytes).to.equal(@[
        @0,
        @(totalSizeOfFilesToArchive / 2)
      ]);
    });

    it(@"should report cancellation error if progress block returns NO", ^{
      __block BOOL completionStatus = NO;
      __block NSError *completionError = nil;

      waitUntil(^(DoneCallback done) {
        [archiver archiveFilesAtPaths:filesToArchive withArchivedNames:filesToArchive
                          fileManager:fileManager
                             progress:^BOOL(NSNumber *, NSNumber *bytesProcessed) {
                               return [bytesProcessed longLongValue] <
                                   (totalSizeOfFilesToArchive / 2);
                             } completion:^(BOOL success, NSError *error) {
                               completionStatus = success;
                               completionError = error;
                               done();
                             }];
      });

      expect(completionStatus).to.beFalsy();
      expect(completionError.lt_isLTDomain).to.beTruthy();
      expect(completionError.code).to.equal(BZRErrorCodeArchivingCancelled);
    });
  });
});

SpecEnd
