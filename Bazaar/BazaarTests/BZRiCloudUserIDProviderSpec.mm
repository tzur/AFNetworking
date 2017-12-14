// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRiCloudUserIDProvider.h"

#import "BZRCloudKitAccountInfo.h"
#import "BZRCloudKitAccountInfoProvider.h"
#import "BZRCloudKitAccountStatus.h"

SpecBegin(BZRiCloudUserIDProvider)

__block BZRCloudKitAccountInfoProvider *accountInfoProvider;
__block RACSubject *accountInfoSubject;
__block BZRiCloudUserIDProvider *userRecordIDProvider;

beforeEach(^{
  accountInfoProvider = OCMClassMock([BZRCloudKitAccountInfoProvider class]);
  accountInfoSubject = [RACSubject subject];
  OCMStub([accountInfoProvider accountInfo]).andReturn(accountInfoSubject);
  userRecordIDProvider =
      [[BZRiCloudUserIDProvider alloc]
       initWithCloudKitAccountInfoProvider:accountInfoProvider];
});

it(@"should initialize user identifier to nil", ^{
  expect(userRecordIDProvider.userID).to.beNil();
});

it(@"should update when new account info is received with user record ID", ^{
  auto userIdentifierChanges = [RACObserve(userRecordIDProvider, userID) testRecorder];

  [accountInfoSubject sendNext:[[BZRCloudKitAccountInfo alloc]
                                initWithAccountStatus:$(BZRCloudKitAccountStatusAvailable)
                                containerIdentifier:@"foo" userRecordIdentifier:@"bar"]];

  expect(userIdentifierChanges).to.sendValues(@[[NSNull null], @"bar"]);
});

it(@"should be nil when new account info is received without user record ID ", ^{
  auto userIdentifierChanges = [RACObserve(userRecordIDProvider, userID) testRecorder];

  [accountInfoSubject sendNext:[[BZRCloudKitAccountInfo alloc]
                                initWithAccountStatus:$(BZRCloudKitAccountStatusRestricted)
                                containerIdentifier:@"foo" userRecordIdentifier:nil]];

  expect(userIdentifierChanges).to.sendValues(@[[NSNull null], [NSNull null]]);
});

SpecEnd
