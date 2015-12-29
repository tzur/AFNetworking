// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSErrorCodes+Photons.h"

/// All error codes available in Photons.
LTErrorCodesImplement(PhotonsErrorCodeProductID,
  /// Caused when an invalid URL has been given.
  PTNErrorCodeInvalidURL,
  /// Caused when a requested album has not been found.
  PTNErrorCodeAlbumNotFound,
  /// Caused when a requested asset has not been found.
  PTNErrorCodeAssetNotFound,
  /// Caused when key assets for an album were not found.
  PTNErrorCodeKeyAssetsNotFound,
  /// Caused when asset contents loading has failed.
  PTNErrorCodeAssetLoadingFailed,
  /// Caused when asset metadata loading has failed.
  PTNErrorCodeAssetMetadataLoadingFailed,
  /// Caused when an invalid asset type has been given.
  PTNErrorCodeInvalidAssetType,
  /// Caused when an invalid descriptor has been given.
  PTNErrorCodeInvalidDescriptor,
  /// Caused when descriptor has failed to create itself.
  PTNErrorCodeDescriptorCreationFailed
);
