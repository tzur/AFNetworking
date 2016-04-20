// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/NSErrorCodes+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of Blueprints.
  BlueprintsErrorCodeProductID = 4
};

/// All error codes available in Blueprints.
LTErrorCodesDeclare(BlueprintsErrorCodeProductID,
  /// Caused when a node has not been found.
  BLUErrorCodeNodeNotFound,
  /// Caused when a path has not been found.
  BLUErrorCodePathNotFound
);

NS_ASSUME_NONNULL_END
