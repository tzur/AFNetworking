// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitFakeFetchResultChangeDetails.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitFakeFetchResultChangeDetails ()

/// Fetch result with the state of the fetched objects before this change (returns the fetch result
/// passed in to \c changeDetailsForFetchResult).
@property (strong, nonatomic) PHFetchResult *fakeFetchResultBeforeChanges;

/// Fetch result with the state of the fetched objects after this change.
@property (strong, nonatomic) PHFetchResult *fakeFetchResultAfterChanges;

/// \c YES if the changes to this fetch result are described by the removed/inserted/changed
/// details. \c NO indicates that the scope of changes were too large and UI clients should do a
/// full reload or that incremental changes could not be provided.
@property (nonatomic) BOOL fakeHasIncrementalChanges;

/// The indexes of the removed items, relative to the 'before' state of the fetch result. Returns
/// \c nil if hasIncrementalChanges is \c NO.
@property (strong, nonatomic) NSIndexSet *fakeRemovedIndexes;

/// The removed items, relative to the 'before' state of the fetch result. Returns \c nil if
/// \c hasIncrementalChanges is \c NO.
@property (strong, nonatomic) NSArray<PHObject *> *fakeRemovedObjects;

/// The indexes of the inserted items, relative to the 'before' state of the fetch result after
/// applying the removedIndexes.
@property (strong, nonatomic) NSIndexSet *fakeInsertedIndexes;

/// The inserted items, relative to the 'before' state of the fetch result after applying the
/// removedIndexes.
@property (strong, nonatomic) NSArray<PHObject *> *fakeInsertedObjects;

/// The indexes of the updated items, relative to the 'after' state of the fetch result.
@property (strong, nonatomic) NSIndexSet *fakeChangedIndexes;

/// The updated items, relative to the 'after' state of the fetch result.
@property (strong, nonatomic) NSArray<PHObject *> *fakeChangedObjects;

/// \c YES if there are moved items. Returns \c NO if hasIncrementalChanges is \c NO.
@property (nonatomic) BOOL fakeHasMoves;

@end

@implementation PTNPhotoKitFakeFetchResultChangeDetails

- (instancetype)initWithBeforeChanges:(PHFetchResult *)before afterChanges:(PHFetchResult *)after
                hasIncrementalChanges:(BOOL)hasIncrementalChanges
                       removedIndexes:(NSIndexSet *)removedIndexes
                       removedObjects:(NSArray<PHObject *> *)removedObjects
                      insertedIndexes:(NSIndexSet *)insertedIndexes
                      insertedObjects:(NSArray<PHObject *> *)insertedObjects
                       changedIndexes:(NSIndexSet *)changedIndexes
                       changedObjects:(NSArray<PHObject *> *)changedObjects
                             hasMoves:(BOOL)hasMoves {
  if (self = [super init]) {
    self.fakeFetchResultBeforeChanges = before;
    self.fakeFetchResultAfterChanges = after;
    self.fakeHasIncrementalChanges = hasIncrementalChanges;
    self.fakeRemovedIndexes = removedIndexes;
    self.fakeRemovedObjects = removedObjects;
    self.fakeInsertedIndexes = insertedIndexes;
    self.fakeInsertedObjects = insertedObjects;
    self.fakeChangedIndexes = changedIndexes;
    self.fakeChangedObjects = changedObjects;
    self.fakeHasMoves = hasMoves;
  }
  return self;
}

- (PHFetchResult *)fetchResultBeforeChanges {
  return self.fakeFetchResultBeforeChanges;
}

- (PHFetchResult *)fetchResultAfterChanges {
  return self.fakeFetchResultAfterChanges;
}

- (BOOL)hasIncrementalChanges {
  return self.hasIncrementalChanges;
}

- (BOOL)hasMoves {
  return self.fakeHasMoves;
}

- (nullable NSIndexSet *)removedIndexes {
  return self.fakeRemovedIndexes;
}

- (NSArray<PHObject *> *)removedObjects {
  return self.fakeRemovedObjects;
}

- (nullable NSIndexSet *)insertedIndexes {
  return self.fakeInsertedIndexes;
}

- (NSArray<PHObject *> *)insertedObjects {
  return self.fakeInsertedObjects;
}

- (nullable NSIndexSet *)changedIndexes {
  return self.fakeChangedIndexes;
}

- (NSArray<PHObject *> *)changedObjects {
  return self.fakeChangedObjects;
}

@end

NS_ASSUME_NONNULL_END
