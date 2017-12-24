// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import <LTKit/NSErrorCodes+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of LTKit.
  TINErrorCodeProductID = 15
};

/// All error codes available in TinCan.
LTErrorCodesDeclare(TINErrorCodeProductID,
  /// Caused when invalid UTI is encountered.
  TINErrorCodeInvalidUTI,
  /// Caused when application doesn't have an entitlement to access an application group ID.
  TINErrorCodeAppGroupAccessFailed,
  /// Caused when message's target can't be found.
  TINErrorCodeMessageTargetNotFound,
  /// Caused when message can't be sent.
  TINErrorCodeMessageSendFailed,
  /// Caused when this application dones't support any scheme.
  TINErrorCodeNoValidSchemeFound
);

NS_ASSUME_NONNULL_END
