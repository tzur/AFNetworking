// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/NSErrorCodes+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of Laboratory.
  LaboratoryErrorCodeProductID = 13
};

/// All error codes available in Laboratory.
LTErrorCodesDeclare(LaboratoryErrorCodeProductID,
  /// Caused when a given experiment has not been found.
  LABErrorCodeExperimentNotFound,
  /// Caused when a given variant has not been found for a given experiment.
  LABErrorCodeVariantForExperimentNotFound,
  /// Caused when a source failed to fetch data.
  LABErrorCodeSourceDataFetchFailed
);

NS_ASSUME_NONNULL_END
