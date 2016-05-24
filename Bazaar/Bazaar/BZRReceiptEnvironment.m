// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptEnvironment.h"

NS_ASSUME_NONNULL_BEGIN

/// Possible values of application receipt environment.
LTEnumImplement(NSUInteger, BZRReceiptEnvironment,
  BZRReceiptEnvironmentSandbox,
  BZRReceiptEnvironmentProduction
);

NS_ASSUME_NONNULL_END
