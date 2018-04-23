// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUDataSourceProvider.h"

#import <Photons/PTNAssetManager.h>

#import "PTUChangesetProvider.h"
#import "PTUDataSource.h"
#import "PTUHeaderCell.h"
#import "PTUImageCell.h"

SpecBegin(PTUDataSourceProvider)

it(@"should correctly initialize with convenience initializer", ^{
  id<PTNAssetManager> assetManager = OCMProtocolMock(@protocol(PTNAssetManager));
  NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];
  PTUDataSourceProvider *provider = [[PTUDataSourceProvider alloc] initWithAssetManager:assetManager
                                                                               albumURL:url];

  expect(provider).toNot.beNil();
});

context(@"designated initializer", ^{
  __block PTUDataSourceProvider *provider;
  __block UICollectionView *collectionView;

  beforeEach(^{
    id<PTUChangesetProvider> changesetProvider = OCMProtocolMock(@protocol(PTUChangesetProvider));
    OCMStub([changesetProvider fetchChangeset]).andReturn([RACSignal empty]);
    id<PTUImageCellViewModelProvider> cellViewModelProvider =
        OCMProtocolMock(@protocol(PTUImageCellViewModelProvider));
    provider = [[PTUDataSourceProvider alloc] initWithChangesetProvider:changesetProvider
                                                  cellViewModelProvider:cellViewModelProvider
                                                              cellClass:[PTUImageCell class]
                                                        headerCellClass:[PTUHeaderCell class]];
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
});

SpecEnd
