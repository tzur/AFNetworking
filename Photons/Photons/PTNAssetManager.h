// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <AVFoundation/AVPlayerItem.h>

#import "PTNAVDataAsset.h"
#import "PTNAudiovisualAsset.h"
#import "PTNImageAsset.h"
#import "PTNImageContentMode.h"
#import "PTNImageDataAsset.h"
#import "PTNProgress.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAlbumDescriptor, PTNAssetDescriptor, PTNDescriptor, PTNResizingStrategy;

@class PTNAVAssetFetchOptions, PTNAlbumChangeset, PTNImageFetchOptions;

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
- (RACSignal<PTNAlbumChangeset *> *)fetchAlbumWithURL:(NSURL *)url;

/// Fetches the \c PTNDescriptor of the asset identified by the given \url, and continues to stream
/// updates about the asset in the returned signal.
///
/// The returned signal sends \c id<PTNDescriptor> objects that represent the asset, on an arbitrary
/// thread. The signal can be infinite or contain a single value, depending on the capabilities of
/// the asset manager:
///
///   - If the manager is capable of observing the fetched asset and reporting changes, the signal
///     will be infinite, where each value is sent upon asset update.
///   - If the manager is not capable of such observation, a single \c id<PTNDescriptor> value will
///     be sent upon fetch, and then the signal will complete.
- (RACSignal<id<PTNDescriptor>> *)fetchDescriptorWithURL:(NSURL *)url;

/// Fetches the image which is backed by the given \c descriptor. For asset descriptors, the
/// returned image is the image represented by the asset. For album descriptors, the returned image
/// is a representative image for that album (which is usually the first or last asset in that
/// album).
///
/// The returned signal sends \c PTNProgress objects on an arbitrary thread, completes once the
/// final result is sent and errs if an error occurred while fetching the image asset, or if
/// creation of the image asset has failed. The result type will always be a \c PTNImageAsset.
///
/// If the asset doesn't exist, the signal will err.
///
/// Disposal of the returned signal will abort the current image fetch operation, if in progress.
- (RACSignal<PTNProgress<id<PTNImageAsset>> *> *)
    fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
    resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
    options:(PTNImageFetchOptions *)options;

/// Fetches the audiovisual asset which is backed by the given \c descriptor.
///
/// The returned signal sends \c PTNProgress objects on an arbitrary thread, completes once the
/// final result is sent and errs if an error occurred while fetching the asset. The result type
/// will always be a \c PTNAudiovisualAsset.
///
/// If the asset doesn't exist, the signal will err.
///
/// Disposal of the returned signal will abort the current asset fetch operation, if in progress.
- (RACSignal<PTNProgress<id<PTNAudiovisualAsset>> *> *)
    fetchAVAssetWithDescriptor:(id<PTNDescriptor>)descriptor
    options:(PTNAVAssetFetchOptions *)options;

/// Fetches the image data which is backed by the given \c descriptor. The returned signal will err
/// if \c descriptor is not an asset descriptor.
///
/// The returned signal sends \c PTNProgress objects on a arbitrary thread, complete once the final
/// result is sent and errs if an error occurs while fetching the image. The result type will
/// always be a \c PTNImageDataAsset.
///
/// If the asset doesn't exist, the signal will err.
///
/// Disposal of the returned signal will abort the current image data fetch operation, if in
/// progress.
- (RACSignal<PTNProgress<id<PTNImageDataAsset>> *> *)
    fetchImageDataWithDescriptor:(id<PTNDescriptor>)descriptor;

/// Fetches an \c AVPlayerItem that contains a preview to the asset backed by \c descriptor.
///
/// The returned signal sends \c PTNProgress objects on an arbitrary thread, completes once the
/// final result is sent and errs if an error occurred while fetching the player item. The result
/// type will always be a \c AVPlayerItem.
///
/// If the asset doesn't exist, the signal will err.
///
/// Disposal of the returned signal will abort the current fetch operation, if in progress.
- (RACSignal<PTNProgress<AVPlayerItem *> *> *)
    fetchAVPreviewWithDescriptor:(id<PTNDescriptor>)descriptor
    options:(PTNAVAssetFetchOptions *)options;

/// Fetches the audiovisual data which is backed by the given \c descriptor. The returned signal
/// will err if \c descriptor is not an asset descriptor.
///
/// The returned signal sends \c PTNProgress objects on a arbitrary thread, complete once the final
/// result is sent and errs if an error occurs while fetching the data. The result type will
/// always be a \c PTNAVDataAsset.
///
/// If the asset doesn't exist, the signal will err.
///
/// Disposal of the returned signal will abort the current data fetch operation, if in progress.
- (RACSignal<PTNProgress<id<PTNAVDataAsset>> *>*)
    fetchAVDataWithDescriptor:(id<PTNDescriptor>)descriptor;

@optional

/// Permanently deletes the assets backed by the given \c descriptors. Each \c PTNDescriptor must
/// support \c PTNDescriptorCapabilityDelete in their \c PTNDescriptorCapabilities in order to be
/// eligible for deletion.
///
/// The returned signal completes on an arbitrary thread once the assets were successfully deleted
/// and errs if an error occurred while deleting the assets. The signal sends no values.
///
/// @return RACSignal<>.
- (RACSignal *)deleteDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors;

/// Removes the assets backed by the given \c descriptors. \c albumDescriptor must support
/// \c PTNAlbumDescriptorCapabilityRemoveContent in its \c PTNAlbumDescriptorCapabilities in order
/// for \c descriptors be eligible for removal from it.
///
/// The returned signal completes on an arbitrary thread once the assets were successfully removed
/// and errs if an error occurred while removing the assets. The signal sends no values.
///
/// @return RACSignal<>.
- (RACSignal *)removeDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors
                       fromAlbum:(id<PTNAlbumDescriptor>)albumDescriptor;

/// Sets the favorite value of the assets backed the given by \c descriptors to \c favorite.
/// \c descriptors must all support \c PTNAssetDescriptorCapabilityFavorite in their
/// \c PTNAssetDescriptorCapabilities in order to be eligible for favoring.
///
/// The returned signal completes on an arbitrary thread once all the assets favorite value was
/// successfully set to \c favorite, and errs if an error occurred while favoring the assets. The
/// signal sends no values.
///
/// @return RACSignal<>.
- (RACSignal *)favoriteDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors
                          favorite:(BOOL)favorite;

@end

NS_ASSUME_NONNULL_END
