// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for \c PTNAssetManager objects that support caching.
///
/// @important For the caching to operate correctly the conforming asset manager must return
/// \c PTNCacheProxy objects wrapping its \c PTNDescriptor, \c PTNAlbum and \c PTNImageAsset
/// objects for any \c -fetchDescriptor: \c -fetchAlbumWithURL: and
/// \c -fetchImageWithDescriptor:resizingStrategey:options respectively. Additionally
/// \c PTNImageAsset objects must also conform to the \c PTNDataAsset protocol.
///
/// @see PTNCachingAssetManager
@protocol PTNCacheAwareAssetManager <PTNAssetManager>

/// Returns a signal that sends \c YES if the \c PTNAlbum identified with \c entityTag (if
/// originally provided for the album) represents the album that would have been fetched with
/// \c url. The signal then completes. The signal errs with \c PTNErrorCodeCacheValidationFailed
/// error code if an error occurred while validating the album.
- (RACSignal<NSValue *> *)validateAlbumWithURL:(NSURL *)url entityTag:(nullable NSString *)entityTag;

/// Returns a signal that sends \c YES if the \c PTNDescriptor identified with \c entityTag (if
/// originally provided for the descriptor) represents the descriptor that would have been fetched
/// with \c url. The signal then completes. The signal errs with
/// \c PTNErrorCodeCacheValidationFailed error code if an error occurred while validating the
/// descriptor.
- (RACSignal<NSValue *> *)validateDescriptorWithURL:(NSURL *)url
                                          entityTag:(nullable NSString *)entityTag;

/// Returns a signal that sends \c YES if the \c PTNImageAsset identified with \c entityTag (if
/// originally provided for the image asset) represents the image asset that would have been fetched
/// with \c descriptor, \c resizingStrategy and \c options. The signal then completes. The signal
/// errs with \c PTNErrorCodeCacheValidationFailed error code if an error occurred while validating
/// the image asset.
- (RACSignal<NSValue *> *)validateImageWithDescriptor:(id<PTNDescriptor>)descriptor
                                     resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                              options:(PTNImageFetchOptions *)options
                                            entityTag:(nullable NSString *)entityTag;

/// Returns a generic representation of the image asset that will be fetched with \c descriptor
/// \c resizingStrategy and \c options if available or \c nil if no such representation is
/// available. This is a cache optimization mechanism that allows the same asset to be used for
/// several requests when the underlying asset is shared between those requests.
///
/// An example of when this is useful is when images sizes are bucketed. In Dropbox for example,
/// fetching is possible in a number of distinct sizes, such as \c 128x128 and \c 640x480. When
/// requesting an image of size 200x200, it will return the 640x480 version and cache it, how ever
/// all requested sizes up-to 640x480 can share that cached resource.
- (nullable NSURL *)canonicalURLForDescriptor:(id<PTNDescriptor>)descriptor
                             resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                      options:(PTNImageFetchOptions *)options;

@end

NS_ASSUME_NONNULL_END
