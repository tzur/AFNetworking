// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRSharedUserInfoReader.h"

#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"

/// Category for testing, exposes the method that creates the inner
/// \c BZRReceiptValidationStatusCache for accessing the cache.
@interface BZRSharedUserInfoReader (ForTesting)

/// Returns \c BZRReceiptValidationStatusCache with access to keychain with \c bundleIdentifier
/// service.
- (BZRReceiptValidationStatusCache *)receiptValidationStatusCacheForAppWithBundleIdentifier
    :(NSString *)bundleIdentifier;

@end

SpecBegin(BZRSharedUserInfo)
__block NSString *bundleIdentifier;
__block BZRReceiptInfo *receiptInfo;
__block BZRSharedUserInfoReader *sharedUserInfo;

beforeEach(^{
  bundleIdentifier = @"com.lightricks.sharedApp";

  BZRReceiptValidationStatusCache *receiptValidationStatusCache =
      OCMClassMock([BZRReceiptValidationStatusCache class]);

  BZRReceiptValidationStatus *receiptValidationStatus =
      OCMClassMock([BZRReceiptValidationStatus class]);
  receiptInfo = OCMClassMock([BZRReceiptInfo class]);
  OCMStub(receiptValidationStatus.receipt).andReturn(receiptInfo);

  auto receiptValidationStatusCacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                                            initWithReceiptValidationStatus:receiptValidationStatus
                                            cachingDateTime:[NSDate date]];
  OCMStub([receiptValidationStatusCache loadCacheEntry:nil])
      .andReturn(receiptValidationStatusCacheEntry);

  sharedUserInfo = OCMPartialMock([[BZRSharedUserInfoReader alloc] init]);
  OCMStub([sharedUserInfo receiptValidationStatusCacheForAppWithBundleIdentifier:bundleIdentifier])
      .andReturn(receiptValidationStatusCache);
});

it(@"should return NO if the user does not have subscription", ^{
  expect([sharedUserInfo isSubscriberOfAppWithBundleIdentifier:bundleIdentifier]).to.beFalsy();
});

it(@"should return YES if the user has active subscription", ^{
  BZRReceiptSubscriptionInfo *subscription = OCMClassMock([BZRReceiptSubscriptionInfo class]);
  OCMStub(subscription.isExpired).andReturn(NO);
  OCMStub(receiptInfo.subscription).andReturn(subscription);

  expect([sharedUserInfo isSubscriberOfAppWithBundleIdentifier:bundleIdentifier]).to.beTruthy();
});

it(@"should return NO if the user subscription is expired", ^{
  BZRReceiptSubscriptionInfo *subscription = OCMClassMock([BZRReceiptSubscriptionInfo class]);
  OCMStub(subscription.isExpired).andReturn(YES);
  OCMStub(receiptInfo.subscription).andReturn(subscription);

  expect([sharedUserInfo isSubscriberOfAppWithBundleIdentifier:bundleIdentifier]).to.beFalsy();
});

SpecEnd
