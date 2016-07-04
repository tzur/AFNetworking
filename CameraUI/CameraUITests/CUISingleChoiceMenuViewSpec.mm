// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUISingleChoiceMenuView.h"

#import "CUIIconWithTitleCell.h"
#import "CUIMutableMenuItemView.h"
#import "CUISharedTheme.h"
#import "CUISingleChoiceMenuViewModel.h"

@interface CUISingleChoiceMenuView (ForTesting) <UICollectionViewDelegate,
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

SpecBegin(CUISingleChoiceMenuView)

static const CGRect kFrame = CGRectMake(0, 0, 320, 100);
static const CGRect kFrame2 = CGRectMake(0, 0, 375, 80);
static const CGFloat kStartingItemPerRow = 5.5;
static NSURL * const kTestURL = [NSURL URLWithString:@"http://hello.world"];

__block CUISingleChoiceMenuView *singleChoiceMenuView;
__block CUISingleChoiceMenuViewModel *menuViewModel;
__block NSArray<CUIMenuItemModel *> *itemModels;

beforeEach(^{
  LTMockProtocol(@protocol(CUITheme));
  itemModels = @[
    [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"a" iconURL:kTestURL key:@""],
    [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"b" iconURL:kTestURL key:@""]
  ];
  menuViewModel = [[CUISingleChoiceMenuViewModel alloc] initWithItemModels:itemModels
                                                              selectedItem:itemModels[0]];
  singleChoiceMenuView =
      [[CUISingleChoiceMenuView alloc] initWithFrame:CGRectZero menuViewModel:menuViewModel
                                           cellClass:[CUIIconWithTitleCell class]];
  singleChoiceMenuView.frame = kFrame;
  [singleChoiceMenuView layoutIfNeeded];
});

context(@"items per row", ^{
  it(@"should start with 5.5 items per row", ^{
    expect(singleChoiceMenuView.itemsPerRow).to.equal(kStartingItemPerRow);
    CGSize itemSize = [singleChoiceMenuView collectionView:singleChoiceMenuView.collectionView
                                                    layout:[[UICollectionViewFlowLayout alloc] init]
                                    sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0
                                                                               inSection:0]];
    expect(itemSize.height).to.equal(kFrame.size.height);
    expect(itemSize.width).to.equal(std::floor(kFrame.size.width / kStartingItemPerRow));
  });

  it(@"should change size according to items per row", ^{
    CGFloat itemsPerRow = 4;
    singleChoiceMenuView.itemsPerRow = itemsPerRow;
    CGSize itemSize = [singleChoiceMenuView collectionView:singleChoiceMenuView.collectionView
                                                    layout:[[UICollectionViewFlowLayout alloc] init]
                                    sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0
                                                                               inSection:0]];
    expect(itemSize.height).to.equal(kFrame.size.height);
    expect(itemSize.width).to.equal(std::floor(kFrame.size.width / itemsPerRow));
  });

  it(@"should change size when frame changes", ^{
    singleChoiceMenuView.frame = kFrame2;
    [singleChoiceMenuView layoutIfNeeded];
    CGSize itemSize = [singleChoiceMenuView collectionView:singleChoiceMenuView.collectionView
                                                    layout:[[UICollectionViewFlowLayout alloc] init]
                                    sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0
                                                                               inSection:0]];
    expect(itemSize.height).to.equal(kFrame2.size.height);
    expect(itemSize.width).to.equal(std::floor(kFrame2.size.width / kStartingItemPerRow));
  });

  it(@"should raise an exception when itemsPerRow is set to zero", ^{
    expect(^{
      singleChoiceMenuView.itemsPerRow = 0;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when itemsPerRow is set to a negative number", ^{
    expect(^{
      singleChoiceMenuView.itemsPerRow = -1;
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"items cells", ^{
  it(@"should raise an exception when init with illegal cell", ^{
    __block CUISingleChoiceMenuView *newSingleChoiceMenuView;
    expect(^{
      newSingleChoiceMenuView =
          [[CUISingleChoiceMenuView alloc] initWithFrame:CGRectZero menuViewModel:menuViewModel
                                               cellClass:[UIView class]];
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      newSingleChoiceMenuView =
          [[CUISingleChoiceMenuView alloc] initWithFrame:CGRectZero menuViewModel:menuViewModel
                                               cellClass:[UICollectionViewCell class]];
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      newSingleChoiceMenuView =
          [[CUISingleChoiceMenuView alloc] initWithFrame:CGRectZero menuViewModel:menuViewModel
                                               cellClass:[CUIFakeMutableMenuItemView class]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should select item", ^{
    expect(menuViewModel.selectedItem).to.equal(itemModels[0]);
    NSIndexPath *newSelected = [NSIndexPath indexPathForItem:1 inSection:0];
    if ([singleChoiceMenuView collectionView:singleChoiceMenuView.collectionView
                 shouldSelectItemAtIndexPath:newSelected]) {
      [singleChoiceMenuView collectionView:singleChoiceMenuView.collectionView
                  didSelectItemAtIndexPath:newSelected];
    }
    expect(menuViewModel.selectedItem).to.equal(itemModels[1]);
  });

  it(@"should update number of items", ^{
    NSUInteger numberOfItems = [singleChoiceMenuView.collectionView numberOfItemsInSection:0];
    expect(numberOfItems).to.equal(itemModels.count);
    NSArray<CUIMenuItemModel *> *newItemModels = @[
        [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"1" iconURL:kTestURL key:@""],
        [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"2" iconURL:kTestURL key:@""],
        [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"3" iconURL:kTestURL key:@""]
    ];
    [menuViewModel setItemModels:newItemModels selectedItem:newItemModels[1]];
    numberOfItems = [singleChoiceMenuView.collectionView numberOfItemsInSection:0];
    expect(numberOfItems).to.equal(newItemModels.count);
  });
});

context(@"fake view model", ^{
  __block CUISingleChoiceMenuView *menuViewWithFakeViewModel;
  __block CUIFakeSingleChoiceMenuViewModel *fakeMenuViewModel;

  beforeEach(^{
    fakeMenuViewModel = [[CUIFakeSingleChoiceMenuViewModel alloc] initWithItemModels:itemModels
                                                                        selectedItem:itemModels[0]];
    menuViewWithFakeViewModel =
        [[CUISingleChoiceMenuView alloc] initWithFrame:CGRectZero menuViewModel:fakeMenuViewModel
                                             cellClass:[CUIIconWithTitleCell class]];
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
