// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUDataSource.h"

#import "PTNFakeAssetManager.h"
#import "PTUChangeset.h"
#import "PTUImageCell.h"

SpecBegin(PTUDataSource)

__block PTUDataSource *dataSource;
__block RACSubject *dataSignal;
__block UICollectionView *collectionView;
__block id<PTUImageCellViewModelProvider> provider;
__block Class cellClass;

beforeEach(^{
  cellClass = [PTUImageCell class];
  collectionView = OCMClassMock([UICollectionView class]);
  provider = OCMProtocolMock(@protocol(PTUImageCellViewModelProvider));
  dataSignal = [RACSubject subject];
  dataSource = [[PTUDataSource alloc] initWithCollectionView:collectionView
                                                  dataSignal:dataSignal
                                       cellViewModelProvider:provider
                                                   cellClass:cellClass];
});

it(@"should start with empty data", ^{
  expect([dataSource objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]).to.beNil();
});

it(@"should register given cell class for reuse", ^{
  OCMVerify([collectionView registerClass:cellClass forCellWithReuseIdentifier:OCMOCK_ANY]);
});

it(@"should remain up to date with sent data", ^{
  PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1], @[@2, @3]]];
  [dataSignal sendNext:changeset];
  expect([dataSource objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]).to.equal(@1);
  expect([dataSource objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]]).to.equal(@2);
  expect([dataSource objectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:1]]).to.equal(@3);
  expect([dataSource objectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]]).to.beNil();
  expect([dataSource objectAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:1]]).to.beNil();
  expect([dataSource objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:2]]).to.beNil();
  expect([dataSource indexPathOfObject:(id<PTNDescriptor>)@1])
      .to.equal([NSIndexPath indexPathForItem:0 inSection:0]);
  expect([dataSource indexPathOfObject:(id<PTNDescriptor>)@2])
      .to.equal([NSIndexPath indexPathForItem:0 inSection:1]);
  expect([dataSource indexPathOfObject:(id<PTNDescriptor>)@4]).to.beNil();
});

context(@"updates", ^{
  it(@"should reload collection view on initial data", ^{
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1], @[@2, @3]]];
    [dataSignal sendNext:changeset];

    OCMVerify([collectionView reloadData]);
  });

  it(@"should perfom updates colleciton view when no incremental changes are avilable", ^{
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1], @[@2, @3]]];
    [dataSignal sendNext:changeset];
    OCMVerify([collectionView reloadData]);
    [dataSignal sendNext:changeset];
    OCMVerify([collectionView reloadData]);
  });


  it(@"should update according to incremental changes if available", ^{
    [[(OCMockObject *)collectionView reject] reloadData];

    NSArray *updated = @[[NSIndexPath indexPathForItem:0 inSection:0]];
    NSArray *inserted = @[[NSIndexPath indexPathForItem:1 inSection:0]];
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1]]
                                                             afterDataModel:@[@[@2, @3]]
                                                                    deleted:nil
                                                                   inserted:inserted
                                                                    updated:updated
                                                                      moved:nil];

    OCMStub([collectionView performBatchUpdates:[OCMArg invokeBlock]
                                     completion:([OCMArg invokeBlockWithArgs:@YES, nil])]);
    [dataSignal sendNext:changeset];
    OCMVerify([collectionView insertItemsAtIndexPaths:inserted]);
    OCMVerify([collectionView reloadItemsAtIndexPaths:updated]);
  });
});

SpecEnd
