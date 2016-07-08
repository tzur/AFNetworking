// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUDataSourceProvider.h"

#import "PTUDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUDataSourceProvider ()

/// Provider for \c PTUImageCellViewModel objects used when creating \c PTUDataSource objects.
@property (readonly, nonatomic) id<PTUImageCellViewModelProvider> cellViewModelProvider;

/// Class used for collection view cells used when creating \c PTUDataSource objects.
@property (readonly, nonatomic) Class cellClass;

/// Provider of \c PTUChangeset objects used when creating \c PTUDataSource objects.
@property (readonly, nonatomic) id<PTUChangesetProvider> changesetProvider;

@end

@implementation PTUDataSourceProvider

- (instancetype)initWithChangesetProvider:(id<PTUChangesetProvider>)changesetProvider
                    cellViewModelProvider:(id<PTUImageCellViewModelProvider>)cellViewModelProvider
                                cellClass:(Class)cellClass  {
  if (self = [super init]) {
    _changesetProvider = changesetProvider;
    _cellViewModelProvider = cellViewModelProvider;
    _cellClass = cellClass;
  }
  return self;
}

#pragma mark -
#pragma mark PTUDataSourceProvider
#pragma mark -

- (id<PTUDataSource>)dataSourceForCollectionView:(UICollectionView *)collectionView {
  return [[PTUDataSource alloc] initWithCollectionView:collectionView
                                     changesetProvider:self.changesetProvider
                                 cellViewModelProvider:self.cellViewModelProvider
                                             cellClass:self.cellClass];
}

@end

NS_ASSUME_NONNULL_END
