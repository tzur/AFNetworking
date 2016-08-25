// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUDataSourceProvider.h"

#import "PTUAlbumChangesetProvider.h"
#import "PTUDataSource.h"
#import "PTUHeaderCell.h"
#import "PTUImageCell.h"
#import "PTUImageCellViewModelProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUDataSourceProvider ()

/// Provider for \c PTUImageCellViewModel objects used when creating \c PTUDataSource objects.
@property (readonly, nonatomic) id<PTUImageCellViewModelProvider> cellViewModelProvider;

/// Class used for collection view cells used when creating \c PTUDataSource objects.
@property (readonly, nonatomic) Class cellClass;

/// Class used for collection view headers used when creating \c PTUDataSource objects.
@property (readonly, nonatomic) Class headerCellClass;

/// Provider of \c PTUChangeset objects used when creating \c PTUDataSource objects.
@property (readonly, nonatomic) id<PTUChangesetProvider> changesetProvider;

@end

@implementation PTUDataSourceProvider

- (instancetype)initWithChangesetProvider:(id<PTUChangesetProvider>)changesetProvider
                    cellViewModelProvider:(id<PTUImageCellViewModelProvider>)cellViewModelProvider
                                cellClass:(Class)cellClass headerCellClass:(Class)headerCellClass {
  if (self = [super init]) {
    _changesetProvider = changesetProvider;
    _cellViewModelProvider = cellViewModelProvider;
    _cellClass = cellClass;
    _headerCellClass = headerCellClass;
  }
  return self;
}

- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager albumURL:(NSURL *)url {
  PTUAlbumChangesetProvider *changesetProvider =
      [[PTUAlbumChangesetProvider alloc] initWithManager:assetManager albumURL:url];
  PTUImageCellViewModelProvider *viewModelProvider =
      [[PTUImageCellViewModelProvider alloc] initWithAssetManager:assetManager];
  
  return [self initWithChangesetProvider:changesetProvider cellViewModelProvider:viewModelProvider
                               cellClass:PTUImageCell.class headerCellClass:PTUHeaderCell.class];
}

#pragma mark -
#pragma mark PTUDataSourceProvider
#pragma mark -

- (id<PTUDataSource>)dataSourceForCollectionView:(UICollectionView *)collectionView {
  return [[PTUDataSource alloc] initWithCollectionView:collectionView
                                     changesetProvider:self.changesetProvider
                                 cellViewModelProvider:self.cellViewModelProvider
                                             cellClass:self.cellClass
                                       headerCellClass:self.headerCellClass];
}

@end

NS_ASSUME_NONNULL_END
