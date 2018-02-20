// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

@class FMDatabaseQueue;

/// Objects conforming to this protocol store records as data objects, and are able to delete and
/// retrieve.
@protocol INTRecordStorage <NSObject>

/// Saves \c records. Returns \c YES for success and \c NO otherwise. If the save fails, \c error is
/// set to an error with code \c INTErrorCodeJSONRecordSaveFailed.
- (BOOL)saveRecords:(NSArray<NSData *> *)records error:(NSError **)error;

/// Deletes records according to the given \c ids. If there is an error during this operation,
/// \c error is set.
- (BOOL)deleteRecordsWithIDs:(NSArray<NSNumber *> *)ids error:(NSError **)error;

/// Fetches oldest records in the storage up to \c count. Records are fetched by their order of
/// saving. Each record is returned alongside its unique identifier. If there is an error during the
/// fetch operation, \c error is set and a \c nil is returned.
- (nullable NSArray<RACTwoTuple<NSNumber *, NSData *> *> *)
    fetchOldestRecordsWithCount:(NSUInteger)count error:(NSError **)error;

/// Returns the current number of records stored. Returns 0 if there was an error while feching the
/// record count and \c error is set accordingly.
- (NSUInteger)recordCountWithError:(NSError **)error;

@end

/// Default implementation of \c INTRecordStorage. Uses an underlying \c FMDatabaseQueue in order to
/// store records. In order to uphold \c maxDiskSpace in bytes, oldest records are deleted, when
/// more than \c maxDiskSpace is used after a save operation.
@interface INTRecordStorage : NSObject <INTRecordStorage>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c databaseQueue for saving records and \c maxDiskSpace in bytes.
- (nullable instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)databaseQueue
                                  maxDiskSpace:(NSUInteger)maxDiskSpace NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
