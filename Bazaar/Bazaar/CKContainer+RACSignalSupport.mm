// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "CKContainer+RACSignalSupport.h"

#import "BZRCloudKitAccountStatus.h"
#import "RACSignal+CloudKitRetry.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRCloudKitAccountStatus+CKAccountStatus
#pragma mark -

/// Adds convenience conversion from \c CKAccountStatus.
@interface BZRCloudKitAccountStatus (CKAccountStatus)

/// Create a new enum value with the given \c CKAccountStatus value.
+ (instancetype)enumWithCloudKitAccountStatus:(CKAccountStatus)accountStatus;

@end

@implementation BZRCloudKitAccountStatus (CKAccountStatus)

+ (instancetype)enumWithCloudKitAccountStatus:(CKAccountStatus)accountStatus {
  switch (accountStatus) {
    case CKAccountStatusAvailable:
      return $(BZRCloudKitAccountStatusAvailable);
    case CKAccountStatusNoAccount:
      return $(BZRCloudKitAccountStatusNoAccount);
    case CKAccountStatusRestricted:
      return $(BZRCloudKitAccountStatusRestricted);
    case CKAccountStatusCouldNotDetermine:
      return $(BZRCloudKitAccountStatusCouldNotDetermine);
  }
}

@end

#pragma mark -
#pragma mark CKContainer+RACSignalSupport
#pragma mark -

@implementation CKContainer (RACSignalSupport)

- (RACSignal<BZRCloudKitAccountStatus *> *)bzr_accountStatus {
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [self accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus,
                                               NSError * _Nullable error) {
      if (error) {
        [subscriber sendError:error];
      } else {
        auto *value = [BZRCloudKitAccountStatus enumWithCloudKitAccountStatus:accountStatus];
        [subscriber sendNext:value];
        [subscriber sendCompleted];
      }
    }];

    return nil;
  }]
  bzr_retryCloudKitErrorIfNeeded:3];
}

- (RACSignal<CKRecordID *> *)bzr_userRecordID {
  CKDatabase *privateCloudDatabase = self.privateCloudDatabase;
  return [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    CKFetchRecordsOperation *operation = [CKFetchRecordsOperation fetchCurrentUserRecordOperation];
    operation.fetchRecordsCompletionBlock =
        ^(NSDictionary<CKRecordID *, CKRecord *> * _Nullable recordsByRecordID,
          NSError * _Nullable operationError) {
      if (operationError) {
        [subscriber sendError:operationError];
      } else {
        [subscriber sendNext:recordsByRecordID.allKeys.firstObject];
        [subscriber sendCompleted];
      }
    };

    [privateCloudDatabase addOperation:operation];

    return [RACDisposable disposableWithBlock:^{
      if (!(operation.isFinished || operation.isCancelled)) {
        [operation cancel];
      }
    }];
  }]
  bzr_retryCloudKitErrorIfNeeded:3];
}

@end

NS_ASSUME_NONNULL_END
