// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTRecordStorage.h"

#import <LTKit/NSArray+Functional.h>

#import "NSError+Intelligence.h"

NS_ASSUME_NONNULL_BEGIN

@interface INTRecordStorage ()

/// Used for enqueuing records.
@property (readonly, nonatomic) FMDatabaseQueue *databaseQueue;

/// Maximal disk space that can be used by the underlying database of \c databaseQueue.
@property (readonly, nonatomic) NSUInteger maxDiskSpace;

@end

@implementation INTRecordStorage

- (nullable instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)databaseQueue
                                  maxDiskSpace:(NSUInteger)maxDiskSpace {
  if (self = [super init]) {
    _databaseQueue = databaseQueue;
    _maxDiskSpace = maxDiskSpace;
    if (![self setupDatabase]) {
      return nil;
    }
  }
  return self;
}

- (BOOL)setupDatabase {
  __block BOOL success;
  [self.databaseQueue inDatabase:^(FMDatabase *database) {
    NSError *error;
    success = [database executeUpdate:[self createTableRecordsStatement] values:nil error:&error];

    if (error) {
      LogError(@"Failed to initialize records table %@", error);
      return;
    }
  }];

  return success;
}

- (NSString *)createTableRecordsStatement {
  return @"CREATE TABLE IF NOT EXISTS records ("
          "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "  record BLOB NOT NULL"
          ")";
}

- (BOOL)saveRecords:(NSArray<NSData *> *)records error:(NSError * __autoreleasing *)error {
  __block BOOL insertSuccess = YES;
  __block NSError *err;

  [self.databaseQueue inTransaction:^(FMDatabase *database, BOOL *rollback) {
    [records enumerateObjectsUsingBlock:^(NSData *record, NSUInteger, BOOL *stop) {
      NSError *internalError;
      insertSuccess = [database executeUpdate:@"INSERT INTO records (record) VALUES (?)"
                                       values:@[record] error:&internalError];
      if (!insertSuccess) {
        if (error) {
          err = [NSError int_errorWithCode:INTErrorCodeDataRecordSaveFailed
                                    record:record underlyingError:internalError];
          *stop = YES;
        }
      }
    }];

    if (!insertSuccess) {
      *rollback = YES;
      return;
    }

    NSError *internalError;
    insertSuccess = [self clearDiskSpaceIfNeededWithDatabase:database error:&internalError];

    if (!insertSuccess) {
      err = [NSError lt_errorWithCode:INTErrorCodeDataRecordSaveFailed
                      underlyingError:internalError];

      *rollback = YES;
    }
  }];

  if (err && error) {
    *error = err;
  }

  return insertSuccess;
}

- (BOOL)clearDiskSpaceIfNeededWithDatabase:(FMDatabase *)database
                                     error:(NSError * __autoreleasing *)error {
  auto totalRecordsSize = [self fetchTotalRecordSize:database error:error];
  if (!totalRecordsSize) {
    return NO;
  }

  if (totalRecordsSize.unsignedIntegerValue <= self.maxDiskSpace) {
    return YES;
  }

  auto recordsSizeOverhead = totalRecordsSize.unsignedIntegerValue - self.maxDiskSpace;
  auto _Nullable recordIDsForDeletion = [self fetchOldestRecordIDsUpToSize:recordsSizeOverhead
                                                                  database:database error:error];
  return [database executeUpdate:[self deleteRecordsStatementWithIDs:recordIDsForDeletion]
                          values:nil error:error];
}

- (nullable NSNumber *)fetchTotalRecordSize:(FMDatabase *)database
                                      error:(NSError * __autoreleasing *)error {
  auto _Nullable totalSizeResultSet =
      [database executeQuery:@"SELECT sum(length(record)) FROM records" values:nil error:error];
  if (!totalSizeResultSet) {
    return nil;
  }
  if (![totalSizeResultSet nextWithError:error]) {
    return nil;
  }

  auto totalRecordSize = [totalSizeResultSet unsignedLongLongIntForColumnIndex:0];
  [totalSizeResultSet close];

  return @(totalRecordSize);
}

- (nullable NSArray<NSNumber *> *)fetchOldestRecordIDsUpToSize:(NSUInteger)size
                                                      database:(FMDatabase *)database
                                                         error:(NSError * __autoreleasing *)error {
  auto _Nullable resultSet =
      [database executeQuery:@"SELECT id, length(record) FROM records ORDER BY id ASC" values:nil
                       error:error];
  if (!resultSet) {
    return nil;
  }

  NSUInteger comulativeRecordSize = 0;
  auto ids = [NSMutableArray<NSNumber *> array];
  NSError *internalError;

  while ([resultSet nextWithError:&internalError] && comulativeRecordSize < size) {
    [ids addObject:@([resultSet intForColumnIndex:0])];
    auto recordLength = [resultSet unsignedLongLongIntForColumnIndex:1];
    comulativeRecordSize += recordLength;
  }
  [resultSet close];

  if (internalError) {
    if (error) {
      *error = internalError;
    }
    return nil;
  }

  return [ids copy];
}

- (BOOL)deleteRecordsWithIDs:(NSArray<NSNumber *> *)ids error:(NSError * __autoreleasing *)error {
  __block BOOL success = YES;
  [self.databaseQueue inDatabase:^(FMDatabase *database) {
    success = [database executeUpdate:[self deleteRecordsStatementWithIDs:ids] values:nil
                                error:error];
  }];

  return success;
}

- (NSString *)deleteRecordsStatementWithIDs:(NSArray<NSNumber *> *)ids {
  return [NSString stringWithFormat:@"DELETE FROM records WHERE id IN (%@)",
          [ids componentsJoinedByString:@", "]];
}

- (nullable NSArray<RACTwoTuple<NSNumber *, NSData *> *> *)
    fetchOldestRecordsWithCount:(NSUInteger)count error:(NSError * __autoreleasing *)error {
  auto records = [NSMutableArray<RACTwoTuple<NSNumber *, NSData *> *> arrayWithCapacity:count];

  __block auto success = YES;
  __block NSError *internalError;
  [self.databaseQueue inDatabase:^(FMDatabase *database) {
    auto query = [NSString stringWithFormat:@"SELECT id, record FROM records ORDER BY id LIMIT %@",
                  @(count)];
    auto _Nullable results = [database executeQuery:query values:nil error:&internalError];

    if (!results) {
      success = NO;
      return;
    }

    while ([results nextWithError:&internalError]) {
      auto data = [results dataForColumnIndex:1];
      auto identifier = @([results unsignedLongLongIntForColumnIndex:0]);
      auto record = RACTuplePack(identifier, data);
      [records addObject:record];
    }
    [results close];

    if (internalError) {
      success = NO;
      return;
    }
  }];

  if (!success) {
    if (error) {
      *error = internalError;
    }

    return nil;
  }

  return records;
}

@end

NS_ASSUME_NONNULL_END
