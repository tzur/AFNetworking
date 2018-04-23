// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUDataSource.h"

#import <LTKit/LTCGExtensions.h>
#import <LTKit/LTRandomAccessCollection.h>
#import <LTKit/NSArray+Functional.h>

#import "PTUChangeset.h"
#import "PTUChangesetMetadata.h"
#import "PTUChangesetMove.h"
#import "PTUChangesetProvider.h"
#import "PTUHeaderCell.h"
#import "PTUImageCell.h"
#import "PTUImageCellViewModelProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUDataSource () <UICollectionViewDataSource> {
  /// Optimization used to flush the update queue when a reload update is received.
  std::atomic<unsigned int> _pendingReloads;
}

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
/// the existence of at least one object. This property is KVO compliant.
@property (readwrite, nonatomic) BOOL hasData;

/// Error sent on data signal provided by \c changesetProvider or \c nil of no such error was sent.
/// This property is KVO compliant.
@property (strong, nonatomic, nullable) NSError *error;

/// Queue used to process updates serially.
@property (readonly, nonatomic) dispatch_queue_t updateQueue;

/// Used to extend each update job to its whole execution, including completion block call.
@property (readonly, nonatomic) dispatch_semaphore_t updateQueueSemaphore;

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
    _updateQueue = dispatch_queue_create("com.lightricks.PhotonsUI.dataSource",
                                         DISPATCH_QUEUE_SERIAL);
    _updateQueueSemaphore = dispatch_semaphore_create(0);
    _pendingReloads = 0;

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
  [[dataSignal
      takeUntil:self.rac_willDeallocSignal]
      subscribeNext:^(PTUChangeset *changeset) {
        @strongify(self);
        if (!self) {
          return;
        }

        // Changes without incremental changes make all changes made before them obsolete, so the
        // \c pendingReloads counter is used to flush the queue as quickly as possible.
        if (!changeset.hasIncrementalChanges) {
          ++self->_pendingReloads;
        }

        /// Dispatching on a serial queue ensures we process updates serially, without ever blocking
        /// the main thread.
        dispatch_async(self.updateQueue, ^{
          @strongify(self);
          if (!self) {
            return;
          }

          // Applying incremental changes when a reload is pending is wasteful, so if a reload is
          // pending we try to clear the queue as quickly as possible.
          if (changeset.hasIncrementalChanges && self->_pendingReloads) {
            return;
          }

          dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if (!self) {
              return;
            }

            if (!changeset.hasIncrementalChanges) {
              self.dataModel = changeset.afterDataModel;
              self.hasData = [[self class] hasDataInDataModel:self.dataModel];
              [self.collectionView reloadData];
              [self.didUpdateCollectionViewSubject sendNext:[RACUnit defaultUnit]];
              --self->_pendingReloads;
              dispatch_semaphore_signal(self.updateQueueSemaphore);
              return;
            }

            [self.collectionView performBatchUpdates:^{
              self.dataModel = changeset.afterDataModel;
              self.hasData = [[self class] hasDataInDataModel:self.dataModel];
              [self performIncrementalUpdatesFromChangeset:changeset];
            } completion:^(BOOL) {
              [self.didUpdateCollectionViewSubject sendNext:[RACUnit defaultUnit]];
              dispatch_semaphore_signal(self.updateQueueSemaphore);
            }];
          });

          // A semaphore is used to make each queued job wait for its corresponding update's
          // asynchronous completion.
          dispatch_semaphore_wait(self.updateQueueSemaphore, DISPATCH_TIME_FOREVER);
        });
      } error:^(NSError *error) {
        @strongify(self)
        self.error = error;
      }];
}

