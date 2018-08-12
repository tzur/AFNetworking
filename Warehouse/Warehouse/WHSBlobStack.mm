// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "WHSBlobStack.h"

#import <fmdb/FMDB.h>

NS_ASSUME_NONNULL_BEGIN

@interface WHSDatabaseBlobStack ()

/// Database backing the stack.
@property (readonly, nonatomic) FMDatabase *database;

@end

@implementation WHSDatabaseBlobStack

- (nullable instancetype)initWithDatabaseURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
  return [self initWithDatabase:[FMDatabase databaseWithURL:url] error:error];
}

- (nullable instancetype)initWithDatabase:(FMDatabase *)database
                                    error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    _database = database;
    self.database.maxBusyRetryTimeInterval = 0;
    self.database.shouldCacheStatements = YES;

    if (![_database open]) {
      if (error) {
        if (database.databaseURL) {
          *error = [NSError lt_errorWithCode:WHSErrorCodeWriteFailed url:nn(database.databaseURL)];
        } else {
          *error = [NSError lt_errorWithCode:WHSErrorCodeWriteFailed];
        }
      }
      return nil;
    }

    if (![self createTableIfNeededWithError:error]) {
      return nil;
    }
  }
  return self;
}

- (BOOL)createTableIfNeededWithError:(NSError *__autoreleasing *)error {
  NSError *localError;
  auto created = [self.database executeUpdate:@"CREATE TABLE IF NOT EXISTS blobs "
                  "(idx INTEGER NOT NULL, data BLOB NOT NULL, PRIMARY KEY (idx))"
                         withErrorAndBindings:&localError];
  if (!created) {
    if (error) {
      *error = [NSError lt_errorWithCode:WHSErrorCodeWriteFailed underlyingError:localError];
    }
  }

  return created;
}

- (BOOL)close {
  return [self.database close];
}

- (BOOL)pushBlob:(NSData *)blob error:(NSError *__autoreleasing *)error {
  NSError *localError;
  auto updated = [self.database executeUpdate:@"INSERT INTO blobs (idx, data) "
                  "SELECT COUNT(*), ? FROM blobs" withErrorAndBindings:&localError, blob];
  if (!updated) {
    if (error) {
      *error = [NSError lt_errorWithCode:WHSErrorCodeWriteFailed underlyingError:localError];
    }
  }

  return updated;
}

- (nullable NSData *)blobAtIndex:(NSUInteger)index error:(NSError *__autoreleasing *)error {
  return [self blobsInRange:NSMakeRange(index, 1) error:error][0];
}

- (nullable NSArray<NSData *> *)blobsInRange:(NSRange)range
                                       error:(NSError *__autoreleasing *)error {
  NSError *localError;
  auto _Nullable resultSet = [self.database
                              executeQuery:@"SELECT data from blobs WHERE idx >= ? AND idx < ?"
                              values:@[@(range.location), @(NSMaxRange(range))]
                              error:&localError];
  if (!resultSet) {
    if (error) {
      *error = [NSError lt_errorWithCode:WHSErrorCodeFetchFailed underlyingError:localError];
    }
    return nil;
  }

  auto blobs = [NSMutableArray<NSData *> array];
  while ([resultSet nextWithError:&localError]) {
    auto _Nullable blob = [resultSet dataForColumnIndex:0];
    if (!blob) {
      if (error) {
        *error = [NSError lt_errorWithCode:WHSErrorCodeFetchFailed
                               description:@"Failed fetching blob"];
      }
      return nil;
    }

    [blobs addObject:nn(blob)];
  }

  if (localError) {
    if (error) {
      *error = [NSError lt_errorWithCode:WHSErrorCodeFetchFailed underlyingError:localError];
    }
    return nil;
  }

  return blobs;
}

- (BOOL)popBlobsFromIndex:(NSUInteger)index error:(NSError *__autoreleasing *)error {
  NSError *localError;
  auto updated = [self.database executeUpdate:@"DELETE FROM blobs WHERE idx >= ?"
                         withErrorAndBindings:&localError, @(index)];
  if (!updated) {
    if (error) {
      *error = [NSError lt_errorWithCode:WHSErrorCodeDeleteFailed underlyingError:localError];
    }
  }

  return updated;
}

- (nullable NSNumber *)countWithError:(NSError *__autoreleasing *)error {
  NSError *localError;
  auto _Nullable resultSet = [self.database executeQuery:@"SELECT COUNT(*) FROM blobs" values:nil
                                                   error:&localError];
  if (!resultSet) {
    if (error) {
      *error = [NSError lt_errorWithCode:WHSErrorCodeFetchFailed underlyingError:localError];
    }
    return nil;
  }

  if (![resultSet nextWithError:&localError]) {
    if (error) {
      *error = [NSError lt_errorWithCode:WHSErrorCodeFetchFailed underlyingError:localError];
    }
    return nil;
  }

  return @([resultSet unsignedLongLongIntForColumnIndex:0]);
}

@end

NS_ASSUME_NONNULL_END
