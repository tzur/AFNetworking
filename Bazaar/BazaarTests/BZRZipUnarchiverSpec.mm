// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRZipUnarchiver.h"

#import <ZipArchive/SSZipArchive.h>

#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

SpecBegin(BZRZipUnarchiver)

__block id underlyingArchive;

beforeEach(^{
  underlyingArchive = OCMClassMock([SSZipArchive class]);
});

context(@"unarchiving", ^{
  __block NSString *archivePath;
  __block NSString *targetPath;
  __block NSString *password;
  __block BZRZipUnarchiver *unarchiver;

  beforeEach(^{
    archivePath = @"/foo.zip";
    targetPath = @"/foo";
    password = @"foobar";
    unarchiver = [[BZRZipUnarchiver alloc] initWithPath:archivePath password:password
                                         archivingQueue:nil];
  });

  it(@"should raise exception if completion block is nil", ^{
    expect(^{
      LTSuccessOrErrorBlock completion;
      [unarchiver unarchiveFilesToPath:targetPath progress:nil completion:completion];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should invoke the unarchiving method of the underlying class with correct parameters", ^{
    OCMExpect([underlyingArchive unzipFileAtPath:archivePath toDestination:targetPath
                              preserveAttributes:YES overwrite:YES password:password
                                           error:[OCMArg anyObjectRef] delegate:OCMOCK_ANY]);
    [unarchiver unarchiveFilesToPath:targetPath progress:nil completion:^(BOOL, NSError *) {}];

    OCMVerifyAllWithDelay(underlyingArchive, 1);
  });

  it(@"should report completion when the underlying archive completes unarchiving", ^{
    OCMStub([underlyingArchive unzipFileAtPath:archivePath toDestination:targetPath
                            preserveAttributes:YES overwrite:YES password:password
                                         error:[OCMArg anyObjectRef] delegate:OCMOCK_ANY])
        .andReturn(YES);

    __block BOOL completed = NO;
    __block BOOL completionStatus;
    __block NSError *completionError;
    [unarchiver unarchiveFilesToPath:targetPath progress:nil
                          completion:^(BOOL success, NSError *error) {
                            completed = YES;
                            completionStatus = success;
                            completionError = error;
                          }];

    expect(completed).will.beTruthy();
    expect(completionStatus).will.beTruthy();
    expect(completionError).will.beNil();
  });

  it(@"should report error when the underlying archive reports error", ^{
    NSError *underlyingError = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingArchive unzipFileAtPath:archivePath toDestination:targetPath
                            preserveAttributes:YES overwrite:YES password:password
                                         error:[OCMArg setTo:underlyingError] delegate:OCMOCK_ANY])
        .andReturn(NO);

    __block BOOL completed = NO;
    __block BOOL completionStatus;
    __block NSError *completionError;
    [unarchiver unarchiveFilesToPath:targetPath progress:nil
                          completion:^(BOOL success, NSError *error) {
                            completed = YES;
                            completionStatus = success;
                            completionError = error;
                          }];

    expect(completed).will.beTruthy();
    expect(completionStatus).will.beFalsy();
    expect(completionError).willNot.beNil();
    expect(completionError.lt_isLTDomain).will.beTruthy();
    expect(completionError.code).will.equal(BZRErrorCodeUnarchivingFailed);
    expect(completionError.lt_underlyingError).will.equal(underlyingError);
  });

  it(@"should report progress as the unarchiving progress", ^{
    OCMStub([underlyingArchive unzipFileAtPath:archivePath toDestination:targetPath
                            preserveAttributes:YES overwrite:YES password:password
                                         error:[OCMArg anyObjectRef] delegate:[OCMArg isNotNil]])
        .andDo(^(NSInvocation *invocation) {
          id<SSZipArchiveDelegate> __unsafe_unretained delegate;
          [invocation getArgument:&delegate atIndex:8];
          [delegate zipArchiveProgressEvent:0 total:100];
          [delegate zipArchiveProgressEvent:50 total:100];
          [delegate zipArchiveProgressEvent:100 total:100];
        }).andReturn(YES);

    NSMutableArray<NSNumber *> *reportedTotalBytes = [NSMutableArray array];
    NSMutableArray<NSNumber *> *reportedProcessedBytes = [NSMutableArray array];
    [unarchiver unarchiveFilesToPath:targetPath
                            progress:^BOOL(NSNumber *totalBytes, NSNumber *processedBytes) {
                              [reportedTotalBytes addObject:totalBytes];
                              [reportedProcessedBytes addObject:processedBytes];
                              return YES;
                            } completion:^(BOOL, NSError *) {}];

    expect(reportedTotalBytes).will.equal(@[@100, @100, @100]);
    expect(reportedProcessedBytes).will.equal(@[@0, @50, @100]);
  });

  it(@"should cancel the unarchiving if the progress block returns NO and complete with error", ^{
    OCMStub([underlyingArchive unzipFileAtPath:archivePath toDestination:targetPath
                            preserveAttributes:YES overwrite:YES password:password
                                         error:[OCMArg anyObjectRef] delegate:[OCMArg isNotNil]])
        .andDo(^(NSInvocation *invocation) {
          id<SSZipArchiveDelegate> __unsafe_unretained delegate;
          [invocation getArgument:&delegate atIndex:8];
          [delegate zipArchiveProgressEvent:0 total:100];
          [delegate zipArchiveProgressEvent:50 total:100];
          [delegate zipArchiveProgressEvent:100 total:100];
        }).andReturn(NO);

    __block BOOL completed = NO;
    __block BOOL completionStatus;
    __block NSError *completionError;
    [unarchiver unarchiveFilesToPath:targetPath
                            progress:^BOOL(NSNumber *totalBytes, NSNumber *processedBytes) {
                              return
                                  [processedBytes longLongValue] < ([totalBytes longLongValue] / 2);
                            } completion:^(BOOL success, NSError *error) {
                              completed = YES;
                              completionStatus = success;
                              completionError = error;
                            }];
    
    expect(completed).will.beTruthy();
    expect(completionStatus).will.beFalsy();
    expect(completionError).willNot.beNil();
    expect(completionError.lt_isLTDomain).will.beTruthy();
    expect(completionError.code).will.equal(BZRErrorCodeArchivingCancelled);
  });
});

SpecEnd
