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
  /// Caused when an assignment update operation failed.
  LABErrorCodeAssignmentUpdateFailed,
  /// Caused when a source failed to update itself.
  LABErrorCodeSourceUpdateFailed,
  /// Caused when a fetch operation failed.
  LABErrorCodeFetchFailed,
  /// Caused when an experiment was misconfigured.
  LABErrorCodeMisconfiguredExperiment,
  /// Caused when an update to \c FBTweak collection failed.
  LABErrorCodeTweaksCollectionsUpdateFailed
);

NS_ASSUME_NONNULL_END
