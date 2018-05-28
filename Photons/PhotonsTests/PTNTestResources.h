// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

@class PTNOceanAssetDescriptor, PTNOceanAssetSearchResponse;

NS_ASSUME_NONNULL_BEGIN

/// Returns a file URL with path to a video with 16x16 dimensions and approximately 1 second
/// duration.
NSURL *PTNOneSecondVideoURL(void);

/// Returns a file URL with path to for an image with 16x16 dimensions.
NSURL *PTNSmallImageURL(void);

/// Returns a file URL with path to a text file.
NSURL *PTNTextFileURL(void);

/// Returns a file URL with path to an image with metadata.
NSURL *PTNImageWithMetadataURL(void);

/// Returns a file URL with path to to a JSON file containing an Ocean search response.
NSURL *PTNOceanSearchResponseJSONURL(void);

/// Returns a file URL with path to to a JSON file containing an Ocean search response in which the
/// \c page field value is equal to the \c total_pages field.
NSURL *PTNOceanSearchResponseLastPageJSONURL(void);

/// Returns a file URL with path to to a JSON file containing an Ocean asset descriptor for a photo
/// asset.
NSURL *PTNOceanPhotoAssetDescriptorJSONURL(void);

/// Returns a file URL with path to a JSON file containing an Ocean asset descriptor for a video
/// asset.
NSURL *PTNOceanVideoAssetDescriptorJSONURL(void);

/// Returns a file URL with path to a JSON file containing an Ocean asset descriptor for a video
/// asset with some \c stream_url and \c download_url fields missing.
NSURL *PTNOceanPartialVideoAssetDescriptorJSONURL(void);

/// Returns a file URL with path to a JSON file containing an Ocean asset descriptor for a video
/// asset without any \c download_url fields.
NSURL *PTNOceanNoDownloadVideoAssetDescriptorJSONURL(void);

/// Returns a file URL with path to a JSON file containing an Ocean asset descriptor for a video
/// asset without any \c stream_url fields.
NSURL *PTNOceanNoStreamingVideoAssetDescriptorJSONURL(void);

NS_ASSUME_NONNULL_END
