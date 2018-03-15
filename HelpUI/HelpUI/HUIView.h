// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

NS_ASSUME_NONNULL_BEGIN

@protocol HUIItemsDataSource;

/// View for displaying help content in a collection view, as provided by data source. If the cells
/// provided by the data source conform to \c HUIAnimatableCell, they are being animated when they
/// intersect the animation area - the rectangle that is centered in the middle of this view and
/// it's width and height are half of the width and height of this view.
///
/// The collection view has "CollectionView" as its accessibility identifier.
@interface HUIView : UIView

/// Scrolls the view so that the section at the given \c sectionIndex becomes visible at the given
/// \c scrollPosition . Throws \c NSInvalidArgumentException if \c sectionIndex is out of bounds.
/// animates the scrolling if \c animated is \c YES.
- (void)showSection:(NSInteger)sectionIndex
   atScrollPosition:(UICollectionViewScrollPosition)scrollPosition
           animated:(BOOL)animated;

/// Invalidate current layout and force a re-layout of the view.
- (void)invalidateLayout;

/// Reloads all of the data for the help view.
- (void)reloadData;

/// Data source that provides the actual content to this view.
@property (strong, nonatomic, nullable) id<HUIItemsDataSource> dataSource;

@end

NS_ASSUME_NONNULL_END
