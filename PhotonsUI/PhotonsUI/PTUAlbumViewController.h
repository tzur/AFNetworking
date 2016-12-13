// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

@protocol PTUAlbumViewModel, PTUErrorViewProvider;

@class PTUCollectionViewConfiguration;

/// View controller displaying an album of images using \c PTUCollectionViewController instance
/// while exposing \c MVVM interface.
@interface PTUAlbumViewController : UIViewController

/// Initializes with \c viewModel used to configure and control an internal collection of images
/// configured with the given \c configuration.
///
/// The view contains a \c UICollectionView with the \c CollectionView accessibility identifier.
- (instancetype)initWithViewModel:(id<PTUAlbumViewModel>)viewModel
                    configuration:(PTUCollectionViewConfiguration *)configuration
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

/// Creates and returns an \c PTUAlbumViewController initialized with \c viewModel and
/// <tt>[PTUCollectionViewConfiguration photoStrip]</tt> configuration.
///
/// @see -initWithViewModel:configuration:.
+ (instancetype)photoStripWithViewModel:(id<PTUAlbumViewModel>)viewModel;

/// Creates and returns an \c FPTUAlbumViewController initialized with \c viewModel and
/// <tt>[PTUCollectionViewConfiguration defaultConfiguration]</tt> configuration.
///
/// @see -initWithViewModel:configuration:.
+ (instancetype)albumWithViewModel:(id<PTUAlbumViewModel>)viewModel;

/// View model that controls this view controller.
@property (readonly, nonatomic) id<PTUAlbumViewModel> viewModel;

/// Title of the data associated with this album view controller according to the latest data
/// source. This property is KVO compliant.
@property (readonly, nonatomic, nullable) NSString *localizedTitle;

/// View to display when the receiver's current \c PTUDataSource has no data, but did not err. The
/// view will automatically track the size of the receiver's view. The default view is
/// <tt>[PTUCollectionView defaultEmptyView]</tt>.
@property (strong, nonatomic) UIView *emptyView;

/// Current view used to display when the receiver's current \c PTUDataSource declares that an error
/// occurred. This property is set by \c errorViewProvider if given. The view will automatically
/// track the size of the receiver's view. The default view is
/// <tt>[PTUCollectionView defaultErrorView]</tt>.
@property (strong, nonatomic) UIView *errorView;

/// View displayed behind the cells of this collection view controller's collection view, the view
/// will automatically track the size of the receiver's view. Setting this view will add it the the
/// receiver's view hierarchy. Setting this view to \c nil will result in no view to be displayed
/// behind the collection view, which is the default behavior.
@property (strong, nonatomic, nullable) UIView *backgroundView;

/// Provider of views to display when the receiver's current \c PTUDataSource declares that an error
/// occurred. The provider will be queried upon error, and the view it returns will be set as the
/// receiver's error view, automatically tracking the size of the receiver's view. If \c nil, the
/// current \c errorView will remain unchanged.
@property (strong, nonatomic, nullable) id<PTUErrorViewProvider> errorViewProvider;

@end

NS_ASSUME_NONNULL_END
