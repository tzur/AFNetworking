// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class FMDatabase;

/// Holds a stack of blobs, allowing to pop blobs from the top of the stack, push blobs into it and
/// access blobs in constant time.
@protocol WHSBlobStack <NSObject>

/// Pushes the given \c blob to the top of the stack, and returns \c YES on success. On error, \c NO
/// is returned and \c error is popuilated with \c WHSErrorCodeWriteFailed.
///
/// Complexity: \c O(1).
- (BOOL)pushBlob:(NSData *)blob error:(NSError **)error;

/// Returns the blob at the given \c index, or \c nil and populates \c error with
/// \c WHSErrorCodeFetchFailed on failure. The index must not exceed the bounds of the stack.
///
/// Complexity: \c O(1).
- (nullable NSData *)blobAtIndex:(NSUInteger)index error:(NSError **)error;

/// Returns the blobs in the given range, as ordered in the stack, or \c nil and populates \c error
/// with \c WHSErrorCodeFetchFailed on failure. The range must not exceed the bounds of the stack.
///
/// Complexity: \c O(n) for range of length \c n.
- (nullable NSArray<NSData *> *)blobsInRange:(NSRange)range error:(NSError **)error;

/// Pops all the blobs from the given \c index to the end of the stack. Returns \c YES if
/// successfully removed the blobs, or \c NO and populates \c error with \c WHSErrorCodeWriteFailed
/// otherwise. The index must not exceed the bounds of the stack.
///
/// Complexity: \c O(m) where <tt>m = count - index</tt>.
- (BOOL)popBlobsFromIndex:(NSUInteger)index error:(NSError **)error;

/// Returns the number of blobs in the stack as a boxed \c NSUInteger, or \c nil and populates
/// \c error with \c WHSErrorCodeFetchFailed if fetching the number of objects failed.
///
/// Complexity: \c O(1).
- (nullable NSNumber *)countWithError:(NSError **)error;

@end

/// Blob stack backed by an SQLite database. In contrast to common knowledge, SQLite performs
/// better than the file system for small blobs (~10KB in size). Performance tests we ran on actual
/// iOS device with SQLite version 3.19.3 shows that reads of blobs at this size are about/ x9
/// faster, while writing are x3 faster than using the file system.
///
/// @see https://www.sqlite.org/fasterthanfs.html
@interface WHSDatabaseBlobStack : NSObject <WHSBlobStack>

/// Initializes a new stack backed with the database in the given \c url. If the \c url doesn't
/// point to an existing database, a new database will be created. \c url must be a path URL. If the
/// database cannot be created, \c nil will be returned and \c WHSErrorCodeWriteFailed error will be
/// set.
- (nullable instancetype)initWithDatabaseURL:(NSURL *)url error:(NSError **)error;

/// Initializes a new stack backed with \c database. If the stack cannot be created, \c nil will be
/// returned and \c WHSErrorCodeWriteFailed error will be set.
- (nullable instancetype)initWithDatabase:(FMDatabase *)database error:(NSError **)error
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Forcefully closes the database connection and returns \c YES if the database has been closed
/// successfully. The stack must not be used after calling this method.
///
/// @note the stack automatically closes the connection on deallocation. Use this only if you need
/// to ensure the underlying database is closed prior to file operations such as move or delete.
- (BOOL)close;

@end

NS_ASSUME_NONNULL_END
