// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRiCloudUserIDProvider.h"

#import "BZRCloudKitAccountInfo.h"
#import "BZRCloudKitAccountInfoProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRiCloudUserIDProvider ()

/// Provider used to provide the user record ID.
@property (readonly, nonatomic) BZRCloudKitAccountInfoProvider *accountInfoProvider;

/// Identifier set to be the user record ID if its available, and \c nil otherwise.
@property (readwrite, nonatomic, nullable) NSString *userID;

@end

@implementation BZRiCloudUserIDProvider

@synthesize userID = _userID;

- (instancetype)init {
  auto accountInfoProvider =
      [[BZRCloudKitAccountInfoProvider alloc]
       initWithContainerIdentifier:@"iCloud.com.lightricks.Bazaar"];
  return [self initWithCloudKitAccountInfoProvider:accountInfoProvider];
}

- (instancetype)initWithCloudKitAccountInfoProvider:
    (BZRCloudKitAccountInfoProvider *)accountInfoProvider {
  if (self = [super init]) {
    _accountInfoProvider = accountInfoProvider;

    [self userRecordIDChanges];
  }

  return self;
}

- (void)userRecordIDChanges {
  auto userRecordIdentifierSignal = [self.accountInfoProvider.accountInfo
      map:^NSString * _Nullable(BZRCloudKitAccountInfo *accountInfo) {
        return accountInfo.userRecordIdentifier;
      }];
  [self rac_liftSelector:@selector(setUserID:) withSignalsFromArray:@[userRecordIdentifierSignal]];
}

- (void)setUserID:(nullable NSString *)userID {
  @synchronized(self) {
    _userID = userID;
  }
}

- (nullable NSString *)userID {
  @synchronized(self) {
    return _userID;
  }
}

@end

NS_ASSUME_NONNULL_END
