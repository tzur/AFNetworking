// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "HUIFakeDataSource.h"

#import "HUIFakeCell.h"

NS_ASSUME_NONNULL_BEGIN

@implementation HUIFakeDataSource

- (instancetype)initWithArrayOfArrays:(NSArray *)arrays {
  if (self = [super init]) {
    self.arrays = [arrays mutableCopy];
  }
  return  self;
}

#pragma mark -
#pragma mark HUIDataSource
#pragma mark -

- (void)registerCellClassesWithCollectionView:(UICollectionView *)collectionView {
  Class cellClass = [HUIFakeCell class];
  [collectionView registerClass:cellClass forCellWithReuseIdentifier:NSStringFromClass(cellClass)];
}

- (CGFloat)cellHeightForIndexPath:(NSIndexPath __unused *)indexPath width:(CGFloat)cellWidth {
  return cellWidth;
}

#pragma mark -
#pragma mark UICollectionViewDataSource
#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView __unused *)collectionView {
  return self.arrays.count;
}

- (NSInteger)collectionView:(nonnull UICollectionView __unused *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  NSArray *sectionArray = self.arrays[section];
  return sectionArray.count;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView
                                   cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
  UICollectionViewCell *cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([HUIFakeCell class])
                                                forIndexPath:indexPath];
  [self prepareCellForDisplay:(HUIFakeCell *)cell atIndexPath:indexPath];
  return cell;
}

- (void)prepareCellForDisplay:(HUIFakeCell *)cell
                  atIndexPath:(NSIndexPath *)indexPath {
  cell.value = self.arrays[indexPath.section][indexPath.item];
}

@end

NS_ASSUME_NONNULL_END
