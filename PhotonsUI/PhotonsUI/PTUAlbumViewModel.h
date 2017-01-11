// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

@protocol PTUChangesetProvider, PTNDescriptor, PTNAssetManager;

/// View model for a view displaying an image collection.
@protocol PTUAlbumViewModel <NSObject>

/// Signal sending the latest \c PTUDataSourceProvider used to determine the contents of the album
/// view.
@property (readonly, nonatomic) RACSignal *dataSourceProvider;

/// Signal sending an array of \c PTNDescriptor objects to be set as selected assets.
@property (readonly, nonatomic) RACSignal *selectedAssets;

/// Hot signal sending <tt>(id<PTNDescriptor>, PTUCollectionViewScrollPosition)</tt> tuples
/// representing an asset that should be scrolled to and the position in which to apply the
/// scrolling.
@property (readonly, nonatomic) RACSignal *scrollToAsset;

/// Hot signal that sends a corresponding \c id<PTNDescriptor> each time an asset is selected.
@property (strong, nonatomic, nullable) RACSignal *assetSelected;

/// Hot signal sending the appropriate \c id<PTNDescriptor> of each deselected item as it's being
/// deselected.
@property (strong, nonatomic) RACSignal *assetDeselected;

/// Default title of the album view used whenever the underlying title is \c nil. If set to \c nil
/// the title has no default value and remains \c nil.
@property (readonly, nonatomic, nullable) NSString *defaultTitle;

/// URL associated with this album view model or \c nil if no such URL is available.
@property (readonly, nonatomic, nullable) NSURL *url;

@end

/// Concrete implementation of \c id<PTUAlbumViewModel> initialized with signals.
@interface PTUAlbumViewModel : NSObject <PTUAlbumViewModel>

/// Initializes with the signals required by \c id<PTUAlbumViewModel>.
- (instancetype)initWithDataSourceProvider:(RACSignal *)dataSourceProvider
                            selectedAssets:(RACSignal *)selectedAssets
                             scrollToAsset:(RACSignal *)scrollToAsset
                              defaultTitle:(nullable NSString *)defaultTitle
                                       url:(nullable NSURL *)url
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
