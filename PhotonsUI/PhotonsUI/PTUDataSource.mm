// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUDataSource.h"

#import <LTKit/LTCGExtensions.h>
#import <LTKit/LTRandomAccessCollection.h>

#import "PTUChangeset.h"
#import "PTUChangesetMove.h"
#import "PTUChangesetProvider.h"
#import "PTUImageCell.h"
#import "PTUImageCellViewModelProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUDataSource () <UICollectionViewDataSource>

/// Collection view to keep up to date with \c changesetProvider.
@property (readonly, nonatomic) UICollectionView *collectionView;

/// Factory class for cell view model objects.
@property (readonly, nonatomic) id<PTUImageCellViewModelProvider> cellViewModelProvider;

/// Class used for collection view cells.
@property (readonly, nonatomic) Class cellClass;

/// Current data model.
@property (strong, nonatomic) PTUDataModel *dataModel;

@end

@implementation PTUDataSource

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                            dataSignal:(RACSignal *)dataSignal
                 cellViewModelProvider:(id<PTUImageCellViewModelProvider>)cellViewModelProvider
                             cellClass:(Class)cellClass {
  LTParameterAssert([cellClass isSubclassOfClass:[UICollectionViewCell class]] &&
                    [cellClass conformsToProtocol:@protocol(PTUImageCell)], @"Given cellClass is "
                    "not a subclass of UICollectionViewCell or does not conform to the "
                    "PTUImageCell protocol: %@", NSStringFromClass(cellClass));
  if (self = [super init]) {
    _cellViewModelProvider = cellViewModelProvider;
    _cellClass = cellClass;
    self.dataModel = @[];
    [self setupCollectionView:collectionView withDataSignal:dataSignal];
  }
  return self;
}

- (void)setupCollectionView:(UICollectionView *)collectionView
             withDataSignal:(RACSignal *)dataSignal {
  _collectionView = collectionView;
  self.collectionView.dataSource = self;
  [self.collectionView registerClass:self.cellClass
          forCellWithReuseIdentifier:NSStringFromClass(self.cellClass)];
  [self bindCollectionViewToDataSignal:dataSignal];
}

- (void)bindCollectionViewToDataSignal:(RACSignal *)dataSignal {
  @weakify(self)
  [[[dataSignal
      takeUntil:self.rac_willDeallocSignal]
      deliverOnMainThread]
      subscribeNext:^(PTUChangeset *changeset) {
        @strongify(self)
        self.dataModel = changeset.afterDataModel;

        if (!changeset.hasIncrementalChanges) {
          [self.collectionView reloadData];
          return;
        }

        // Deletions and insertions are performed as a single separate batch operation since they
        // validate internal consistency using \c afterDataModel which already includes both
        // operations.
        [self.collectionView performBatchUpdates:^{
          // 1.a. Remove items at the indexes specified by the \c deletedIndexes property.
          [self.collectionView deleteItemsAtIndexPaths:changeset.deletedIndexes];

          // 1.b. Insert items at the indexes specified by the \c insertedIndexes property.
          [self.collectionView insertItemsAtIndexPaths:changeset.insertedIndexes];
        } completion:nil];

        // Updates and moves indexes assume corresponding inserts and removes were already made and
        // therefore cannot be made within the same batch operation.
        [self.collectionView performBatchUpdates:^{
          // 2.a. Update items specified by the \c updatedIndexes property.
          [self.collectionView reloadItemsAtIndexPaths:changeset.updatedIndexes];

          // 2.b. Iterate over the \c moves array in order and handle items whose locations have
          //      changed.
          for (PTUChangesetMove *move in changeset.movedIndexes) {
            [self.collectionView moveItemAtIndexPath:move.fromIndex toIndexPath:move.toIndex];
          }
        } completion:nil];
      }];
}

- (nullable id<PTNDescriptor>)objectAtIndexPath:(NSIndexPath *)index {
  id<LTRandomAccessCollection> _Nullable items = [self objectsInSection:index.section];
  if (index.item < 0 || (NSUInteger)index.item >= items.count) {
    return nil;
  }
  return items[index.item];
}

- (nullable id<LTRandomAccessCollection>)objectsInSection:(NSInteger)section {
  if (section < 0 || (NSUInteger)section >= self.dataModel.count) {
    return nil;
  }

  return self.dataModel[section];
}

- (nullable NSIndexPath *)indexPathOfObject:(id<PTNDescriptor>)object {
  NSUInteger index;
  for (NSUInteger i = 0; i < self.dataModel.count; ++i) {
    index = [self.dataModel[i] indexOfObject:object];
    if (index != NSNotFound) {
      return [NSIndexPath indexPathForItem:index inSection:i];
    }
  }
  return nil;
}

#pragma mark -
#pragma mark UICollectionViewDataSource
#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView * __unused)collectionView {
  return self.dataModel.count;
}

- (NSInteger)collectionView:(UICollectionView * __unused)view
     numberOfItemsInSection:(NSInteger)section {
  return [self objectsInSection:section].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  id<PTNDescriptor> descriptor = [self objectAtIndexPath:indexPath];

  UICollectionViewCell<PTUImageCell> *cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(self.cellClass)
                                                forIndexPath:indexPath];

  CGSize cellSize = [collectionView layoutAttributesForItemAtIndexPath:indexPath].size;
  CGSize cellSizeInPixels = cellSize * cell.contentScaleFactor;
  cell.viewModel = [self.cellViewModelProvider viewModelWithDescriptor:descriptor
                                                              cellSize:cellSizeInPixels];

  return cell;
}

@end

NS_ASSUME_NONNULL_END
