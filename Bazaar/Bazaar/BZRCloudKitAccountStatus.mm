// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRCloudKitAccountStatus.h"

NS_ASSUME_NONNULL_BEGIN

/// Status of the account associated with the CloudKit container.
LTEnumImplement(NSUInteger, BZRCloudKitAccountStatus,
  /// An error occurred while fetching the account status.
  BZRCloudKitAccountStatusCouldNotDetermine,
  /// iCloud account information is available.
  BZRCloudKitAccountStatusAvailable,
  /// Parental Controls / Device Management has denied access to iCloud account credentials.
  BZRCloudKitAccountStatusRestricted,
  /// No iCloud account is configured on this device.
  BZRCloudKitAccountStatusNoAccount
);

NS_ASSUME_NONNULL_END
