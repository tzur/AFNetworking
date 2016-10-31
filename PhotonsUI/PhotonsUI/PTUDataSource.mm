// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUDataSource.h"

#import <LTKit/LTCGExtensions.h>
#import <LTKit/LTRandomAccessCollection.h>

#import "PTUChangeset.h"
#import "PTUChangesetMetadata.h"
#import "PTUChangesetMove.h"
#import "PTUChangesetProvider.h"
#import "PTUHeaderCell.h"
#import "PTUImageCell.h"
#import "PTUImageCellViewModelProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUDataSource () <UICollectionViewDataSource>

/// Collection view to keep up to date with \c changesetProvider.
@property (readonly, nonatomic) UICollectionView *collectionView;

/// Provider of signals used to determine the data displayed using this data source.
@property (readonly, nonatomic) id<PTUChangesetProvider> changesetProvider;

/// Factory class for cell view model objects.
@property (readonly, nonatomic) id<PTUImageCellViewModelProvider> cellViewModelProvider;

/// Class used for collection view cells.
@property (readonly, nonatomic) Class cellClass;

/// Class used for collection view headers.
@property (readonly, nonatomic) Class headerCellClass;

/// Subject sending a \c RACUnit every time the receiver's collection view is updated.
@property (readonly, nonatomic) RACSubject *didUpdateCollectionViewSubject;

/// Current data model.
@property (strong, nonatomic) PTUDataModel *dataModel;

/// Title associated with the data provided in this data source, or \c nil if no such title exists.
/// This property is KVO compliant.
@property (strong, nonatomic, nullable) NSString *title;

/// Titles of the sections of the data in this data source. If no title is available for a section,
/// \c sectionTitles will contain no value for section's index.
@property (strong, nonatomic) NSDictionary<NSNumber *, NSString *> *sectionTitles;

/// \c YES if the latest value sent by the data signal provided by \c changesetProvider indicated
/// the existance of at least one object. This property is KVO compliant.
@property (readwrite, nonatomic) BOOL hasData;

/// Error sent on data signal provided by \c changesetProvider or \c nil of no such error was sent.
/// This property is KVO compliant.
@property (strong, nonatomic, nullable) NSError *error;

@end

@implementation PTUDataSource

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                     changesetProvider:(id<PTUChangesetProvider>)changesetProvider
                 cellViewModelProvider:(id<PTUImageCellViewModelProvider>)cellViewModelProvider
                             cellClass:(Class)cellClass headerCellClass:(Class)headerCellClass {
  LTParameterAssert([cellClass isSubclassOfClass:[UICollectionViewCell class]] &&
                    [cellClass conformsToProtocol:@protocol(PTUImageCell)], @"Given cellClass is "
                    "not a subclass of UICollectionViewCell or does not conform to the "
                    "PTUImageCell protocol: %@", NSStringFromClass(cellClass));
  LTParameterAssert([headerCellClass isSubclassOfClass:[UICollectionReusableView class]] &&
                    [headerCellClass conformsToProtocol:@protocol(PTUHeaderCell)], @"Given "
                    "headerCellClass is not a subclass of UICollectionReusableView or does not "
                    "conform to the PTUHeaderCell protocol: %@",
                    NSStringFromClass(headerCellClass));
  if (self = [super init]) {
    _cellViewModelProvider = cellViewModelProvider;
    _changesetProvider = changesetProvider;
    _cellClass = cellClass;
    _headerCellClass = headerCellClass;
    
    self.dataModel = @[];
    self.sectionTitles = @{};
    _didUpdateCollectionViewSubject = [RACSubject subject];

    [self setupCollectionView:collectionView];
    [self bindMetadataSignal];
  }
  return self;
}

- (void)setupCollectionView:(UICollectionView *)collectionView {
  _collectionView = collectionView;
  self.collectionView.dataSource = self;
  [self.collectionView registerClass:self.cellClass
          forCellWithReuseIdentifier:NSStringFromClass(self.cellClass)];
  [self.collectionView registerClass:self.headerCellClass
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                 withReuseIdentifier:NSStringFromClass(self.headerCellClass)];
  [self bindCollectionViewToDataSignal:[self.changesetProvider fetchChangeset]];
}

- (void)bindCollectionViewToDataSignal:(RACSignal *)dataSignal {
  @weakify(self)
  [[[dataSignal
      takeUntil:self.rac_willDeallocSignal]
      deliverOnMainThread]
      subscribeNext:^(PTUChangeset *changeset) {
        @strongify(self)
        self.dataModel = changeset.afterDataModel;
        self.hasData = [self dataModelHasData];

        if (!changeset.hasIncrementalChanges) {
          [self.collectionView reloadData];
          [self.collectionView layoutIfNeeded];
          [self.didUpdateCollectionViewSubject sendNext:[RACUnit defaultUnit]];
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
        } completion:^(BOOL) {
          [self.didUpdateCollectionViewSubject sendNext:[RACUnit defaultUnit]];
        }];
      } error:^(NSError *error) {
        @strongify(self)
        self.error = error;
      }];
}

- (BOOL)dataModelHasData {
  for (id<LTRandomAccessCollection> collection in self.dataModel) {
    if (collection.count) {
      return YES;
    }
  }
  
  return NO;
}

- (void)bindMetadataSignal {
  @weakify(self)
  [[[[self.changesetProvider fetchChangesetMetadata]
      takeUntil:self.rac_willDeallocSignal]
      deliverOnMainThread]
      subscribeNext:^(PTUChangesetMetadata *metadata) {
        @strongify(self);
        self.title = metadata.title;
        self.sectionTitles = metadata.sectionTitles;
      } error:^(NSError *error) {
        @strongify(self);
        self.error = error;
      }];
}

- (RACSignal *)didUpdateCollectionView {
  return [self.didUpdateCollectionViewSubject takeUntil:self.rac_willDeallocSignal];
}

- (nullable id<PTNDescriptor>)descriptorAtIndexPath:(NSIndexPath *)index {
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

- (nullable NSIndexPath *)indexPathOfDescriptor:(id<PTNDescriptor>)descriptor {
  NSUInteger index;
  for (NSUInteger i = 0; i < self.dataModel.count; ++i) {
    index = [self.dataModel[i] indexOfObject:descriptor];
    if (index != NSNotFound) {
      return [NSIndexPath indexPathForItem:index inSection:i];
    }
  }
  return nil;
}

- (nullable NSString *)titleForSection:(NSInteger)section {
  return self.sectionTitles[@(section)];
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
  id<PTNDescriptor> descriptor = [self descriptorAtIndexPath:indexPath];

  UICollectionViewCell<PTUImageCell> *cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(self.cellClass)
                                                forIndexPath:indexPath];

  cell.viewModel = [self.cellViewModelProvider viewModelForDescriptor:descriptor];

  return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
  if (![kind isEqualToString:UICollectionElementKindSectionHeader]) {
    return [[UICollectionReusableView alloc] initWithFrame:CGRectZero];
  }
  
  NSString *title = self.sectionTitles[@(indexPath.section)];
  
  UICollectionReusableView<PTUHeaderCell> *headerCell =
      [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                         withReuseIdentifier:NSStringFromClass(self.headerCellClass)
                                                forIndexPath:indexPath];
  headerCell.title = title;
  
  return headerCell;
}

@end

NS_ASSUME_NONNULL_END
