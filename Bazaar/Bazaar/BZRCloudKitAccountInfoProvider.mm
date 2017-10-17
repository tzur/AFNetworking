// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BZRCloudKitAccountInfoProvider.h"

#import <CloudKit/CloudKit.h>

#import "BZRCloudKitAccountInfo.h"
#import "BZRCloudKitAccountStatus.h"
#import "CKContainer+RACSignalSupport.h"

NS_ASSUME_NONNULL_BEGIN

// Fetches the iCloud account status.
//
// \c container is used to fetch the account status.
//
// Returns a signal that fetches iCloud account status on subscription, it delivers a single
// \c BZRCloudKitAccountInfo with the fetched account status and then completes. The signal errs
// if there was an unrecoverable error fetching the account status.
static RACSignal<BZRCloudKitAccountInfo *> *BZRAccountStatusWithContainer(CKContainer *container) {
  return [container.bzr_accountStatus
      map:^BZRCloudKitAccountInfo *(BZRCloudKitAccountStatus *accountStatus) {
        return [[BZRCloudKitAccountInfo alloc] initWithAccountStatus:accountStatus
                                                 containerIdentifier:container.containerIdentifier
                                                userRecordIdentifier:nil];
      }];
}

// Fetches the iCloud account status and the identifier of the user record associated with
// \c container.
//
// Returns a signal that fetches iCloud account status and user record identifier on subscription,
// it delivers a single \c BZRCloudKitAccountInfo with the fetched account information and then
// completes. The signal errs if there was an unrecoverable error fetching the account status or the
// user record associated with \c container.
static RACSignal<BZRCloudKitAccountInfo *> *BZRAccountInfoWithContainer(CKContainer *container) {
  return [BZRAccountStatusWithContainer(container)
      flattenMap:^RACSignal<BZRCloudKitAccountInfo *> *(BZRCloudKitAccountInfo *accountInfo) {
        if (accountInfo.accountStatus.value == BZRCloudKitAccountStatusAvailable) {
          return [container.bzr_userRecordID
              map:^BZRCloudKitAccountInfo *(CKRecordID *recordId) {
                return [[BZRCloudKitAccountInfo alloc]
                        initWithAccountStatus:accountInfo.accountStatus
                        containerIdentifier:accountInfo.containerIdentifier
                        userRecordIdentifier:recordId.recordName];
              }];
        }
        return [RACSignal return:accountInfo];
      }];
}

// Returns a signal that can be used as a trigger for refetching the iCloud account information.
// The signal sends a \c RACUnit value whenever it identifier refetch is required, it emits a
// value immediately on subscription to trigger initial fetch. The signal nerver errs or completes.
static RACSignal<RACUnit *> *BZRAccountInfoFetchRequired(NSNotificationCenter *notificationCenter) {
  return [[[RACSignal
      merge:@[
        [notificationCenter rac_addObserverForName:CKAccountChangedNotification object:nil],
        [notificationCenter rac_addObserverForName:UIApplicationWillEnterForegroundNotification
                                            object:nil]
      ]]
      mapReplace:[RACUnit defaultUnit]]
      startWith:[RACUnit defaultUnit]];
}

// Continuously fetches iCloud account information (account status and the identifier of the user
// record associated with \c container). \c notificationCenter is used to listen to
// notifications that requires refetching of the account information.
//
// Returns a signal that continuously fetches and delivers iCloud account infomration whenever a
// \c CKAccountChangedNotification or \c UIApplicationWillEnterForeground is observed. The signal
// errs if there was an unrecoverable error while fetching the account status or the user record
// associated with \c container. The signal never compeltes.
static RACSignal<BZRCloudKitAccountInfo *> *BZRRefetchAccountInfoWhenNeeded(CKContainer *container,
    NSNotificationCenter *notificationCenter) {
  return [BZRAccountInfoFetchRequired(notificationCenter)
      flattenMap:^RACSignal<BZRCloudKitAccountInfo *> *(RACUnit *) {
        return BZRAccountInfoWithContainer(container);
      }];
}

@interface BZRCloudKitAccountInfoProvider ()

/// Container used to fetch the user record from.
@property (readonly, nonatomic) CKContainer *container;

/// Notification center used to listen to notifications.
@property (readonly, nonatomic) NSNotificationCenter *notificationCenter;

@end

@implementation BZRCloudKitAccountInfoProvider

- (instancetype)init {
  return [self initWithContainer:[CKContainer defaultContainer]
              notificationCenter:[NSNotificationCenter defaultCenter]];
}

- (instancetype)initWithContainerIdentifier:(NSString *)identifier {
  auto container = [CKContainer containerWithIdentifier:identifier];
  return [self initWithContainer:container notificationCenter:[NSNotificationCenter defaultCenter]];
}

- (instancetype)initWithContainer:(CKContainer *)container
               notificationCenter:(NSNotificationCenter *)notificationCenter {
  if (self = [super init]) {
    _container = container;
    _notificationCenter = notificationCenter;
  }
  return self;
}

- (RACSignal<BZRCloudKitAccountInfo *> *)accountInfo {
  return [[BZRAccountStatusWithContainer(self.container)
      concat:BZRRefetchAccountInfoWhenNeeded(self.container, self.notificationCenter)]
      distinctUntilChanged];
}

@end

NS_ASSUME_NONNULL_END
