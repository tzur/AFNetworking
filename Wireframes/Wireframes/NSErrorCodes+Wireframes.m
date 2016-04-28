// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "NSErrorCodes+Wireframes.h"

NS_ASSUME_NONNULL_BEGIN

/// All error codes available in Wireframes.
LTErrorCodesImplement(WireframesErrorCodeProductID,
  /// Caused when an unrecognized URL scheme has been given.
  WFErrorCodeUnrecognizedURLScheme,
  /// Caused when an invalid URL has been given.
  WFErrorCodeInvalidURL,
  /// Caused when a requested asset could not be found.
  WFErrorCodeAssetNotFound
);

NS_ASSUME_NONNULL_END
