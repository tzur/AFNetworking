// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import <LTKit/NSErrorCodes+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of Warehouse.
  WarehouseErrorCodeProductID = 19
};

/// All error codes available in Warehouse.
LTErrorCodesDeclare(WarehouseErrorCodeProductID,
  /// Caused when writing to the storage failed.
  WHSErrorCodeWriteFailed,
  /// Caused when fetching from the storage failed.
  WHSErrorCodeFetchFailed,
  /// Caused when deleting from the storage failed.
  WHSErrorCodeDeleteFailed,
  /// Caused when calculating size of the storage or of a subcomponent of the storage failed.
  WHSErrorCodeCalculateSizeFailed
);

NS_ASSUME_NONNULL_END
