// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTRecordStorage.h"

#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>
#import <LTKitTestUtils/LTTestUtils.h>

#import "NSError+Intelligence.h"

typedef void (^INTFMDatabaseBlock)(FMDatabase *database);
typedef void (^INTFMDatabaseTransactionBlock)(FMDatabase *database, BOOL *rollback);

@interface INTTestableDatabase : FMDatabase

/// Error to set for every insert operation. If set to an error, than any query beginning with
/// "insert" returns \c NO, and the error is set to this value, otherwise the operation is executed
/// normally.
@property (strong, nonatomic, nullable) NSError *insertError;

/// Error to set for every select operation. If set to an error, than any query beginning with
/// "select" returns \c NO, and the error is set to this value, otherwise the operation is executed
/// normally.
@property (strong, nonatomic, nullable) NSError *selectError;

/// Error to set for every delete operation. If set to an error, than any query beginning with
/// "delete" returns \c NO, and the error is set to this value, otherwise the operation is executed
/// normally.
@property (strong, nonatomic, nullable) NSError *deleteError;

/// Error to set for every delete operation. If set to an error, than any query beginning with
/// "delete" returns \c NO, and the error is set to this value, otherwise the operation is executed
/// normally.
@property (strong, nonatomic, nullable) NSError *createError;

@end

@implementation INTTestableDatabase

- (BOOL)executeUpdate:(NSString*)sql values:(NSArray * _Nullable)values
                error:(NSError * __autoreleasing *)error {
  if (self.insertError && [[sql lowercaseString] hasPrefix:@"insert"]) {
    if (error) {
      *error = self.insertError;
    }
    return NO;
  }

  if (self.deleteError && [[sql lowercaseString] hasPrefix:@"delete"]) {
    if (error) {
      *error = self.deleteError;
    }
    return NO;
  }

  if (self.createError && [[sql lowercaseString] hasPrefix:@"create"]) {
    if (error) {
      *error = self.createError;
    }
    return NO;
  }

  return [super executeUpdate:sql values:values error:error];
}

- (FMResultSet *)executeQuery:(NSString *)sql values:(NSArray *)values
                        error:(NSError *__autoreleasing *)error {
  if (self.selectError && [[sql lowercaseString] hasPrefix:@"select"]) {
    if (error) {
      *error = self.selectError;
    }
    return nil;
  }

  return [super executeQuery:sql values:values error:error];
}

@end

static NSData *INTRandomData(NSUInteger byteCount) {
  uint8_t bytes[byteCount];
  arc4random_buf(&bytes, byteCount);
  return [NSData dataWithBytes:bytes length:byteCount];
}

static NSArray<NSDictionary<NSString *, id> *>
    *INTDataFromTuples(NSArray<RACTwoTuple<NSNumber *, NSData *> *> *dataArray) {
  return [dataArray lt_map:^NSData *(RACTwoTuple<NSNumber *, NSData *> *tuple) {
    return tuple.second;
  }];
}

static FMDatabaseQueue *INTDatabaseQueueMock(INTTestableDatabase *database) {
  dispatch_queue_t serialQueue = dispatch_queue_create("INTDatabaseQueueMock",
                                                       DISPATCH_QUEUE_SERIAL);
  FMDatabaseQueue *databaseQueue = OCMClassMock(FMDatabaseQueue.class);
  OCMStub([databaseQueue inDatabase:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        dispatch_sync(serialQueue, ^{
          INTFMDatabaseBlock __unsafe_unretained databaseBlock;
          [invocation getArgument:&databaseBlock atIndex:2];
          databaseBlock(database);
        });
      });

  OCMStub([databaseQueue inTransaction:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        dispatch_sync(serialQueue, ^{
          INTFMDatabaseTransactionBlock databaseTranasactionBlock;
          [invocation getArgument:&databaseTranasactionBlock atIndex:2];
          BOOL rollback = NO;
          [database beginTransaction];
          databaseTranasactionBlock(database, &rollback);

          if (rollback) {
            [database rollback];
          } else {
            [database commit];
          }
        });
  });

  return databaseQueue;
}

SpecBegin(INTAloomaRecorder)

static const NSUInteger kMaxDiskSpace = 5 * 1024 * 1024;

__block NSString *databasePath;
__block INTRecordStorage *storage;
__block FMDatabaseQueue *databaseQueue;

beforeEach(^{
  databasePath = LTTemporaryPath(@"tmp.db");
  databaseQueue = [FMDatabaseQueue databaseQueueWithPath:databasePath];
  storage = [[INTRecordStorage alloc] initWithDatabaseQueue:databaseQueue
                                              maxDiskSpace:kMaxDiskSpace];
});

afterEach(^{
  [databaseQueue close];
});

