// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@class PTUCollectionViewConfiguration;

@protocol PTNAssetManager, PTUDataSourceProvider, PTNDescriptor;

/// Available target positions of item being scrolled to.
typedef NS_ENUM(NSUInteger, PTUCollectionViewScrollPosition) {
  /// Scrolling will end with item at the top or left when scrolling vertically or horizontally
  /// respectively.
  PTUCollectionViewScrollPositionTopLeft,
  /// Scrolling will end with item at the center.
  PTUCollectionViewScrollPositionCenter,
  /// Scrolling will end with item at the bottom or right when scrolling vertically or horizontally
  /// respectively.
  PTUCollectionViewScrollPositionBottomRight,
};

/// Protocol for controllers that contain a collection of Photons entities.
@protocol PTUCollectionViewController <NSObject>

/// Scrolls the collection view contents to its top (or left, if scrolling is done horizontally)
/// and optionally animates the change.
- (void)scrollToTopAnimated:(BOOL)animated;

/// Scrolls the collection view contents until the specified \c item is visible in \c position and
/// optionally animates the change. If \c item cannot be found in the collection this has no effect.
- (void)scrollToItem:(id<PTNDescriptor>)item
    atScrollPosition:(PTUCollectionViewScrollPosition)position
            animated:(BOOL)animated;

/// Sets \c item to be selected. Calling this method will not trigger values on the \c itemSelected
/// signal, or apply any scrolling. If \c item cannot be found in the collection this has no effect.
- (void)selectItem:(id<PTNDescriptor>)item;

/// Sets \c configuration as the receiver's current configuration. Calling this method changes the
/// underlying collection layout and possibly changes the offest of the scrolled content.
- (void)setConfiguration:(PTUCollectionViewConfiguration *)configuration animated:(BOOL)animated;

/// Discards the currently used \c PTUDataSource and fetches a new data source from the given
/// \c PTUDataSourceProvider to use in its place.
- (void)reloadData;

/// Hot signal sending the appropriate \c id<PTNDescriptor> of each selected item as it's being
/// selected. This signal does not err and completes when the receiver is deallocated.
///
/// @return <tt>RACSignal<id<PTNDescriptor>></tt>.
@property (readonly, nonatomic) RACSignal *itemSelected;

/// Hot signal sending an array of currently selected \c id<PTNDescriptor> objects. The signal sends
/// all selected items on every change to the selected item list. This signal does not err and
/// completes when the receiver is deallocated.
///
/// @return <tt>RACSignal<NSArray<id<PTNDescriptor>> *></tt>.
@property (readonly, nonatomic) RACSignal *selectedItems;

/// Hot signal sending the appropriate \c id<PTNDescriptor> of each deselected item as it's being
/// deselected. This signal does not err and completes when the receiver is deallocated.
///
/// @return <tt>RACSignal<id<PTNDescriptor>></tt>.
@property (readonly, nonatomic) RACSignal *itemDeselected;

/// Currently used configuration determining the layout properties of the collection view used in
/// this controller. Items containing descriptors that conform to \c PTNAlbumDescriptor are sized
/// using \c albumCellSizingStrategy, all other items are be sized using \c assetCellSizingStrategy.
@property (readonly, nonatomic) PTUCollectionViewConfiguration *configuration;

/// \c YES if the receiver is in multiple selection mode.
@property (nonatomic) BOOL allowsMultipleSelection;

@end

/// Implementation of \c PTUCollectionController that displays the content of a given
/// \c PTUDataSourceProvider according to a given configuration object. The controller adapts to
/// changes in its view's size to resize its content according to \c configuration.
///
/// The view controller contains views with the <tt>{CollectionView, Empty, Error}</tt>
/// accessibility identifiers.
@interface PTUCollectionViewController : UIViewController <PTUCollectionViewController>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

/// Initializes with \c dataSourceProvider to provide \c PTUDataSource objects used to configure
/// the receiver's \c UICollectionView and \c initialConfiguration.
- (instancetype)initWithDataSourceProvider:(id<PTUDataSourceProvider>)dataSourceProvider
                      initialConfiguration:(PTUCollectionViewConfiguration *)initialConfiguration
    NS_DESIGNATED_INITIALIZER;

/// Initializes with an \c assetManager and \c url used to create the default
/// \c PTUDataSourceProvider and default \c PTUCollectionViewConfiguration used as the
/// \c initialConfiguration.
///
/// @see initWithDataSourceProvider:initialConfiguration:.
- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager albumURL:(NSURL *)url;

/// View displayed behind the cells of this collection view controller's collection view, the view
/// will automatically track the size of the receiver's view.
@property (strong, nonatomic, nullable) UIView *backgroundView;

/// Background color of the receiver's collection view.
@property (strong, nonatomic) UIColor *backgroundColor;

/// View to display when the receiver's current \c PTUDataSource has no data, but did not err. The
/// view will automatically track the size of the receiver's view. The default view contains a
/// single \c UILabel containing the string "No photos".
@property (strong, nonatomic) UIView *emptyView;

/// View to display when the receiver's current \c PTUDataSource declares that an error occurred.
/// The view will automatically track the size of the receiver's view. Default view contains a
/// single \c UILabel containing the string "Error fetching data".
@property (strong, nonatomic) UIView *errorView;

@end

NS_ASSUME_NONNULL_END
