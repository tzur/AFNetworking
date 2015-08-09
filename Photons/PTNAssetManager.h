// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PTNObject;

@class PTNImageFetchOptions;

/// Options for fitting an image’s aspect ratio to a requested size.
typedef NS_ENUM(NSUInteger, PTNImageContentMode) {
  /// Scales the image so that its larger dimension fits the target size.
  PTNImageContentModeAspectFit = PHImageContentModeAspectFit,
  /// Scales the image so that it completely fills the target size.
  PTNImageContentModeAspectFill = PHImageContentModeAspectFill
};

@protocol PTNAssetManager <NSObject>

/// Fetches the album identified by the given \c url, and continues to stream updates about the
/// album in the returned signal.
///
/// The returned signal sends \c PTNAlbumChangeset objects on an arbitrary thread. The signal can be
/// infinite or contain a single value, depending on the capabilities of the asset manager:
///
///   - If the manager is capable of observing the fetched album and reporting changes, the signal
///     will be infinite, where the first value contains the \c afterAlbum only, and each
///     consecutive value, which is sent upon an album update, contains all the change details with
///     respect to the previous value.
///   - If the manager is not capable of such observation, a single \c PTNAlbumChangeset
///     value will be sent upon fetch containing the \c afterAlbum only, and then the signal will
///     complete.
///
/// If the album doesn't exist, the signal will error.
///
/// @return RACSignal<PTNAlbumChangeset>.
- (RACSignal *)fetchAlbumWithURL:(NSURL *)url;

/// Fetches the asset identified by the given \url, and continues to stream updates about the asset
/// in the returned signal.
///
/// The returned signal sends \c id<PTNObject> objects that represent the asset, on an arbitrary
/// thread. The signal can be infinite or contain a single value, depending on the capabilities of
/// the asset manager:
///
///   - If the manager is capable of observing the fetched asset and reporting changes, the signal
///     will be infinite, where each value is sent upon asset update.
///   - If the manager is not capable of such observation, a single \c id<PTNObject> value will be
///     sent upon fetch, and then the signal will complete.
///
/// @return RACSignal<id<PTNObject>>.
- (RACSignal *)fetchAssetWithURL:(NSURL *)url;

/// Fetches the image which is backed by the object identified by the given \c url. For asset
/// objects, the returned image is the image represented by the asset. For album objects, the
/// returned image is a representative image for that album (which is usually the first or last
/// asset in that album).
///
/// The returned signal sends \c PTNProgress objects on an arbitrary thread, completes once the
/// final result is sent and errs if an error occurred while fetching the image. The result type
/// will always be a \c UIImage.
///
/// If the asset doesn't exist, the signal will err.
///
/// Disposal of the returned signal will abort the current image fetch operation, if in progress.
///
/// @return RACSignal<PTNProgress>.
- (RACSignal *)fetchImageWithURL:(NSURL *)url
                      targetSize:(CGSize)targetSize
                     contentMode:(PTNImageContentMode)contentMode
                         options:(PTNImageFetchOptions *)options;

/// Fetches the image which is backed by the given \c object. For asset objects, the returned image
/// is the image represented by the asset. For album objects, the returned image is a representative
/// image for that album (which is usually the first or last asset in that album).
///
/// The returned signal sends \c PTNProgress objects on an arbitrary thread, completes once the
/// final result is sent and errs if an error occurred while fetching the image. The result type
/// will always be a \c UIImage.
///
/// If the asset doesn't exist, the signal will err.
///
/// Disposal of the returned signal will abort the current image fetch operation, if in progress.
///
/// @return RACSignal<PTNProgress>.
- (RACSignal *)fetchImageWithObject:(id<PTNObject>)object
                         targetSize:(CGSize)targetSize
                        contentMode:(PTNImageContentMode)contentMode
                            options:(PTNImageFetchOptions *)options;

@end

NS_ASSUME_NONNULL_END
