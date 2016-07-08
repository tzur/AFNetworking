// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUDataSourceProvider.h"

#import "PTUChangesetProvider.h"
#import "PTUDataSource.h"
#import "PTUImageCell.h"

SpecBegin(PTUDataSourceProvider)

__block PTUDataSourceProvider *provider;
__block UICollectionView *collectionView;

beforeEach(^{
  id<PTUChangesetProvider> changesetProvider = OCMProtocolMock(@protocol(PTUChangesetProvider));
  id<PTUImageCellViewModelProvider> cellViewModelProvider =
      OCMProtocolMock(@protocol(PTUImageCellViewModelProvider));
  provider = [[PTUDataSourceProvider alloc] initWithChangesetProvider:changesetProvider
                                                cellViewModelProvider:cellViewModelProvider
                                                            cellClass:[PTUImageCell class]];

  collectionView = OCMClassMock([UICollectionView class]);
});

it(@"should return instances of PTUDataSource", ^{
  expect([provider dataSourceForCollectionView:collectionView])
      .to.beInstanceOf([PTUDataSource class]);
});

it(@"should return a new instance on every call", ^{
  expect([provider dataSourceForCollectionView:collectionView])
      .toNot.equal([provider dataSourceForCollectionView:collectionView]);
});

SpecEnd
