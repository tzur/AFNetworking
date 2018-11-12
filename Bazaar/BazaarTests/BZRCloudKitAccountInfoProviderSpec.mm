// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRCloudKitAccountInfoProvider.h"

#import "BZRCloudKitAccountInfo.h"
#import "BZRCloudKitAccountStatus.h"
#import "CKContainer+RACSignalSupport.h"

static BZRCloudKitAccountInfo *BZRAccountInfo(BZRCloudKitAccountStatus *accountStatus,
    CKContainer *container, CKRecordID * _Nullable recordIdentifier) {
  return [[BZRCloudKitAccountInfo alloc] initWithAccountStatus:accountStatus
                                           containerIdentifier:container.containerIdentifier
                                          userRecordIdentifier:recordIdentifier.recordName];
}

SpecBegin(BZRCloudKitAccountInfoProvider)

__block CKContainer *container;
__block NSNotificationCenter *notificationCenter;
__block BZRCloudKitAccountInfoProvider *provider;

beforeEach(^{
  container = OCMClassMock([CKContainer class]);
  OCMStub([container containerIdentifier]).andReturn(@"foo-bar");
  notificationCenter = [[NSNotificationCenter alloc] init];
  provider = [[BZRCloudKitAccountInfoProvider alloc] initWithContainer:container
                                                    notificationCenter:notificationCenter];
});

context(@"failed to fetch iCloud account status", ^{
  it(@"should err if failed to fetch iCloud account status", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([container bzr_accountStatus]).andReturn([RACSignal error:error]);

    auto recorder = [provider.accountInfo testRecorder];

    expect(recorder).to.sendError(error);
  });
});

context(@"iCloud account is not available", ^{
  beforeEach(^{
    auto accountStatus = $(BZRCloudKitAccountStatusNoAccount);
    OCMStub([container bzr_accountStatus]).andReturn([RACSignal return:accountStatus]);
  });

  it(@"should deliver account information with the account status", ^{
    auto recorder = [provider.accountInfo testRecorder];

    expect(recorder).will.matchValue(0, ^BOOL(BZRCloudKitAccountInfo *accountInfo) {
      return accountInfo.accountStatus.value == BZRCloudKitAccountStatusNoAccount &&
          [accountInfo.containerIdentifier isEqualToString:container.containerIdentifier] &&
          accountInfo.userRecordIdentifier == nil;
    });
  });

  it(@"should not fetch user record", ^{
    OCMReject([container bzr_userRecordID]);

    auto recorder = [provider.accountInfo testRecorder];

    expect(recorder).will.sendValuesWithCount(1);
  });
});

context(@"iCloud account is available", ^{
  beforeEach(^{
    auto accountStatus = $(BZRCloudKitAccountStatusAvailable);
    OCMStub([container bzr_accountStatus]).andReturn([RACSignal return:accountStatus]);
  });

  it(@"should deliver account information with the account status", ^{
    auto recorder = [provider.accountInfo testRecorder];

    expect(recorder).will.matchValue(0, ^BOOL(BZRCloudKitAccountInfo *accountInfo) {
      return accountInfo.accountStatus.value == BZRCloudKitAccountStatusAvailable &&
          [accountInfo.containerIdentifier isEqualToString:container.containerIdentifier] &&
          accountInfo.userRecordIdentifier == nil;
    });
  });

  it(@"should fetch user record", ^{
    auto userRecordID = [[CKRecordID alloc] initWithRecordName:@"user-record"];
    OCMExpect([container bzr_userRecordID]).andReturn([RACSignal return:userRecordID]);

    auto recorder = [provider.accountInfo testRecorder];

    expect(recorder).will.sendValuesWithCount(2);
    expect(recorder).will.matchValue(1, ^BOOL(BZRCloudKitAccountInfo *accountInfo) {
      return accountInfo.accountStatus.value == BZRCloudKitAccountStatusAvailable &&
          [accountInfo.containerIdentifier isEqualToString:container.containerIdentifier] &&
          [accountInfo.userRecordIdentifier isEqualToString:userRecordID.recordName];
    });
    OCMVerifyAll(container);
  });

  it(@"should err if fetching user record failed", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMExpect([container bzr_userRecordID]).andReturn([RACSignal error:error]);

    auto recorder = [provider.accountInfo testRecorder];

    expect(recorder).will.sendError(error);
    OCMVerifyAll(container);
  });
});

context(@"handling notifications", ^{
  /// Key in the shared examples data dictionary mapping to a name of a trigger notification.
  static auto const kBZRNotificationNameKey = @"BZRNotificationName";

  sharedExamplesFor(@"account info refetch trigger notification", ^(NSDictionary *data) {
    __block NSString *notificationName;

    beforeEach(^{
      notificationName = data[kBZRNotificationNameKey];
    });

    it(@"should refetch account information when notification is posted", ^{
      // Pre notification state: User is not signed in to iCloud.
      OCMExpect([container bzr_accountStatus])
          .andReturn([RACSignal return:$(BZRCloudKitAccountStatusNoAccount)]);
      OCMExpect([container bzr_accountStatus])
          .andReturn([RACSignal return:$(BZRCloudKitAccountStatusNoAccount)]);
      auto recorder = [provider.accountInfo testRecorder];
      OCMVerifyAll(container);

      // Post notification state: User is signed in to iCloud and user record is available.
      OCMExpect([container bzr_accountStatus])
          .andReturn([RACSignal return:$(BZRCloudKitAccountStatusAvailable)]);
      auto recordID = [[CKRecordID alloc] initWithRecordName:@"user-record"];
      OCMExpect([container bzr_userRecordID]).andReturn([RACSignal return:recordID]);
      [notificationCenter postNotificationName:notificationName object:nil];

      expect(recorder).to.sendValuesWithCount(2);
      expect(recorder).to.sendValues(@[
        BZRAccountInfo($(BZRCloudKitAccountStatusNoAccount), container, nil),
        BZRAccountInfo($(BZRCloudKitAccountStatusAvailable), container, recordID)
      ]);
      OCMVerifyAll(container);
    });

    it(@"should not send account info if account info has not changed", ^{
      OCMStub([container bzr_accountStatus])
          .andReturn([RACSignal return:$(BZRCloudKitAccountStatusAvailable)]);
      auto recordID = [[CKRecordID alloc] initWithRecordName:@"user-record"];
      OCMStub([container bzr_userRecordID]).andReturn([RACSignal return:recordID]);
      auto recorder = [provider.accountInfo testRecorder];

      [notificationCenter postNotificationName:notificationName object:nil];

      expect(recorder).to.sendValuesWithCount(2);
      expect(recorder).to.sendValues(@[
        BZRAccountInfo($(BZRCloudKitAccountStatusAvailable), container, nil),
        BZRAccountInfo($(BZRCloudKitAccountStatusAvailable), container, recordID)
      ]);
      OCMVerifyAll(container);
    });
  });

  itShouldBehaveLike(@"account info refetch trigger notification", @{
    kBZRNotificationNameKey: CKAccountChangedNotification
  });

  itShouldBehaveLike(@"account info refetch trigger notification", @{
    kBZRNotificationNameKey: UIApplicationWillEnterForegroundNotification
  });
});

SpecEnd
