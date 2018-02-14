// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/NSErrorCodes+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of Intelligence.
  INTErrorCodeProductID = 16
};

/// All error codes available in Intelligence.
LTErrorCodesDeclare(INTErrorCodeProductID,
  /// Caused when a record saving operation has failed.
  INTErrorCodeDataRecordSaveFailed,
  /// Caused when a record sending operation has failed.
  INTErrorCodeJSONRecordsSendFailed,
  /// Caused when a JSON record or a group of JSON records is invalid.
  INTErrorCodeInvalidJSONRecords,
  /// Caused when a JSON batch size is too large.
  INTErrorCodeJSONBatchSizeTooLarge
);

NS_ASSUME_NONNULL_END
