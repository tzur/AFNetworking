// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUISingleChoiceMenuViewController.h"

#import "CUIIconWithTitleCell.h"
#import "CUITheme.h"

@interface CUISingleChoiceMenuViewController (ForTesting) <UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout>
@property (strong, nonatomic) UICollectionView *collectionView;
@end

@interface CUIFakeMutableMenuItemView : NSObject <CUIMutableMenuItemView>
@end

@implementation CUIFakeMutableMenuItemView
@synthesize viewModel = _viewModel;
@end

@interface CUIFakeSingleChoiceMenuViewModel : CUISingleChoiceMenuViewModel
@property (nonatomic) NSUInteger lastTappedIndex;
@end

@implementation CUIFakeSingleChoiceMenuViewModel
- (void)didTapItemAtIndex:(NSUInteger)itemIndex {
  self.lastTappedIndex = itemIndex;
}
@end

SpecBegin(CUISingleChoiceMenuViewController)

static const CGRect kFrame = CGRectMake(0, 0, 320, 100);
static const CGRect kFrame2 = CGRectMake(0, 0, 375, 120);
static const CGFloat kStartingItemPerRow = 5.5;
static NSURL * const kTestURL = [NSURL URLWithString:@"http://hello.world"];

__block CUISingleChoiceMenuViewController *singleChoiceMenuViewController;
__block CUISingleChoiceMenuViewModel *menuViewModel;
__block NSArray<CUIMenuItemModel *> *itemModels;

beforeEach(^{
  LTMockClass([CUITheme class]);
  itemModels = @[
    [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"a" iconURL:kTestURL key:@""],
    [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"b" iconURL:kTestURL key:@""]
  ];
  menuViewModel = [[CUISingleChoiceMenuViewModel alloc] initWithItemModels:itemModels
                                                              selectedItem:itemModels[0]];
  singleChoiceMenuViewController = [[CUISingleChoiceMenuViewController alloc]
      initWithMenuViewModel:menuViewModel cellClass:[CUIIconWithTitleCell class]];
  singleChoiceMenuViewController.view.frame = kFrame;
  [singleChoiceMenuViewController.view layoutIfNeeded];
});

context(@"items per row", ^{
  __block UICollectionView *collectionView;
  __block UICollectionViewLayout *layout;

  beforeEach(^{
    collectionView = singleChoiceMenuViewController.collectionView;
    layout = collectionView.collectionViewLayout;
  });

  it(@"should start with 5.5 items per row", ^{
    expect(singleChoiceMenuViewController.itemsPerRow).to.equal(kStartingItemPerRow);
    CGSize itemSize =
        [singleChoiceMenuViewController collectionView:collectionView
                                                layout:layout
                                sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0
                                                                           inSection:0]];
    expect(itemSize.height).to.equal(kFrame.size.height);
    expect(itemSize.width).to.equal(std::floor(kFrame.size.width / kStartingItemPerRow));
  });

  it(@"should change size according to items per row", ^{
    CGFloat itemsPerRow = 4;
    singleChoiceMenuViewController.itemsPerRow = itemsPerRow;
    CGSize itemSize =
        [singleChoiceMenuViewController collectionView:collectionView
                                                layout:layout
                                sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0
                                                                           inSection:0]];
    expect(itemSize.height).to.equal(kFrame.size.height);
    expect(itemSize.width).to.equal(std::floor(kFrame.size.width / itemsPerRow));
  });

  it(@"should change size when frame changes", ^{
    singleChoiceMenuViewController.view.frame = kFrame2;
    [singleChoiceMenuViewController.view layoutIfNeeded];
    CGSize itemSize =
        [singleChoiceMenuViewController collectionView:collectionView
                                                layout:layout
                                sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0
                                                                           inSection:0]];
    expect(itemSize.height).to.equal(kFrame2.size.height);
    expect(itemSize.width).to.equal(std::floor(kFrame2.size.width / kStartingItemPerRow));
  });

  it(@"should raise an exception when itemsPerRow is set to zero", ^{
    expect(^{
      singleChoiceMenuViewController.itemsPerRow = 0;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when itemsPerRow is set to a negative number", ^{
    expect(^{
      singleChoiceMenuViewController.itemsPerRow = -1;
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"items cells", ^{
  it(@"should raise an exception when init with illegal cell", ^{
    __block CUISingleChoiceMenuViewController *newSingleChoiceMenuView;
    expect(^{
      newSingleChoiceMenuView =
          [[CUISingleChoiceMenuViewController alloc] initWithMenuViewModel:menuViewModel
                                                                 cellClass:[UIView class]];
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      newSingleChoiceMenuView = [[CUISingleChoiceMenuViewController alloc]
          initWithMenuViewModel:menuViewModel cellClass:[UICollectionViewCell class]];
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      newSingleChoiceMenuView = [[CUISingleChoiceMenuViewController alloc]
          initWithMenuViewModel:menuViewModel cellClass:[CUIFakeMutableMenuItemView class]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should select item", ^{
    expect(menuViewModel.selectedItem).to.equal(itemModels[0]);
    NSIndexPath *newSelected = [NSIndexPath indexPathForItem:1 inSection:0];
    if ([singleChoiceMenuViewController collectionView:singleChoiceMenuViewController.collectionView
                 shouldSelectItemAtIndexPath:newSelected]) {
      [singleChoiceMenuViewController collectionView:singleChoiceMenuViewController.collectionView
                  didSelectItemAtIndexPath:newSelected];
    }
    expect(menuViewModel.selectedItem).to.equal(itemModels[1]);
  });

  it(@"should update number of items", ^{
    NSInteger numberOfItems =
        [singleChoiceMenuViewController.collectionView numberOfItemsInSection:0];
    expect(numberOfItems).to.equal(itemModels.count);
    NSArray<CUIMenuItemModel *> *newItemModels = @[
      [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"1" iconURL:kTestURL key:@""],
      [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"2" iconURL:kTestURL key:@""],
      [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"3" iconURL:kTestURL key:@""]
    ];
    [menuViewModel setItemModels:newItemModels selectedItem:newItemModels[1]];
    numberOfItems = [singleChoiceMenuViewController.collectionView numberOfItemsInSection:0];
    expect(numberOfItems).to.equal(newItemModels.count);
  });
});

context(@"fake view model", ^{
  __block CUISingleChoiceMenuViewController *menuViewWithFakeViewModel;
  __block CUIFakeSingleChoiceMenuViewModel *fakeMenuViewModel;

  beforeEach(^{
    fakeMenuViewModel = [[CUIFakeSingleChoiceMenuViewModel alloc] initWithItemModels:itemModels
                                                                        selectedItem:itemModels[0]];
    menuViewWithFakeViewModel = [[CUISingleChoiceMenuViewController alloc]
        initWithMenuViewModel:fakeMenuViewModel cellClass:[CUIIconWithTitleCell class]];
    [menuViewWithFakeViewModel.view layoutIfNeeded];
  });

  it(@"should tap index", ^{
    expect(fakeMenuViewModel.lastTappedIndex).to.equal(0);
    NSIndexPath *newSelected = [NSIndexPath indexPathForItem:1 inSection:0];
    if ([menuViewWithFakeViewModel collectionView:menuViewWithFakeViewModel.collectionView
                      shouldSelectItemAtIndexPath:newSelected]) {
      [menuViewWithFakeViewModel collectionView:menuViewWithFakeViewModel.collectionView
                       didSelectItemAtIndexPath:newSelected];
    }
    expect(fakeMenuViewModel.lastTappedIndex).to.equal(1);
  });
});

SpecEnd
