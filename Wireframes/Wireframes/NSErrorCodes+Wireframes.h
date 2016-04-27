// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import <LTKit/NSErrorCodes+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of Wireframes.
  WireframesErrorCodeProductID = 4
};

/// All error codes available in Wireframes.
LTErrorCodesDeclare(WireframesErrorCodeProductID,
  /// Caused when an unrecognized URL scheme has been given.
  WFErrorCodeUnrecognizedURLScheme,
  /// Caused when an invalid URL has been given.
  WFErrorCodeInvalidURL,
  /// Caused when a requested asset could not be found.
  WFErrorCodeAssetNotFound
);

NS_ASSUME_NONNULL_END
