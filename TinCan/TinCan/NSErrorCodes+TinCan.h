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
  TINErrorCodeAppGroupAccessFailed
);

NS_ASSUME_NONNULL_END
