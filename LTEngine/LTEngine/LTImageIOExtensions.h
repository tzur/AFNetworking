// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Combines \c imageData with \c metadata and returns the result as \c NSData. On error, \c nil
/// will be returned and \c error will be set. Output image data will have the same format as
/// \c imageData. JPEG, PNG and TIFF formats are supported.
NSData * _Nullable LTCombineImageWithMetadata(NSData *imageData, NSDictionary * _Nullable metadata,
                                              NSError *__autoreleasing *error);

/// Combines \c imageData with \c metadata, while writing the result to \c url. On error, \c NO will
/// be returned and \c error will be set. Output image data will have the same format as
/// \c imageData. JPEG, PNG and TIFF formats are supported.
BOOL LTCombineImageWithMetadataAndSavetoURL(NSData *imageData, NSDictionary * _Nullable metadata,
                                            NSURL *url, NSError *__autoreleasing *error);

NS_ASSUME_NONNULL_END
