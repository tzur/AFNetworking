// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@protocol PTUImageCellViewModel;

NS_ASSUME_NONNULL_BEGIN

/// Protocol for collection view cells to conform to in order to be used by the Photons framework.
@protocol PTUImageCell <NSObject>

/// View model to determine the properties displayed by this cell. Changing the view model will
/// first set all the relevant properties to \c nil followed by the latest value sent from each
/// signal of the \c viewModel. Errors on these signals are mapped to \c nil and all values are
/// explicitly delivered on the main thread. Current \c viewModel image signal will be queried and
/// used each time the cell view size changes.
- (void)setViewModel:(nullable id<PTUImageCellViewModel>)viewModel;

@end

/// A dynamic UICollectionView cell that alters its content in response to its current dimensions.
/// The cell displays a single \c PTUImageCellView object as its content view.
///
/// This cell is expected to be a base class of cell classes used in the Photons User Interface
/// framework. By inheriting from this class, cells are expected to add subviews various properties
/// such as \c highlightingView.
@interface PTUImageCell : UICollectionViewCell <PTUImageCell>

/// Container view to display when cell is highlighted or selected. The view size will be set to
/// cover the entire cell. Initially this view has no subviews.
///
/// When inheriting from this class highlighting view should be added as children of this view.
@property (readonly, nonatomic) UIView *highlightingView;

@end

NS_ASSUME_NONNULL_END
