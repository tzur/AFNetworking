// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIView.h"

SpecBegin(HUIView)

__block HUIView *helpView;
__block id<HUIItemsDataSource> dataSource;
__block UICollectionView *collectionView;

beforeEach(^{
  helpView = [[HUIView alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
  dataSource = [[HUIFakeDataSource alloc] initWithArrayOfArrays:@[@[@"A", @"B"], @[@"C"]]];
  collectionView =
      (UICollectionView *)[helpView wf_viewForAccessibilityIdentifier:@"CollectionView"];
  helpView.dataSource = dataSource;
  [helpView layoutIfNeeded];
});

it(@"should create collection view with correct accessibility identifier", ^{
  expect([helpView wf_viewForAccessibilityIdentifier:@"CollectionView"])
      .to.beKindOf([UICollectionView class]);
});

context(@"dataSource", ^{
  __block id<HUIItemsDataSource> newDataSource;

  beforeEach(^{
    newDataSource = OCMProtocolMock(@protocol(HUIItemsDataSource));
  });

  it(@"should initialize collection view with the content of data source", ^{
    expect(collectionView.numberOfSections).to.equal(2);
    expect([collectionView numberOfItemsInSection:0]).to.equal(2);
    expect([collectionView numberOfItemsInSection:1]).to.equal(1);
  });

  it(@"should set the new data source", ^{
    helpView.dataSource = newDataSource;
    expect(helpView.dataSource).to.equal(newDataSource);
  });

  it(@"should update the collection view with content of a new data source", ^{
    auto dataSource =
        [[HUIFakeDataSource alloc] initWithArrayOfArrays:@[@[@"X"], @[@"Y"], @[@"Z"]]];
    helpView.dataSource = dataSource;
    expect(collectionView.numberOfSections).to.equal(3);
    expect([collectionView numberOfItemsInSection:0]).to.equal(1);
    expect([collectionView numberOfItemsInSection:1]).to.equal(1);
    expect([collectionView numberOfItemsInSection:2]).to.equal(1);
  });
});

it(@"should update the collection view if data source was changed and reloadData called", ^{
  [((HUIFakeDataSource *)(dataSource)).arrays removeObjectAtIndex:0];
  [helpView reloadData];

  expect(collectionView.numberOfSections).to.equal(1);
});

it(@"should initialize collection view layout", ^{
  expect(collectionView.collectionViewLayout).notTo.beNil();
});

it(@"should raise when showing section with invalid index", ^{
  expect(^{
    [helpView showSection:100 atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                 animated:NO];
  }).to.raise(NSInvalidArgumentException);
});

context(@"animation", ^{
  beforeEach(^{
    helpView = [[HUIView alloc] initWithFrame:CGRectMake(0, 0, 4, 4)];
    auto source = @[@[@"A"], @[@"B"], @[@"C"], @[@"D"], @[@"E"], @[@"F"]];
    dataSource = [[HUIFakeDataSource alloc] initWithArrayOfArrays:source];
    collectionView =
        (UICollectionView *)[helpView wf_viewForAccessibilityIdentifier:@"CollectionView"];
    helpView.dataSource = dataSource;
    [helpView layoutIfNeeded];
  });

  it(@"should animate cell that intersects the animation area", ^{
    auto cellIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    auto firstCell = (HUIFakeCell *)[collectionView cellForItemAtIndexPath:cellIndex];
    LTAssert(firstCell, @"first cell is not visible");

    expect(firstCell.animating).to.beTruthy();
  });

  it(@"should animate cell that intersects the animation area after scrolling", ^{
    [helpView showSection:4 atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                 animated:NO];
    [helpView layoutIfNeeded];
    auto cellIndex = [NSIndexPath indexPathForRow:0 inSection:4];
    auto fourthCell = (HUIFakeCell *)[collectionView cellForItemAtIndexPath:cellIndex];
    LTAssert(fourthCell, @"fourth cell is not visible");

    expect(fourthCell.animating).to.beTruthy();
  });

  it(@"should not animate cell that doesn't intersect the animation area", ^{
    helpView = [[HUIView alloc] initWithFrame:CGRectMake(0, 0, 100, 1000)];
    collectionView =
        (UICollectionView *)[helpView wf_viewForAccessibilityIdentifier:@"CollectionView"];
    helpView.dataSource = dataSource;
    [helpView layoutIfNeeded];
    auto cellIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    auto farCell = (HUIFakeCell *)[collectionView cellForItemAtIndexPath:cellIndex];
    LTAssert(farCell, @"far cell is not visible");

    expect(farCell.animating).to.beFalsy();
  });
});

SpecEnd
