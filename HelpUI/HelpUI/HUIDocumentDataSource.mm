// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIDocumentDataSource.h"

#import "HUIDocument.h"
#import "HUIImageCell.h"
#import "HUIItem.h"
#import "HUISection.h"
#import "HUISlideshowCell.h"
#import "HUIVideoCell.h"

NS_ASSUME_NONNULL_BEGIN

@implementation HUIDocumentDataSource

// Mapping between a subtype of \c HUIItem to the subclass of \c HUIResourceCell that is needed
// for presenting the \c HUIItem in the collection view.
static NSDictionary * const kHelpItemClassToCellClass = @{
  [HUIImageItem class]: [HUIImageCell class],
  [HUIVideoItem class]: [HUIVideoCell class],
  [HUISlideshowItem class]: [HUISlideshowCell class]
};

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithHelpDocument:(nullable HUIDocument *)helpDocument {
  if (self = [super init]) {
    _helpDocument = helpDocument;
  }
  return self;
}

#pragma mark -
#pragma mark UICollectionViewDataSource
#pragma mark -

- (NSInteger)collectionView:(UICollectionView __unused *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  return [[self.helpDocument.sections[section] items] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView __unused *)collectionView {
  return [self.helpDocument.sections count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  auto cellClass = [self cellClassForIndexPath:indexPath];
  auto cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(cellClass)
                                                        forIndexPath:indexPath];
  [self prepareCellForDisplay:cell atIndexPath:indexPath];
  return cell;
}

- (Class)cellClassForIndexPath:(NSIndexPath *)indexPath {
  return kHelpItemClassToCellClass[[[self helpItemAtIndexPath:indexPath] class]];
}

- (nullable __kindof HUIItem *)helpItemAtIndexPath:(NSIndexPath *)indexPath {
  return [self.helpDocument.sections[indexPath.section] items][indexPath.item];
}

- (void)prepareCellForDisplay:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  LTAssert([cell respondsToSelector:@selector(setItem:)], @"Cell %@ does not have item property",
           [cell class]);
  [cell setItem:[self helpItemAtIndexPath:indexPath]];
}

#pragma mark -
#pragma mark HUIItemsDataSource
#pragma mark -

- (void)registerCellClassesWithCollectionView:(UICollectionView *)collectionView {
  for (Class cellClass in kHelpItemClassToCellClass.allValues) {
    [collectionView registerClass:cellClass
       forCellWithReuseIdentifier:NSStringFromClass(cellClass)];
  }
}

- (CGFloat)cellHeightForIndexPath:(NSIndexPath *)indexPath width:(CGFloat)cellWidth {
  auto helpItem = [self helpItemAtIndexPath:indexPath];
  return [HUIResourceCell cellHeightForTitle:helpItem.title body:helpItem.body
                                     iconURL:helpItem.iconURL width:cellWidth];
}

@end

NS_ASSUME_NONNULL_END