/// In a changeset the indexes are relative to different states of the data as follows:
/// - deletion are relative to the original data.
/// - insertions are relative to the original data after deletions were made.
/// - updates are relative to the original data after deletions and insertions were made.
/// - moves' from-indexes are relative to the original data and to-indexes are relative to
///   the data after deletions, insertions and updates were made.
///
/// The data we set is after all changes were made, causing everything but deletions to have
/// wrong indexes. Performing batch updates treats deletions according to the original data
/// and inserts according to data after deletions made in that batch update, enabling correct
/// indexes for both deletions and insertions. We then map and moves and updates to deletions and
/// insertions and apply them all in a single batch update.
///
/// We can append indexes to the index path array in any order, as they are (most likely) ordered
/// by the collectionO view prior to insertion.
- (void)performIncrementalUpdatesFromChangeset:(PTUChangeset *)changeset {
  // Backtrack insertion offsets to get inserts from updates.
  NSArray<NSIndexPath *> *updateInserts = [self offsetIndexPaths:changeset.updatedIndexes ?: @[]
                                                    byIndexPaths:changeset.insertedIndexes ?: @[]
                                                         removed:NO];

  // Backtrack deletion offsets to get deletions from update inserts.
  NSArray<NSIndexPath *> *updateDeletions = [self offsetIndexPaths:updateInserts
                                                      byIndexPaths:changeset.deletedIndexes ?: @[]
                                                           removed:YES];

  // Move indexes are already correct and require no offset application.
  NSArray<NSIndexPath *> *moveFromIndexes = [(changeset.movedIndexes ?: @[])
      lt_map:^NSIndexPath *(PTUChangesetMove *move) {
        return move.fromIndex;
      }];
  NSArray<NSIndexPath *> *moveToIndexes = [(changeset.movedIndexes ?: @[])
      lt_map:^NSIndexPath *(PTUChangesetMove *move) {
        return move.toIndex;
      }];

  NSArray<NSIndexPath *> *deletions = [[(changeset.deletedIndexes ?: @[])
    arrayByAddingObjectsFromArray:updateDeletions]
    arrayByAddingObjectsFromArray:moveFromIndexes];
  NSArray<NSIndexPath *> *insertions = [[(changeset.insertedIndexes ?: @[])
    arrayByAddingObjectsFromArray:changeset.updatedIndexes ?: @[]]
    arrayByAddingObjectsFromArray:moveToIndexes];

  // Duplicates need to be removed since updates and moves can be sent in regard to the same
  // indexes.
  [self.collectionView deleteItemsAtIndexPaths:[self removeDuplicatesFromArray:deletions]];
  [self.collectionView insertItemsAtIndexPaths:[self removeDuplicatesFromArray:insertions]];
}

- (NSArray<NSIndexPath *> *)offsetIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
                                byIndexPaths:(NSArray<NSIndexPath *> *)byIndexPaths
                                     removed:(BOOL)removed {
  // Offsetting index paths must be iterated in order. Ascending when removing, and decending when
  // inserting.
  NSArray<NSIndexPath *> *sortedByIndexes = [self sortedIndexPaths:byIndexPaths ascending:removed];

  // Each shifting index applies an offset to multiple indexes, for example in the array [1, 2, 3]
  // inserting 4 between 1 and 2 to result in [1, 4, 2, 3] will potentially offset both 2 and 3.
  NSMutableArray<NSIndexPath *> *offsetIndexes = [indexPaths mutableCopy];
  for (NSIndexPath *shiftingIndex in sortedByIndexes) {
    for (NSUInteger i = 0; i < offsetIndexes.count; ++i) {
      NSIndexPath *index = offsetIndexes[i];
      if (shiftingIndex.section != index.section) {
        continue;
      }

      // When an index is removed, as oppose to inserted, it can affect indexes equal to it, for
      // example in the array [1, 2] turning into [2'] by removing 1 and updating 2, the original
      // position of 2' is affected by the removal of 1, although they share the index 0.
      if (shiftingIndex.item < index.item || (removed && shiftingIndex.item == index.item)) {
        NSInteger item = index.item + (removed ? 1 : -1);
        LTAssert(item >= 0, @"Given indexes %@ cannot be logically shifted by %@ indexes %@",
                 indexPaths, removed ? @"removing" : @"inserting", byIndexPaths);

        offsetIndexes[i] = [NSIndexPath indexPathForItem:item inSection:index.section];
      }
    }
  }
  return offsetIndexes;
}

- (NSArray<NSIndexPath *> *)sortedIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
                                   ascending:(BOOL)ascending {
  NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"item"
                                                                   ascending:ascending];
  return [indexPaths sortedArrayUsingDescriptors:@[sortDescriptor]];
}

- (NSArray *)removeDuplicatesFromArray:(NSArray *)array {
  return [NSSet setWithArray:array].rac_sequence.array;
}

+ (BOOL)hasDataInDataModel:(PTUDataModel *)dataModel {
  for (id<LTRandomAccessCollection> collection in dataModel) {
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
