// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of Photons.
  PhotonsErrorCodeProductID = 3
};

/// All error codes available in Photons.
NS_ENUM(NSInteger) {
  /// Caused when an invalid URL has been given.
  PTNErrorCodeInvalidURL = LTErrorCodeBase + PhotonsErrorCodeProductID,
  /// Caused when a requested album has not been found.
  PTNErrorCodeAlbumNotFound,
  /// Caused when a requested asset has not been found.
  PTNErrorCodeAssetNotFound,
  /// Caused when key assets for an album were not found.
  PTNErrorCodeKeyAssetsNotFound,
  /// Caused when asset contents loading has failed.
  PTNErrorCodeAssetLoadingFailed,
  /// Caused when an invalid asset type has been given.
  PTNErrorCodeInvalidAssetType,
  /// Caused when an invalid object has been given.
  PTNErrorCodeInvalidObject
};
