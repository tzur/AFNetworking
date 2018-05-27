// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// All error codes available in Warehouse.
LTErrorCodesImplement(WarehouseErrorCodeProductID,
  /// Caused when writing to the storage failed.
  WHSErrorCodeWriteFailed,
  /// Caused when fetching from the storage failed.
  WHSErrorCodeFetchFailed,
  /// Caused when deleting from the storage failed.
  WHSErrorCodeDeleteFailed
);

NS_ASSUME_NONNULL_END
