// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUDataSource.h"

#import "PTNFakeAssetManager.h"
#import "PTUChangeset.h"
#import "PTUChangesetMetadata.h"
#import "PTUChangesetProvider.h"
#import "PTUImageCell.h"

SpecBegin(PTUDataSource)

__block PTUDataSource *dataSource;
__block RACSubject *dataSignal;
__block RACSubject *metadataSignal;
__block UICollectionView *collectionView;
__block id<PTUChangesetProvider> changesetProvider;
__block id<PTUImageCellViewModelProvider> viewModelProvider;
__block Class cellClass;

beforeEach(^{
  cellClass = [PTUImageCell class];
  collectionView = OCMClassMock([UICollectionView class]);
  dataSignal = [RACSubject subject];
  metadataSignal = [RACSubject subject];
  changesetProvider = OCMProtocolMock(@protocol(PTUChangesetProvider));
  OCMStub([changesetProvider fetchChangeset]).andReturn(dataSignal);
  OCMStub([changesetProvider fetchChangesetMetadata]).andReturn(metadataSignal);
  viewModelProvider = OCMProtocolMock(@protocol(PTUImageCellViewModelProvider));
  dataSource = [[PTUDataSource alloc] initWithCollectionView:collectionView
                                           changesetProvider:changesetProvider
                                       cellViewModelProvider:viewModelProvider
                                                   cellClass:cellClass];
});

it(@"should start with empty data", ^{
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]])
      .to.beNil();
  expect(dataSource.hasData).to.beFalsy();
  expect(dataSource.title).to.beNil();
});

it(@"should not update hasData with empty data", ^{
  [dataSignal sendNext:[[PTUChangeset alloc] initWithAfterDataModel:@[@[], @[]]]];
  expect(dataSource.hasData).to.beFalsy();
});

it(@"should register given cell class for reuse", ^{
  OCMVerify([collectionView registerClass:cellClass forCellWithReuseIdentifier:OCMOCK_ANY]);
});

it(@"should remain up to date with sent data", ^{
  PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1], @[@2, @3]]];
  [dataSignal sendNext:changeset];
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]])
      .to.equal(@1);
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]])
      .to.equal(@2);
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:1]])
      .to.equal(@3);
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]])
      .to.beNil();
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:1]])
      .to.beNil();
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:2]])
      .to.beNil();
  expect([dataSource indexPathOfDescriptor:(id<PTNDescriptor>)@1])
      .to.equal([NSIndexPath indexPathForItem:0 inSection:0]);
  expect([dataSource indexPathOfDescriptor:(id<PTNDescriptor>)@2])
      .to.equal([NSIndexPath indexPathForItem:0 inSection:1]);
  expect([dataSource indexPathOfDescriptor:(id<PTNDescriptor>)@4]).to.beNil();
  expect(dataSource.hasData).to.beTruthy();
});

it(@"should remain up to date with title of sent metadata", ^{
  PTUChangesetMetadata *changesetMetadata = [[PTUChangesetMetadata alloc] initWithTitle:@"foo"
                                                                          sectionTitles:@{}];
  [metadataSignal sendNext:changesetMetadata];
  expect(dataSource.title).to.equal(@"foo");
  
  PTUChangesetMetadata *otherChangesetMetadata = [[PTUChangesetMetadata alloc] initWithTitle:@"bar"
                                                                               sectionTitles:@{}];
  [metadataSignal sendNext:otherChangesetMetadata];
  expect(dataSource.title).to.equal(@"bar");
});

it(@"should properly update error and error flag on data fetch error", ^{
  expect(dataSource.error).to.beNil();

  NSError *error = [NSError lt_errorWithCode:1337];
  [dataSignal sendError:error];

  expect(dataSource.error).to.equal(error);
});

it(@"should properly update error and error flag on metadata fetch error", ^{
  expect(dataSource.error).to.beNil();

  NSError *error = [NSError lt_errorWithCode:1337];
  [metadataSignal sendError:error];

  expect(dataSource.error).to.equal(error);
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
  
  it(@"should notify on data change due to reload", ^{
    LLSignalTestRecorder *recorder = [dataSource.didUpdateCollectionView testRecorder];
    
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[], @[]]];
    [dataSignal sendNext:changeset];
    OCMVerify([collectionView reloadData]);
    expect(recorder).to.sendValues(@[[RACUnit defaultUnit]]);
    
    [dataSignal sendNext:changeset];
    OCMVerify([collectionView reloadData]);
    expect(recorder).to.sendValues(@[[RACUnit defaultUnit], [RACUnit defaultUnit]]);
  });

  it(@"should notify on data change due batch updates", ^{
    LLSignalTestRecorder *recorder = [dataSource.didUpdateCollectionView testRecorder];
    
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
    expect(recorder).to.sendValues(@[[RACUnit defaultUnit]]);
    
    [dataSignal sendNext:changeset];
    expect(recorder).to.sendValues(@[[RACUnit defaultUnit], [RACUnit defaultUnit]]);
  });
  
  it(@"should complete collection view update signal on dealloc", ^{
    __weak id<PTUDataSource> weakDataSource;
    __block LLSignalTestRecorder *recorder;
    
    @autoreleasepool {
      UICollectionViewLayout *layout = OCMClassMock(UICollectionViewLayout.class);
      UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                                            collectionViewLayout:layout];
      id<PTUDataSource> dataSource = [[PTUDataSource alloc] initWithCollectionView:collectionView
                                                                 changesetProvider:changesetProvider
                                                             cellViewModelProvider:viewModelProvider
                                                                         cellClass:cellClass];
      weakDataSource = dataSource;
      recorder = [dataSource.didUpdateCollectionView testRecorder];
    }
    
    expect(weakDataSource).to.beNil();
    expect(recorder).to.complete();
  });
});

SpecEnd
