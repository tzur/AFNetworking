// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/NSErrorCodes+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of LTEngine.
  LTEngineErrorCodeProductID = 1
};

/// All error codes available in LTEngine.
LTErrorCodesDeclare(LTEngineErrorCodeProductID,
  /// Caused when the compression process has failed.
  LTErrorCodeCompressionFailed
);

NS_ASSUME_NONNULL_END
