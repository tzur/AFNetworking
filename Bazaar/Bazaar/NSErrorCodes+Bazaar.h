// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import <LTKit/NSErrorCodes+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of Bazaar.
  BazaarErrorCodeProductID = 10
};

/// All error codes produced by Bazaar.
LTErrorCodesDeclare(BazaarErrorCodeProductID,
  /// The process of application receipt validation has failed.
  BZRErrorCodeReceiptValidationFailed,
  /// Failure during products metadata fetching.
  BZRErrorCodeProductsMetadataFetchingFailed
);

NS_ASSUME_NONNULL_END
