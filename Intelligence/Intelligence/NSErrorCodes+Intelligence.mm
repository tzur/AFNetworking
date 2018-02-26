// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSErrorCodes+Intelligence.h"

NS_ASSUME_NONNULL_BEGIN

LTErrorCodesImplement(INTErrorCodeProductID,
  /// Caused when a record saving operation has failed.
  INTErrorCodeDataRecordSaveFailed,
  /// Caused when a record sending operation has failed.
  INTErrorCodeJSONRecordsSendFailed,
  /// Caused when a a JSON record or a group of JSON records is invalid.
  INTErrorCodeInvalidJSONRecords,
  // Caused when a JSON batch size is too large.
  INTErrorCodeJSONBatchSizeTooLarge
);

NS_ASSUME_NONNULL_END
