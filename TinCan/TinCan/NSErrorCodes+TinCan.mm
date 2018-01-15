// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSErrorCodes+TinCan.h"

NS_ASSUME_NONNULL_BEGIN

LTErrorCodesImplement(TINErrorCodeProductID,
  /// Caused when invalid UTI is encountered.
  TINErrorCodeInvalidUTI,
  /// Caused when application doesn't have an entitlement to access an application group ID.
  TINErrorCodeAppGroupAccessFailed,
  /// Caused when message's target can't be found.
  TINErrorCodeMessageTargetNotFound,
  /// Caused when message can't be sent.
  TINErrorCodeMessageSendFailed,
  /// Cause when this application dones't support any scheme.
  TINErrorCodeNoValidSchemeFound
);

NS_ASSUME_NONNULL_END
