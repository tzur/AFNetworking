// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "HUICellsAnimator.h"

SpecBegin(HUICellsAnimator)

__block id<UICollectionViewDataSource> dataSource;
__block UICollectionViewFlowLayout *layout;
__block UICollectionView *collectionView;
__block HUICellsAnimator *animator;
__block HUIFakeCell *firstCell;
__block HUIFakeCell *secondCell;

beforeEach(^{
  NSArray *source = @[@[@"A"], @[@"B"]];
  dataSource = [[HUIFakeDataSource alloc] initWithArrayOfArrays:source];
  layout = [[UICollectionViewFlowLayout alloc] init];
  layout.itemSize = CGSizeMake(10,10);
  layout.headerReferenceSize = layout.itemSize;
  CGFloat collectionViewHeight = 2 * (layout.headerReferenceSize.height + layout.itemSize.height);
  CGRect collectionViewRect = CGRectMake(0, 0, layout.itemSize.width, collectionViewHeight);
  collectionView = [[UICollectionView alloc] initWithFrame:collectionViewRect
                                      collectionViewLayout:layout];
  collectionView.dataSource = dataSource;
  Class cellClass = [HUIFakeCell class];
  [collectionView registerClass:cellClass forCellWithReuseIdentifier:NSStringFromClass(cellClass)];
  animator = [[HUICellsAnimator alloc] init];
  LTAddViewToWindow(collectionView);
  [collectionView layoutIfNeeded];

  auto firstCellIndex = [NSIndexPath indexPathForRow:0 inSection:0];
  firstCell = (HUIFakeCell *)[collectionView cellForItemAtIndexPath:firstCellIndex];
  LTAssert(firstCell, @"the first cell of the collection view is not visible");

  auto secondCellIndex = [NSIndexPath indexPathForRow:0 inSection:1];
  secondCell = (HUIFakeCell *)[collectionView cellForItemAtIndexPath:secondCellIndex];
  LTAssert(secondCell, @"the second cell of the collection view is not visible");
});

it(@"should have correct default values", ^{
  expect(animator.animationArea).to.equal(CGRectZero);
});

it(@"should animate cell after adding it when animation area includes the cell", ^{
  expect(firstCell.animating).to.beFalsy();
  animator.animationArea = collectionView.bounds;

  [animator addCell:firstCell];

  expect(firstCell.animating).to.beTruthy();
});

it(@"should animate cell after adding it when animation area intersects the cell", ^{
  expect(firstCell.animating).to.beFalsy();
  CGFloat animationAreaHeight = layout.headerReferenceSize.height + layout.itemSize.height / 2;
  animator.animationArea = CGRectMake(collectionView.bounds.origin.x,
                                      collectionView.bounds.origin.y, layout.itemSize.width,
                                      animationAreaHeight);

  [animator addCell:firstCell];

  expect(firstCell.animating).to.beTruthy();
});

it(@"should not animate cell after adding it when animation area doesn't intersect the cell", ^{
  expect(firstCell.animating).to.beFalsy();
  animator.animationArea = CGRectMake(collectionView.bounds.origin.x,
                                      collectionView.bounds.origin.y,
                                      layout.headerReferenceSize.width,
                                      layout.headerReferenceSize.height);

  [animator addCell:firstCell];

  expect(firstCell.animating).to.beFalsy();
});

it(@"should stop animate cell after removing it", ^{
  expect(firstCell.animating).to.beFalsy();
  animator.animationArea = collectionView.bounds;
  [animator addCell:firstCell];
  expect(firstCell.animating).to.beTruthy();

  [animator removeCell:firstCell];

  expect(firstCell.animating).to.beFalsy();
});

it(@"should animate multiple cells after adding them when animation area includes the cells", ^{
  expect(firstCell.animating).to.beFalsy();
  expect(secondCell.animating).to.beFalsy();
  animator.animationArea = collectionView.bounds;

  [animator addCell:firstCell];
  [animator addCell:secondCell];

  expect(firstCell.animating).to.beTruthy();
  expect(secondCell.animating).to.beTruthy();
});

SpecEnd
