// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import <CloudKit/CloudKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BZRCloudKitAccountStatus;

/// Adds reactive interface for \c CKContainer. Providing basic account information via signals
/// that take care of retrying when possible, and wait for iCloud reachability when applicable.
@interface CKContainer (RACSignalSupport)

/// Signal that sends the account status.
///
/// Upon subscription the signal queries CloudKit for the current account status. The signal
/// delivers a single \c BZRCloudKitAccountStatus value and then completes. If an error occurs while
/// fetching the account status, in case CloudKit suggests retrying with some delay the fetching
/// will be retried after the suggested delay up to 3 times otherwise the signal will err.
///
/// @note In case this method returns a value other than \c BZRCloudKitAccountStatusAvailable other
/// container methods and requests may fail. Use this method to check account availability before
/// accessing the containers private database.
@property (readonly, nonatomic) RACSignal<BZRCloudKitAccountStatus *> *bzr_accountStatus;

/// Signal that sends the user's record identifier.
///
/// Upon subscription, if iCloud is reachable the signal starts fetching the user's record
/// identifier otherwise it waits until iCloud becomes reachable. The signal delivers a single
/// \c CKRecordID value and then completes. If an error occurs while fetching the user record
/// identifier, in case CloudKit suggests retrying with some delay the fetching will be retried
/// after the suggested delay up to 3 times otherwise the signal will err.
///
/// @note If the user is currently not signed in to iCloud or there's a restriction accessing iCloud
/// account inforamtion the signal will err.
@property (readonly, nonatomic) RACSignal<CKRecordID *> *bzr_userRecordID;

@end

NS_ASSUME_NONNULL_END
