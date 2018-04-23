// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUDataSource.h"

#import <LTKit/LTRandomAccessCollection.h>

#import "PTNFakeAssetManager.h"
#import "PTNTestUtils.h"
#import "PTUChangeset.h"
#import "PTUChangesetMetadata.h"
#import "PTUChangesetMove.h"
#import "PTUChangesetProvider.h"
#import "PTUHeaderCell.h"
#import "PTUImageCell.h"
#import "PTUImageCellViewModelProvider.h"
#import "PTUTestUtils.h"

SpecBegin(PTUDataSource)

__block PTUDataSource *dataSource;
__block RACSubject *dataSignal;
__block RACSubject *metadataSignal;
__block id collectionView;
__block id<UICollectionViewDataSource> collectionViewDataSource;
__block id<PTUChangesetProvider> changesetProvider;
__block id<PTUImageCellViewModelProvider> viewModelProvider;
__block Class cellClass;
__block Class headerCellClass;

beforeEach(^{
  cellClass = [PTUImageCell class];
  headerCellClass = [PTUHeaderCell class];
  collectionView = OCMClassMock([UICollectionView class]);
  OCMStub([collectionView setDataSource:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained id<UICollectionViewDataSource> dataSource;
    [invocation getArgument:&dataSource atIndex:2];
    collectionViewDataSource = dataSource;
  });
  dataSignal = [RACSubject subject];
  metadataSignal = [RACSubject subject];
  changesetProvider = OCMProtocolMock(@protocol(PTUChangesetProvider));
  OCMStub([changesetProvider fetchChangeset]).andReturn(dataSignal);
  OCMStub([changesetProvider fetchChangesetMetadata]).andReturn(metadataSignal);
  viewModelProvider = OCMProtocolMock(@protocol(PTUImageCellViewModelProvider));
  dataSource = [[PTUDataSource alloc] initWithCollectionView:collectionView
                                           changesetProvider:changesetProvider
                                       cellViewModelProvider:viewModelProvider
                                                   cellClass:cellClass
                                             headerCellClass:headerCellClass];
});

it(@"should set the given collection view's data source", ^{
  expect(collectionViewDataSource).to.conformTo(@protocol(UICollectionViewDataSource));
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

it(@"should register given cell classes for reuse", ^{
  OCMVerify([collectionView registerClass:cellClass forCellWithReuseIdentifier:OCMOCK_ANY]);
  OCMVerify([collectionView registerClass:headerCellClass forSupplementaryViewOfKind:OCMOCK_ANY
                      withReuseIdentifier:OCMOCK_ANY]);
});

it(@"should remain up to date with sent data", ^{
  PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1], @[@2, @3]]];
  [dataSignal sendNext:changeset];
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]])
      .will.equal(@1);
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]])
      .will.equal(@2);
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:1]])
      .will.equal(@3);
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]])
      .will.beNil();
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:1]])
      .will.beNil();
  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:2]])
      .will.beNil();
  expect([dataSource indexPathOfDescriptor:(id<PTNDescriptor>)@1])
      .will.equal([NSIndexPath indexPathForItem:0 inSection:0]);
  expect([dataSource indexPathOfDescriptor:(id<PTNDescriptor>)@2])
      .will.equal([NSIndexPath indexPathForItem:0 inSection:1]);
  expect([dataSource indexPathOfDescriptor:(id<PTNDescriptor>)@4]).will.beNil();
  expect(dataSource.hasData).will.beTruthy();
});

it(@"should remain up to date with title of sent metadata", ^{
  PTUChangesetMetadata *changesetMetadata = [[PTUChangesetMetadata alloc] initWithTitle:@"foo"
      sectionTitles:@{@1: @"bar", @2: @"baz"}];
  [metadataSignal sendNext:changesetMetadata];
  expect(dataSource.title).to.equal(@"foo");
  expect([dataSource titleForSection:1]).to.equal(@"bar");
  expect([dataSource titleForSection:2]).to.equal(@"baz");
  expect([dataSource titleForSection:0]).to.beNil();
  expect([dataSource titleForSection:3]).to.beNil();

  PTUChangesetMetadata *otherChangesetMetadata = [[PTUChangesetMetadata alloc] initWithTitle:@"bar"
      sectionTitles:@{@1: @"baz", @2: @"gaz"}];
  [metadataSignal sendNext:otherChangesetMetadata];
  expect(dataSource.title).to.equal(@"bar");
  expect([dataSource titleForSection:1]).to.equal(@"baz");
  expect([dataSource titleForSection:2]).to.equal(@"gaz");
  expect([dataSource titleForSection:0]).to.beNil();
  expect([dataSource titleForSection:3]).to.beNil();
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

it(@"should dequeue cells from collection view", ^{
  PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1]]];
  [dataSignal sendNext:changeset];

  expect([dataSource descriptorAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]])
      .will.equal(@1);

  id cell = [[cellClass alloc] initWithFrame:CGRectZero];
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
  OCMStub([collectionView dequeueReusableCellWithReuseIdentifier:OCMOCK_ANY
                                                    forIndexPath:indexPath]).andReturn(cell);

  expect([collectionViewDataSource collectionView:collectionView
                           cellForItemAtIndexPath:indexPath]).to.equal(cell);
});

