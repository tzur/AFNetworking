// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIMenuItemsDataSource.h"

#import "CUIMutableMenuItemView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIMenuItemsDataSource ()

/// Items view models, each view model controls an item in the menu.
@property (readonly, nonatomic) NSArray<id<CUIMenuItemViewModel>> *itemViewModels;

/// Identifier of a reusable cell conforming to the \c CUIMutableMenuItemView protocol from the
/// using \c UICollectionView.
@property (readonly, nonatomic) NSString *reusableCellIdentifier;

@end

@implementation CUIMenuItemsDataSource

- (instancetype)initWithItemViewModels:(NSArray<id<CUIMenuItemViewModel>> *)itemViewModels
                reusableCellIdentifier:(NSString *)reusableCellIdentifier {
  if (self = [super init]) {
    _itemViewModels = itemViewModels;
    _reusableCellIdentifier = reusableCellIdentifier;
  }
  return self;
}

#pragma mark -
#pragma mark UICollectionViewDataSource
#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView __unused *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView __unused *)view
     numberOfItemsInSection:(NSInteger __unused)section {
  return self.itemViewModels.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  UICollectionViewCell<CUIMutableMenuItemView> *cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:self.reusableCellIdentifier
                                                forIndexPath:indexPath];
  LTParameterAssert([cell conformsToProtocol:@protocol(CUIMutableMenuItemView)],
      @"%@ does not conform to the CUIMutableMenuItemView protocol", [cell class]);
  cell.viewModel = [self itemViewModelAtIndexPath:indexPath];
  return cell;
}

- (nullable id<CUIMenuItemViewModel>)itemViewModelAtIndexPath:(NSIndexPath *)indexPath {
  LTParameterAssert(indexPath.section == 0, @"Illegal section");
  LTParameterAssert (indexPath.item >= 0 && (NSUInteger)indexPath.item < self.itemViewModels.count,
      @"Illegal item index");
  return self.itemViewModels[indexPath.item];
}

@end

NS_ASSUME_NONNULL_END
