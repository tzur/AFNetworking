// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Possible types of authorization request responses.
LTEnumDeclare(NSUInteger, PTNAuthorizationStatus,
  /// User has not yet granted or denied access to this source.
  PTNAuthorizationStatusNotDetermined,
  /// User cannot grant such permission.
  PTNAuthorizationStatusRestricted,
  /// User has explicitly denied the app access to this source.
  PTNAuthorizationStatusDenied,
  /// User has explicitly granted the app access to this source.
  PTNAuthorizationStatusAuthorized
);

NS_ASSUME_NONNULL_END