it(@"should correctly configure cells", ^{
  id<PTNDescriptor> asset = PTNCreateDescriptor(@"foo");
  id<PTUImageCellViewModel> viewModel = OCMProtocolMock(@protocol(PTUImageCellViewModel));
  OCMStub([viewModelProvider viewModelForDescriptor:asset]).andReturn(viewModel);
  PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[asset]]];
  [dataSignal sendNext:changeset];
  expect(dataSource.hasData).will.beTruthy();

  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
  OCMStub([collectionView dequeueReusableCellWithReuseIdentifier:OCMOCK_ANY
      forIndexPath:indexPath]).andReturn([[cellClass alloc] initWithFrame:CGRectZero]);

  UICollectionViewCell<PTUImageCell> *cell =
      (UICollectionViewCell<PTUImageCell> *)[collectionViewDataSource collectionView:collectionView
      cellForItemAtIndexPath:indexPath];

  expect(cell).to.beKindOf(cellClass);
  expect(cell).to.conformTo(@protocol(PTUImageCell));
  expect(cell.viewModel).to.equal(viewModel);
});

it(@"should dequeue header cells from collection view", ^{
  PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[]]];
  [dataSignal sendNext:changeset];

  id headerCell = [[headerCellClass alloc] initWithFrame:CGRectZero];
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
  OCMStub([collectionView
      dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
      withReuseIdentifier:OCMOCK_ANY forIndexPath:indexPath]).andReturn(headerCell);

  expect([collectionViewDataSource collectionView:collectionView
      viewForSupplementaryElementOfKind:UICollectionElementKindSectionHeader
                                      atIndexPath:indexPath]).to.equal(headerCell);
});

it(@"should correctly configure headers", ^{
  PTUChangesetMetadata *changesetMetadata = [[PTUChangesetMetadata alloc] initWithTitle:nil
      sectionTitles:@{@0 : @"foo"}];
  [metadataSignal sendNext:changesetMetadata];
  PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[]]];
  [dataSignal sendNext:changeset];

  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
  OCMStub([collectionView
      dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
      withReuseIdentifier:OCMOCK_ANY forIndexPath:indexPath])
      .andReturn([[headerCellClass alloc] initWithFrame:CGRectZero]);

  UICollectionReusableView<PTUHeaderCell> *headerCell =
      (UICollectionReusableView<PTUHeaderCell> *)[collectionViewDataSource
      collectionView:collectionView
      viewForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];

  expect(headerCell).to.beKindOf(headerCellClass);
  expect(headerCell).to.conformTo(@protocol(PTUHeaderCell));
  expect(headerCell.title).to.equal(@"foo");
});

