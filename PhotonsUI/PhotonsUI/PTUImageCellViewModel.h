// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAssetManager, PTNDescriptor, PTNImageFetchOptions, PTUTimeFormatter;

@class AVPlayerItem;

/// Cell that represents an editing session.
extern NSString * const kPTUImageCellViewModelTraitSessionKey;

/// Cell that represents an asset that is backed by remote network storage. Note that the asset
/// might be already downloaded and cached by the client.
extern NSString * const kPTUImageCellViewModelTraitCloudBasedKey;

/// Cell that represents a video asset.
extern NSString * const kPTUImageCellViewModelTraitVideoKey;

/// Cell that represents a raw image asset.
extern NSString * const kPTUImageCellViewModelTraitRawKey;

/// Cell that represents a GIF asset.
extern NSString * const kPTUImageCellViewModelTraitGIFKey;

/// Cell that represents a Live Photo asset.
extern NSString * const kPTUImageCellViewModelTraitLivePhotoKey;

@class PTNImageFetchOptions;

/// Protocol for collection view image cells view models to conform to in order to be used by the
/// Photons framework.
@protocol PTUImageCellViewModel <NSObject>

/// Returns a signal carrying latest image to display in a cell of size \c cellSize in pixels, or
/// \c nil if no image should be set for such a cell.
- (nullable RACSignal *)imageSignalForCellSize:(CGSize)cellSize;

/// Returns a signal carrying an \c AVPlayerItem that contains a preview video of the receiver's
/// content, or \c nil if no preview is available for the receiver.
- (nullable RACSignal<AVPlayerItem *> *)playerItemSignal;

/// Signal carrying title to display, or \c nil if no values should be set for the title to display,
/// and it should be set to \c nil.
@property (readonly, nonatomic, nullable) RACSignal *titleSignal;

/// Signal carrying subtitle to display, or \c nil if no values should be set for the subtitle to
/// display, and it should be set to \c nil.
@property (readonly, nonatomic, nullable) RACSignal *subtitleSignal;

/// Signal carrying duration string to display, or \c nil if no values should be set for the
/// duration to display, and it should be set to \c nil.
@property (readonly, nonatomic, nullable) RACSignal *durationSignal;

/// Set of traits defining properties of the corresponding cell.
///
/// @see PTUImageCellViewModel.h for the cell default trait keys.
@property (readonly, nonatomic) NSSet<NSString *> *traits;

@end

/// \c PTUImageCellViewModel default implementation, delivering properties associated with a
/// \c PTNDescriptor instance. \c traits are derived from given descriptor's \c descriptorTraits.
@interface PTUImageCellViewModel : NSObject <PTUImageCellViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c assetManager, \c descriptor, \c imageFetchOptions and default \c
/// PTUTimeFormatter.
- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager
                          descriptor:(id<PTNDescriptor>)descriptor
                   imageFetchOptions:(PTNImageFetchOptions *)imageFetchOptions;

/// Initializes with \c assetManager, \c descriptor, \c imageFetchOptions and \c timeFormatter,
/// using them to fetch the image and properties associated with \c descriptor.
///   - Signal returned by \c imageSignalForCellSize: delivers the image of the given descriptor,
///     fetched using \c imageFetchOptions in the given \c cellSize using \c aspectFill resizing
///     strategy.
///   - \c titleSignal delivers the \c localizedTitle of the given descriptor.
///   - \c subtitleSignal delivers the number of photos in the corresponding album for
///     \c PTNAlbumDescriptor objects. For a descriptor of a video asset, it delivers the video's
///     duration. It is not set for other \c PTNDescriptor objects.
- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager
                          descriptor:(id<PTNDescriptor>)descriptor
                   imageFetchOptions:(PTNImageFetchOptions *)imageFetchOptions
                       timeFormatter:(id<PTUTimeFormatter>)timeFormatter
    NS_DESIGNATED_INITIALIZER;

/// Asset manager used to fetch image and asset backed by \c descriptor.
@property (readonly, nonatomic) id<PTNAssetManager> assetManager;

/// \c PTNDescriptor representing the data to display with this view model.
@property (readonly, nonatomic) id<PTNDescriptor> descriptor;

/// Options used when fetching the image associated with \c descriptor.
@property (readonly, nonatomic) PTNImageFetchOptions *imageFetchOptions;

@end

NS_ASSUME_NONNULL_END
