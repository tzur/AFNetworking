// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@protocol PTUChangesetProvider, PTUDataSource, PTUImageCellViewModelProvider;

/// Protocol for providers of \c PTUDataSource conforming objects.
@protocol PTUDataSourceProvider <NSObject>

/// Creates and returns a \c PTUDataSource conforming objects configured on \c collectionView.
- (id<PTUDataSource>)dataSourceForCollectionView:(UICollectionView *)collectionView;

@end

/// Implementation of \c PTUDataSourceProvider, providing \c PTUDataSource objects.
@interface PTUDataSourceProvider : NSObject <PTUDataSourceProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c changesetProvider, \c cellViewModelProvider and \c cellClass to be used when
/// creating \c PTUDataSource objects along with the given \c collectionView.
///
/// @note \c cellClass must be a subclass of \c UICollectionViewCell that conforms to the
/// \c PTUImageCell.
- (instancetype)initWithChangesetProvider:(id<PTUChangesetProvider>)changesetProvider
                    cellViewModelProvider:(id<PTUImageCellViewModelProvider>)cellViewModelProvider
                                cellClass:(Class)cellClass NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
