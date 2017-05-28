// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSErrorCodes+Laboratory.h"

NS_ASSUME_NONNULL_BEGIN

LTErrorCodesImplement(LaboratoryErrorCodeProductID,
  /// Caused when a given experiment has not been found.
  LABErrorCodeExperimentNotFound,
  /// Caused when a given variant has not been found for a given experiment.
  LABErrorCodeVariantForExperimentNotFound,
  /// Caused when a source failed to fetch data.
  LABErrorCodeSourceDataFetchFailed
);

NS_ASSUME_NONNULL_END
