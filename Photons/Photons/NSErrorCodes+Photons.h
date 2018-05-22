// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/NSErrorCodes+LTKit.h>

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of Photons.
  PhotonsErrorCodeProductID = 3
};

/// All error codes available in Photons.
LTErrorCodesDeclare(PhotonsErrorCodeProductID,
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
  PTNErrorCodeDescriptorCreationFailed,
  /// Caused when an unrecognized URL scheme has been given.
  PTNErrorCodeUnrecognizedURLScheme,
  /// Caused when an authorization process has failed.
  PTNErrorCodeAuthorizationFailed,
  /// Caused when an authorization revocation has failed.
  PTNErrorCodeAuthorizationRevocationFailed,
  /// Caused when no authorization was given for the source.
  PTNErrorCodeNotAuthorized,
  /// Caused when deletion of assets has failed.
  PTNErrorCodeAssetDeletionFailed,
  // Caused when removal of assets has from an album has failed.
  PTNErrorCodeAssetRemovalFromAlbumFailed,
  // Caused when attemping to make an unsupported operation.
  PTNErrorCodeUnsupportedOperation,
  // Caused when extracting image from asset has failed.
  PTNErrorCodeAVImageAssetFetchImageFailed,
  // Caused when deserialization has failed.
  PTNErrorCodeDeserializationFailed,
  // Caused when failing while validating a cached response.
  PTNErrorCodeCacheValidationFailed,
  // Caused when extracting image data from asset has failed.
  PTNErrorCodeAVImageAssetFetchImageDataFailed,
  // Caused when a fetch operation of remote asset failed.
  PTNErrorCodeRemoteFetchFailed
);