context(@"updates", ^{
  it(@"should reload collection view on initial data", ^{
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1], @[@2, @3]]];
    [dataSignal sendNext:changeset];

    OCMExpect([collectionView reloadData]);
    OCMVerifyAllWithDelay(collectionView, 1);
  });

  it(@"should reload collection view when no incremental changes are avilable", ^{
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1], @[@2, @3]]];
    [dataSignal sendNext:changeset];
    OCMExpect([collectionView reloadData]);
    [dataSignal sendNext:changeset];
    OCMExpect([collectionView reloadData]);
    OCMVerifyAllWithDelay(collectionView, 1);
  });

  it(@"should not reload data if incremental changes are given", ^{
    [[collectionView reject] reloadData];

    NSArray *deleted = @[[NSIndexPath indexPathForItem:0 inSection:0]];
    NSArray *inserted = @[[NSIndexPath indexPathForItem:1 inSection:0]];
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2]]
                                                             afterDataModel:@[@[@2, @3]]
                                                                    deleted:deleted
                                                                   inserted:inserted
                                                                    updated:nil
                                                                      moved:nil];
    [dataSignal sendNext:changeset];
    OCMVerifyAllWithDelay(collectionView, 1);
  });

  it(@"should update according to incremental changes if available", ^{
    NSArray *deleted = @[[NSIndexPath indexPathForItem:0 inSection:0]];
    NSArray *inserted = @[[NSIndexPath indexPathForItem:1 inSection:0]];
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2]]
                                                             afterDataModel:@[@[@2, @3]]
                                                                    deleted:deleted
                                                                   inserted:inserted
                                                                    updated:nil
                                                                      moved:nil];

    OCMStub([collectionView performBatchUpdates:[OCMArg invokeBlock]
                                     completion:([OCMArg invokeBlockWithArgs:@YES, nil])]);
    OCMExpect([collectionView deleteItemsAtIndexPaths:deleted]);
    OCMExpect([collectionView insertItemsAtIndexPaths:inserted]);
    [dataSignal sendNext:changeset];
    OCMVerifyAllWithDelay(collectionView, 1);
  });

  it(@"should not crash when updating incremental changes", ^{
    auto initialState = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1, @2, @3]]];
    auto deletedPaths = @[[NSIndexPath indexPathForItem:0 inSection:0]];
    auto updates = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3]]
                                                  afterDataModel:@[@[@2, @3]] deleted:deletedPaths
                                                        inserted:nil updated:nil moved:nil];
    auto layout = [[UICollectionViewLayout alloc] init];
    auto collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)
                                             collectionViewLayout:layout];
    auto dataSource = [[PTUDataSource alloc] initWithCollectionView:collectionView
                                                  changesetProvider:changesetProvider
                                              cellViewModelProvider:viewModelProvider
                                                          cellClass:cellClass
                                                    headerCellClass:headerCellClass];
    LLSignalTestRecorder *recorder = [dataSource.didUpdateCollectionView testRecorder];
    [dataSignal sendNext:initialState];
    [dataSignal sendNext:updates];

    expect(recorder).will.sendValues(@[[RACUnit defaultUnit], [RACUnit defaultUnit]]);
  });

  it(@"should map incremental changes to corresponding inserts and removes", ^{
    NSArray *deleted = @[[NSIndexPath indexPathForItem:1 inSection:0]];
    NSArray *inserted = @[
      [NSIndexPath indexPathForItem:0 inSection:0],
      [NSIndexPath indexPathForItem:1 inSection:0]
    ];
    NSArray *updated = @[[NSIndexPath indexPathForItem:2 inSection:0]];
    NSArray *moved = @[PTUCreateChangesetMove(2, 4, 0)];
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3, @4]]
                                                             afterDataModel:@[@[@5, @6, @7, @4, @3]]
                                                                    deleted:deleted
                                                                   inserted:inserted
                                                                    updated:updated
                                                                      moved:moved];

    OCMStub([collectionView performBatchUpdates:[OCMArg invokeBlock]
                                     completion:([OCMArg invokeBlockWithArgs:@YES, nil])]);
    OCMExpect(([collectionView
                deleteItemsAtIndexPaths:[OCMArg checkWithBlock:^BOOL(NSArray *removes) {
      return removes.count == 3 &&
          [removes containsObject:[NSIndexPath indexPathForItem:0 inSection:0]] &&
          [removes containsObject:[NSIndexPath indexPathForItem:1 inSection:0]] &&
          [removes containsObject:[NSIndexPath indexPathForItem:2 inSection:0]];
    }]]));
    OCMExpect(([collectionView
                insertItemsAtIndexPaths:[OCMArg checkWithBlock:^BOOL(NSArray *inserts) {
      return inserts.count == 4 &&
          [inserts containsObject:[NSIndexPath indexPathForItem:0 inSection:0]] &&
          [inserts containsObject:[NSIndexPath indexPathForItem:1 inSection:0]] &&
          [inserts containsObject:[NSIndexPath indexPathForItem:2 inSection:0]] &&
          [inserts containsObject:[NSIndexPath indexPathForItem:4 inSection:0]];
    }]]));
    [dataSignal sendNext:changeset];
    OCMVerifyAllWithDelay(collectionView, 1);
  });

  it(@"should take into account changes made during the index update", ^{
    NSArray *inserted = @[
      [NSIndexPath indexPathForItem:0 inSection:0],
      [NSIndexPath indexPathForItem:1 inSection:0]
    ];
    NSArray *updated = @[[NSIndexPath indexPathForItem:2 inSection:0]];
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@3]]
                                                             afterDataModel:@[@[@1, @2, @33]]
                                                                    deleted:nil
                                                                   inserted:inserted
                                                                    updated:updated
                                                                      moved:nil];

    OCMStub([collectionView performBatchUpdates:[OCMArg invokeBlock]
                                     completion:([OCMArg invokeBlockWithArgs:@YES, nil])]);
    OCMExpect(([collectionView
                deleteItemsAtIndexPaths:[OCMArg checkWithBlock:^BOOL(NSArray *removes) {
      return removes.count == 1 &&
          [removes containsObject:[NSIndexPath indexPathForItem:0 inSection:0]];
    }]]));
    OCMExpect(([collectionView
                insertItemsAtIndexPaths:[OCMArg checkWithBlock:^BOOL(NSArray *inserts) {
      return inserts.count == 3 &&
          [inserts containsObject:[NSIndexPath indexPathForItem:0 inSection:0]] &&
          [inserts containsObject:[NSIndexPath indexPathForItem:1 inSection:0]] &&
          [inserts containsObject:[NSIndexPath indexPathForItem:2 inSection:0]];
    }]]));

    [dataSignal sendNext:changeset];

    OCMVerifyAllWithDelay(collectionView, 1);
  });

  it(@"should process updates serially", ^{
    NSArray *inserts = @[[NSIndexPath indexPathForItem:1 inSection:0]];
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1]]
                                                             afterDataModel:@[@[@1, @2]]
                                                                    deleted:nil
                                                                   inserted:inserts
                                                                    updated:nil
                                                                      moved:nil];
    NSArray *otherInserts = @[[NSIndexPath indexPathForItem:2 inSection:0]];
    PTUChangeset *otherChangeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2]]
                                                                  afterDataModel:@[@[@1, @2, @3]]
                                                                         deleted:nil
                                                                        inserted:otherInserts
                                                                         updated:nil
                                                                           moved:nil];

    __block void(^completionBlock)(BOOL);
    OCMStub([collectionView performBatchUpdates:[OCMArg invokeBlock]
                                     completion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
      __unsafe_unretained void(^completion)(BOOL);
      [invocation getArgument:&completion atIndex:3];
      completionBlock = completion;
    });

    [collectionView setExpectationOrderMatters:YES];
    OCMExpect([collectionView insertItemsAtIndexPaths:inserts]);

    [dataSignal sendNext:changeset];
    [dataSignal sendNext:otherChangeset];

    expect([collectionViewDataSource collectionView:collectionView
                             numberOfItemsInSection:0]).will.equal(2);
    OCMVerifyAllWithDelay(collectionView, 1);

    OCMExpect([collectionView insertItemsAtIndexPaths:otherInserts]);
    completionBlock(YES);

    expect([collectionViewDataSource collectionView:collectionView
                             numberOfItemsInSection:0]).will.equal(3);
    OCMVerifyAllWithDelay(collectionView, 1);
  });

  it(@"should skip incremental updates if a changeset without incremental updates was sent", ^{
    NSArray *inserts = @[[NSIndexPath indexPathForItem:1 inSection:0]];
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1]]
                                                             afterDataModel:@[@[@1, @2]]
                                                                    deleted:nil
                                                                   inserted:inserts
                                                                    updated:nil
                                                                      moved:nil];
    NSArray *otherInserts = @[[NSIndexPath indexPathForItem:2 inSection:0]];
    PTUChangeset *otherChangeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2]]
                                                                  afterDataModel:@[@[@1, @2, @3]]
                                                                         deleted:nil
                                                                        inserted:otherInserts
                                                                         updated:nil
                                                                           moved:nil];
    PTUChangeset *reloadingChangeset = [[PTUChangeset alloc] initWithAfterDataModel:@[]];

    __block void(^completionBlock)(BOOL);
    OCMStub([collectionView performBatchUpdates:[OCMArg invokeBlock]
                                     completion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
      __unsafe_unretained void(^completion)(BOOL);
      [invocation getArgument:&completion atIndex:3];
      completionBlock = completion;
    });

    [dataSignal sendNext:changeset];
    expect([collectionViewDataSource collectionView:collectionView
                             numberOfItemsInSection:0]).will.equal(2);

    [[collectionView reject] insertItemsAtIndexPaths:otherInserts];
    OCMExpect([collectionView reloadData]);

    [dataSignal sendNext:otherChangeset];
    [dataSignal sendNext:reloadingChangeset];

    completionBlock(YES);

    OCMVerifyAllWithDelay(collectionView, 1);
    expect([collectionViewDataSource collectionView:collectionView
                             numberOfItemsInSection:0]).will.equal(0);
  });

  it(@"should notify on data change due to reload", ^{
    LLSignalTestRecorder *recorder = [dataSource.didUpdateCollectionView testRecorder];

    PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[], @[]]];
    OCMExpect([collectionView reloadData]);
    [dataSignal sendNext:changeset];
    OCMVerifyAllWithDelay(collectionView, 1);
    expect(recorder).will.sendValues(@[[RACUnit defaultUnit]]);

    OCMExpect([collectionView reloadData]);
    [dataSignal sendNext:changeset];
    OCMVerifyAllWithDelay(collectionView, 1);
    expect(recorder).will.sendValues(@[[RACUnit defaultUnit], [RACUnit defaultUnit]]);
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
    expect(recorder).will.sendValues(@[[RACUnit defaultUnit]]);

    [dataSignal sendNext:changeset];
    expect(recorder).will.sendValues(@[[RACUnit defaultUnit], [RACUnit defaultUnit]]);
  });

  it(@"should complete collection view update signal on dealloc", ^{
    __weak id<PTUDataSource> weakDataSource;
    LLSignalTestRecorder *recorder;

    UICollectionViewLayout *layout = OCMClassMock(UICollectionViewLayout.class);
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                                          collectionViewLayout:layout];
    auto dataSignal = [RACSubject subject];
    auto metadataSignal = [RACSubject subject];
    id<PTUChangesetProvider> changesetProvider = OCMProtocolMock(@protocol(PTUChangesetProvider));
    OCMStub([changesetProvider fetchChangeset]).andReturn(dataSignal);
    OCMStub([changesetProvider fetchChangesetMetadata]).andReturn(metadataSignal);

    @autoreleasepool {
      id<PTUDataSource> dataSource = [[PTUDataSource alloc] initWithCollectionView:collectionView
                                                                 changesetProvider:changesetProvider
                                                             cellViewModelProvider:viewModelProvider
                                                                         cellClass:cellClass
                                                                   headerCellClass:headerCellClass];
      weakDataSource = dataSource;
      recorder = [dataSource.didUpdateCollectionView testRecorder];
    }

    expect(weakDataSource).to.beNil();
    expect(recorder).to.complete();
  });

  it(@"should not crash when deallocating data source while there are pending changes", ^{
    static const NSUInteger kChangesetCount = 10;

    UICollectionViewLayout *layout = OCMClassMock(UICollectionViewLayout.class);
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                                          collectionViewLayout:layout];

    auto dataSignal = [RACSubject subject];
    auto metadataSignal = [RACSubject subject];
    id<PTUChangesetProvider> changesetProvider = OCMProtocolMock(@protocol(PTUChangesetProvider));
    OCMStub([changesetProvider fetchChangeset]).andReturn(dataSignal);
    OCMStub([changesetProvider fetchChangesetMetadata]).andReturn(metadataSignal);

    @autoreleasepool {
      id<PTUDataSource> __unused dataSource =
          [[PTUDataSource alloc] initWithCollectionView:collectionView
                                      changesetProvider:changesetProvider
                                  cellViewModelProvider:viewModelProvider
                                              cellClass:cellClass
                                        headerCellClass:headerCellClass];

      PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1], @[@2, @3]]];
      for (NSUInteger j = 0; j < kChangesetCount; ++j) {
        [dataSignal sendNext:changeset];
      }
    }

    // Note that no expectations are being made here. There's an implicit expectation for this code
    // not to crash. We cannot expect that the data source will deallocate since the changeset
    // processing operation is running on a background thread, which may hold the data source
    // strongly after the autoreleasepool scope in this thread ends, therefore leaving the data
    // source alive.
    //
    // However, since the test "should complete collection view update signal on dealloc" passes, we
    // can be sure that the data source will eventually deallocate.
  });
});

SpecEnd
