// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Fake \c PHFetchResultChangeDetails for easier integration testing.
/// This class is used in opossed to mocking since it is created dynamically during execution time
/// and the OCMock library gives inconsistant results in this case.
///
/// Possibly due to OCMock not being thread safe. See https://github.com/erikdoe/ocmock/issues/171.
@interface PTNPhotoKitFakeFetchResultChangeDetails : PHFetchResultChangeDetails

/// Initializer for fake \c PHFetchResultChangeDetails.
- (instancetype)initWithBeforeChanges:(PHFetchResult *)before
                         afterChanges:(PHFetchResult *)after
                hasIncrementalChanges:(BOOL)hasIncrementalChanges
                       removedIndexes:(NSIndexSet *)removedIndexes
                       removedObjects:(NSArray<PHObject *> *)removedObjects
                      insertedIndexes:(NSIndexSet *)insertedIndexes
                      insertedObjects:(NSArray<PHObject *> *)insertedObjects
                       changedIndexes:(NSIndexSet *)changedIndexes
                       changedObjects:(NSArray<PHObject *> *)changedObjects hasMoves:(BOOL)hasMoves;

@end

NS_ASSUME_NONNULL_END
