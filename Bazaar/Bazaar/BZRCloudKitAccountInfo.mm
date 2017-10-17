// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRCloudKitAccountInfo.h"

#import "BZRCloudKitAccountStatus.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRCloudKitAccountInfo

- (instancetype)initWithAccountStatus:(BZRCloudKitAccountStatus *)accountStatus
                  containerIdentifier:(NSString *)containerIdentifier
                 userRecordIdentifier:(nullable NSString *)userRecordIdentifier {
  if (self = [super init]) {
    _accountStatus = accountStatus;
    _containerIdentifier = [containerIdentifier copy];
    _userRecordIdentifier = [userRecordIdentifier copy];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
