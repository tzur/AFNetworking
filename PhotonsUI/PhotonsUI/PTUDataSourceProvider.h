// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAssetManager, PTUChangesetProvider, PTUDataSource, PTUImageCellViewModelProvider;

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
/// \c PTUImageCell protocol.
///
/// @note \c headerCellClass must be a subclass of \c UICollectionReusableView that conforms to the
/// \c PTUHeaderCell protocol.
- (instancetype)initWithChangesetProvider:(id<PTUChangesetProvider>)changesetProvider
                    cellViewModelProvider:(id<PTUImageCellViewModelProvider>)cellViewModelProvider
                                cellClass:(Class)cellClass headerCellClass:(Class)headerCellClass
    NS_DESIGNATED_INITIALIZER;

/// Initializes with a \c asset manager and \c url used to create and use the default
/// \c PTUAlbumChangesetProvider and \c PTUImageCellViewModelProvider and uses \c PTUImageCell as
/// \c cellClass.
///
/// @see -initWithChangesetProvider:cellViewModelProvider:cellClass:
- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager albumURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