it(@"should saved records and fetch serially", ^{
  auto expected = @[INTRandomData(20), INTRandomData(30)];
  [storage saveRecords:expected error:nil];
  auto records = [storage fetchOldestRecordsWithCount:10 error:nil];

  expect(INTDataFromTuples(records)).to.equal(expected);
});

it(@"should persist saved records", ^{
  auto expected = @[INTRandomData(20), INTRandomData(30)];
  [storage saveRecords:expected error:nil];
  [databaseQueue close];

  auto databaseQueue = [FMDatabaseQueue databaseQueueWithPath:databasePath];
  auto newStorage = [[INTRecordStorage alloc] initWithDatabaseQueue:databaseQueue
                                                        maxDiskSpace:kMaxDiskSpace];

  auto records = [newStorage fetchOldestRecordsWithCount:10 error:nil];
  expect(INTDataFromTuples(records)).to.equal(expected);
});

it(@"should fetch oldest records first", ^{
  auto expected = @[INTRandomData(20), INTRandomData(30)];
  [storage saveRecords:expected error:nil];
  [storage saveRecords:@[INTRandomData(20)] error:nil];

  auto records = [storage fetchOldestRecordsWithCount:2 error:nil];
  expect(INTDataFromTuples(records)).to.equal(expected);
});

it(@"should delete records", ^{
  auto expected = @[INTRandomData(20)];
  [storage saveRecords:@[INTRandomData(20), INTRandomData(30)] error:nil];
  [storage saveRecords:expected error:nil];
  auto records = [storage fetchOldestRecordsWithCount:2 error:nil];
  auto ids = [records lt_map:^NSNumber *(RACTwoTuple<NSNumber *, NSData *> *tuple) {
    return tuple.first;
  }];

  [storage deleteRecordsWithIDs:ids error:nil];
  records = [storage fetchOldestRecordsWithCount:10 error:nil];
  expect(INTDataFromTuples(records)).to.equal(expected);
});

it(@"should remove oldest records to uphold maximal disk space usage", ^{
  storage = [[INTRecordStorage alloc] initWithDatabaseQueue:databaseQueue maxDiskSpace:100];
  auto expected = @[
    INTRandomData(10),
    INTRandomData(22),
    INTRandomData(20),
    INTRandomData(19),
    INTRandomData(17),
    INTRandomData(7)
  ];
  [storage saveRecords:@[
    INTRandomData(20),
    INTRandomData(50),
  ] error:nil];
  [storage saveRecords:expected error:nil];

  auto records = [storage fetchOldestRecordsWithCount:10 error:nil];
  expect(INTDataFromTuples(records)).to.equal(expected);
});

context(@"database errors", ^{
  __block INTTestableDatabase *database;
  __block FMDatabaseQueue *databaseQueue;
  __block INTRecordStorage *storage;

  beforeEach(^{
    database = [INTTestableDatabase databaseWithPath:LTTemporaryPath(@"foo.db")];
    [database open];
    databaseQueue = INTDatabaseQueueMock(database);
    storage = [[INTRecordStorage alloc] initWithDatabaseQueue:databaseQueue
                                                 maxDiskSpace:kMaxDiskSpace];
  });

  afterEach(^{
    [database close];
  });

  it(@"should err if database errs on insert operation", ^{
    database.insertError = [NSError lt_errorWithCode:1337];
    NSError *error;
    auto result = [storage saveRecords:@[INTRandomData(20)] error:&error];

    expect(result).to.beFalsy();
    expect(error.code).to.equal(INTErrorCodeDataRecordSaveFailed);
    expect(error.lt_underlyingError).to.equal(database.insertError);

    auto records = [storage fetchOldestRecordsWithCount:10 error:nil];
    expect(records).to.haveCount(0);
  });

  it(@"should err if database errs on check of database size", ^{
    database.selectError = [NSError lt_errorWithCode:1337];
    NSError *error;
    auto result = [storage saveRecords:@[INTRandomData(20)] error:&error];

    expect(result).to.beFalsy();
    expect(error).to.equal([NSError lt_errorWithCode:INTErrorCodeDataRecordSaveFailed
                                     underlyingError:database.selectError]);

    database.selectError = nil;
    auto records = [storage fetchOldestRecordsWithCount:10 error:nil];
    expect(records).to.haveCount(0);
  });

  it(@"should err record deletion if database fails on deletion", ^{
    database.deleteError =[NSError lt_errorWithCode:1337];
    NSError *error;
    auto result = [storage deleteRecordsWithIDs:@[@1] error:&error];

    expect(result).to.beFalsy();
    expect(error).to.equal(database.deleteError);
  });

  it(@"should err fetch records if database fails on select", ^{
    database.selectError = [NSError lt_errorWithCode:1337];
    NSError *error;
    auto _Nullable records = [storage fetchOldestRecordsWithCount:10 error:&error];

    expect(records).to.beNil();
    expect(error).to.equal(database.selectError);
  });
});

SpecEnd
