// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAssetManager, PTNDescriptor, PTNImageFetchOptions;

/// Cell that represents an editing session.
extern NSString * const kPTUImageCellViewModelTraitSessionKey;

/// Cell that represents an asset that is backed by remote network storage. Note that the asset
/// might be already downloaded and cached by the client.
extern NSString * const kPTUImageCellViewModelTraitCloudBasedKey;

@class PTNImageFetchOptions;

/// Protocol for collection view image cells view models to conform to in order to be used by the
/// Photons framework.
@protocol PTUImageCellViewModel <NSObject>

/// Returns a signal carrying latest image to display in a cell of size \c cellSize in pixels, or
/// \c nil if no image should be set for such a cell.
- (nullable RACSignal *)imageSignalForCellSize:(CGSize)cellSize;

/// Signal carrying title to display, or \c nil if no values should be set for the title to display,
/// and it should be set to \c nil.
@property (readonly, nonatomic, nullable) RACSignal *titleSignal;

/// Signal carrying subtitle to display, or \c nil if no values should be set for the subtitle to
/// display, and it should be set to \c nil.
@property (readonly, nonatomic, nullable) RACSignal *subtitleSignal;

/// Set of traits defining properties of the corresponding cell.
///
/// @see PTUImageCellViewModel.h for the cell default trait keys.
@property (readonly, nonatomic) NSSet<NSString *> *traits;

@end

/// \c PTUImageCellViewModel default implementation, delivering properties associated with a
/// \c PTNDescriptor instance. \c traits are derived from given descriptor's \c descriptorTraits.
@interface PTUImageCellViewModel : NSObject <PTUImageCellViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c assetManager, \c descriptor and \c imageFetchOptions, using them to fetch
/// the image and properties associated with \c descriptor.
///   - Signal returned by \c imageSignalForCellSize: delivers the image of the given descriptor,
///     fetched using \c imageFetchOptions in the given \c cellSize using \c aspectFill resizing
///     strategy.
///   - \c titleSignal delivers the \c localizedTitle of the given descriptor.
///   - \c subtitleSignal delivers the number of photos in the corresponding album for
///     \c PTNAlbumDescriptor objects and is not set for other \c PTNDescriptor objects.
- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager
                          descriptor:(id<PTNDescriptor>)descriptor
                   imageFetchOptions:(PTNImageFetchOptions *)imageFetchOptions
    NS_DESIGNATED_INITIALIZER;

/// Asset manager used to fetch image and asset backed by \c descriptor.
@property (readonly, nonatomic) id<PTNAssetManager> assetManager;

/// \c PTNDescriptor representing the data to display with this view model.
@property (readonly, nonatomic) id<PTNDescriptor> descriptor;

/// Options used when fetching the image associated with \c descriptor.
@property (readonly, nonatomic) PTNImageFetchOptions *imageFetchOptions;

@end

NS_ASSUME_NONNULL_END
