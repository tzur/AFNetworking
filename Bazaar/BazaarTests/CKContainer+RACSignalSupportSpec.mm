// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "CKContainer+RACSignalSupport.h"

#import "BZRCloudKitAccountStatus.h"

// Setup \c accountStatusWithCompletionHandler: expectations on the given mock \c CKContainer
// object. The container's \c accountStatusWithCompletionHandler: is expected to be invoked with
// some completion block. When such invocation occurs the completion block is invoked with the given
// \c accountStatus and \c error parameters. The expectation is setup \c expectationCount times.
static void BZRExpectAccountStatusRetrievalAndComplete(CKContainer *container,
    CKAccountStatus accountStatus, NSError * _Nullable error, NSUInteger expectationCount = 1) {
  LTParameterAssert(expectationCount > 0, @"Expectation count must be at least 1");

  for (NSUInteger i = 0; i < expectationCount; ++i) {
    OCMExpect([container accountStatusWithCompletionHandler:
               ([OCMArg invokeBlockWithArgs:@(accountStatus), error ?: [NSNull null], nil])]);
  }
}

// Setup \c addOperation: expectations on the given mock \c CKDatabase object. The database
// \c addOperation: is expected to be invoked with some \c CKFetchRecordsOperation. When such
// invocation occurs the operation's \c fetchRecordsCompletionBlock is invoked with the given
// \c recordsByRecordID and \c operationError. The expectation is setup \c expectationCount times.
static void BZRExpectFetchRecordsOperationAndComplete(CKDatabase *database,
    NSDictionary<CKRecordID *, CKRecord *> * _Nullable recordsByRecordID,
    NSError * _Nullable operationError, NSUInteger expectationCount = 1) {
  LTParameterAssert(expectationCount > 0, @"Expectation count must be at least 1");

  for (NSUInteger i = 0; i < expectationCount; ++i) {
    OCMExpect([database addOperation:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
      CKFetchRecordsOperation * __unsafe_unretained operation;
      [invocation getArgument:&operation atIndex:2];
      if (operation.fetchRecordsCompletionBlock) {
        operation.fetchRecordsCompletionBlock(recordsByRecordID, operationError);
      }
    });
  }
}

SpecBegin(CKContainer_RACSignalSupport)

__block CKContainer *container;
__block NSError *retryableError;
__block NSError *nonRetryableError;

beforeEach(^{
  container = OCMPartialMock([CKContainer defaultContainer]);
  retryableError = [NSError errorWithDomain:CKErrorDomain code:CKErrorZoneBusy
                                   userInfo:@{CKErrorRetryAfterKey: @0}];
  nonRetryableError = [NSError lt_errorWithCode:1337];
});

afterEach(^{
  [(id)container stopMocking];
});

context(@"account status signal", ^{
  it(@"should err if the fetching account status completed with non-retryable error", ^{
    BZRExpectAccountStatusRetrievalAndComplete(container, CKAccountStatusCouldNotDetermine,
        nonRetryableError);

    auto recorder = [container.bzr_accountStatus testRecorder];

    expect(recorder).to.sendError(nonRetryableError);
    OCMVerifyAll(container);
  });

  it(@"should deliver the correct account status as provided to the completion block", ^{
    BZRExpectAccountStatusRetrievalAndComplete(container, CKAccountStatusRestricted, nil);

    auto recorder = [container.bzr_accountStatus testRecorder];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[$(BZRCloudKitAccountStatusRestricted)]);
    OCMVerifyAll(container);
  });

  it(@"should retry the operation 3 times if failed with a retryable error", ^{
    BZRExpectAccountStatusRetrievalAndComplete(container, CKAccountStatusCouldNotDetermine,
        retryableError, 3);
    BZRExpectAccountStatusRetrievalAndComplete(container, CKAccountStatusAvailable, nil);

    auto recorder = [container.bzr_accountStatus testRecorder];

    expect(recorder).will.complete();
    expect(recorder).to.sendValues(@[$(BZRCloudKitAccountStatusAvailable)]);
    OCMVerifyAll(container);
  });

  it(@"should err if operation failed after 3 retry attempts", ^{
    BZRExpectAccountStatusRetrievalAndComplete(container, CKAccountStatusCouldNotDetermine,
        retryableError, 4);

    auto recorder = [container.bzr_accountStatus testRecorder];

    expect(recorder).will.sendError(retryableError);
    OCMVerifyAll(container);
  });
});

context(@"user record identifier signal", ^{
  __block CKDatabase *privateDatabase;
  __block CKRecordID *recordID;
  __block CKRecord *record;

  beforeEach(^{
    privateDatabase = OCMClassMock([CKDatabase class]);
    OCMStub([container privateCloudDatabase]).andReturn(privateDatabase);

    recordID = [[CKRecordID alloc] initWithRecordName:@"foo-bar"];
    record = OCMClassMock([CKRecord class]);
  });

  it(@"should err if fetching the user record identifier completed with non-retryable error", ^{
    BZRExpectFetchRecordsOperationAndComplete(privateDatabase, nil, nonRetryableError);

    auto recorder = [container.bzr_userRecordID testRecorder];

    expect(recorder).to.sendError(nonRetryableError);
    OCMVerifyAll(privateDatabase);
  });

  it(@"should deliver the identifier of the fetched user record", ^{
    BZRExpectFetchRecordsOperationAndComplete(privateDatabase, @{recordID: record}, nil);

    auto recorder = [container.bzr_userRecordID testRecorder];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[recordID]);
    OCMVerifyAll(privateDatabase);
  });

  it(@"should retry 3 times to fetch the user record if failed with a retryable error", ^{
    BZRExpectFetchRecordsOperationAndComplete(privateDatabase, nil, retryableError, 3);
    BZRExpectFetchRecordsOperationAndComplete(privateDatabase, @{recordID: record}, nil);

    auto recorder = [container.bzr_userRecordID testRecorder];

    expect(recorder).will.complete();
    expect(recorder).to.sendValues(@[recordID]);
    OCMVerifyAll(privateDatabase);
  });

  it(@"should err if operation failed after 3 retry attempts", ^{
    BZRExpectFetchRecordsOperationAndComplete(privateDatabase, nil, retryableError, 4);

    auto recorder = [container.bzr_userRecordID testRecorder];

    expect(recorder).will.sendError(retryableError);
    OCMVerifyAll(privateDatabase);
  });
});

SpecEnd
