// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIMenuItemsDataSource.h"

#import "CUIIconWithTitleCell.h"
#import "CUIMenuItemViewModel.h"
#import "CUISelectableMenuItemViewModel.h"
#import "CUITheme.h"

SpecBegin(CUIMenuItemsDataSource)

static NSURL * const kTestURL = [NSURL URLWithString:@"http://hello.world"];
static NSString * const kCellClassIdentifier = @"testCellClass";

__block CUIMenuItemsDataSource *menuItemsDataSource;
__block id collectionViewStrictMock;
__block NSArray<id<CUIMenuItemViewModel>> *itemViewModels;

beforeEach(^{
  NSArray<NSString *> *itemTitles = @[@"1", @"2", @"3"];
  itemViewModels = [[itemTitles rac_sequence]
     map:^id<CUIMenuItemViewModel>(NSString *itemTitle) {
       CUIMenuItemModel *itemModel =
           [[CUIMenuItemModel alloc] initWithLocalizedTitle:itemTitle iconURL:kTestURL key:@""];
       return [[CUISelectableMenuItemViewModel alloc] initWithMenuItemModel:itemModel];
  }].array;
  menuItemsDataSource =
      [[CUIMenuItemsDataSource alloc] initWithItemViewModels:itemViewModels
                                      reusableCellIdentifier:kCellClassIdentifier];
  collectionViewStrictMock = OCMStrictClassMock([UICollectionView class]);
});

it(@"should return section and item count of itemViewModels", ^{
  NSUInteger numberOfSections =
      [menuItemsDataSource numberOfSectionsInCollectionView:collectionViewStrictMock];
  expect(numberOfSections).to.equal(1);
  NSUInteger numberOfItemsInSection0 = [menuItemsDataSource collectionView:collectionViewStrictMock
                                                   numberOfItemsInSection:0];
  expect(numberOfItemsInSection0).to.equal(itemViewModels.count);
});

context(@"test returned cells", ^{
  __block CUIIconWithTitleCell *cell;

  beforeEach(^{
    LTMockClass([CUITheme class]);
    cell = [[CUIIconWithTitleCell alloc] init];
    OCMStub([collectionViewStrictMock
        dequeueReusableCellWithReuseIdentifier:kCellClassIdentifier
                                  forIndexPath:[OCMArg any]]).andReturn(cell);
  });

  it(@"should return cells with itemViewModels", ^{
    for (NSUInteger i = 0; i < itemViewModels.count; i++) {
      UICollectionViewCell *returnedCell =
          [menuItemsDataSource collectionView:collectionViewStrictMock
                       cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
      expect(returnedCell).to.equal(cell);
      expect(cell.viewModel).to.equal(itemViewModels[i]);
    }
  });

  it(@"should raise an exception for unavailable index path", ^{
    expect(^{
      [menuItemsDataSource collectionView:collectionViewStrictMock
                   cellForItemAtIndexPath:[NSIndexPath indexPathForItem:100 inSection:0]];
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      [menuItemsDataSource collectionView:collectionViewStrictMock
                   cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
