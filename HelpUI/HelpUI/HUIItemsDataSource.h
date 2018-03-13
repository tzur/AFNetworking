// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Data source for a collection view of help items.
@protocol HUIItemsDataSource <UICollectionViewDataSource>

/// Registers the cell classes that this data source can provide with the given \c collectionView.
- (void) registerCellClassesWithCollectionView:(UICollectionView *)collectionView;

/// Returns the wanted height of the cell in the given \c indexPath for the given \c cellWidth.
- (CGFloat)cellHeightForIndexPath:(NSIndexPath *)indexPath width:(CGFloat)cellWidth;

@end

NS_ASSUME_NONNULL_END
