// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "WHSBlobStack.h"

#import "WHSFakeDatabase.h"

SpecBegin(WHSDatabaseBlobStack)

__block NSArray<NSData *> *blobs;

beforeEach(^{
  blobs = @[
    nn([@"a" dataUsingEncoding:NSUTF8StringEncoding]),
    nn([@"b" dataUsingEncoding:NSUTF8StringEncoding]),
    nn([@"c" dataUsingEncoding:NSUTF8StringEncoding]),
    nn([@"d" dataUsingEncoding:NSUTF8StringEncoding])
  ];
});

context(@"integration tests", ^{
  __block NSURL *url;
  __block WHSDatabaseBlobStack *stack;

  beforeEach(^{
    url = [NSURL fileURLWithPath:LTTemporaryPath(@"test.db")];

    stack = [[WHSDatabaseBlobStack alloc] initWithDatabaseURL:url error:nil];

    [stack pushBlob:blobs[0] error:nil];
    [stack pushBlob:blobs[1] error:nil];
    [stack pushBlob:blobs[2] error:nil];
    [stack pushBlob:blobs[3] error:nil];
  });

  afterEach(^{
    // This is required for SQLite to avoid printing errors about the database being deleted while
    // open.
    [stack close];

    stack = nil;
  });

  it(@"should retrieve blob at index", ^{
    expect([stack blobAtIndex:0 error:nil]).to.equal(blobs[0]);
    expect([stack blobAtIndex:1 error:nil]).to.equal(blobs[1]);
    expect([stack blobAtIndex:2 error:nil]).to.equal(blobs[2]);
    expect([stack blobAtIndex:3 error:nil]).to.equal(blobs[3]);
  });

  it(@"should pop blobs from index", ^{
    [stack popBlobsFromIndex:2 error:nil];

    expect([stack countWithError:nil]).to.equal(@2);
    expect([stack blobsInRange:NSMakeRange(0, 2) error:nil]).to.equal(@[blobs[0], blobs[1]]);
  });

  it(@"should retrieve blobs in range", ^{
    expect([stack blobsInRange:NSMakeRange(0, 4) error:nil]).to.equal(blobs);
    expect([stack blobsInRange:NSMakeRange(1, 2) error:nil]).to.equal(@[blobs[1], blobs[2]]);
    expect([stack blobsInRange:NSMakeRange(0, 1) error:nil]).to.equal(@[blobs[0]]);
  });

  it(@"should return correct count", ^{
    expect([stack countWithError:nil]).to.equal(@4);
  });

  it(@"should fail when trying to open database at a directory that doesn't exist", ^{
    auto url = [NSURL fileURLWithPath:@"/foo/bar"];

    NSError *error;
    auto _Nullable collection = [[WHSDatabaseBlobStack alloc] initWithDatabaseURL:url error:&error];

    expect(collection).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeWriteFailed);
  });

  it(@"should persist data", ^{
    [stack close];

    auto sameStack = [[WHSDatabaseBlobStack alloc] initWithDatabaseURL:url error:nil];

    expect([sameStack blobAtIndex:0 error:nil]).to.equal(blobs[0]);
    expect([sameStack blobAtIndex:1 error:nil]).to.equal(blobs[1]);
    expect([sameStack blobAtIndex:2 error:nil]).to.equal(blobs[2]);
    expect([sameStack blobAtIndex:3 error:nil]).to.equal(blobs[3]);
  });

  it(@"should report open upon successful initialization", ^{
    expect([stack isOpen]).to.beTruthy();
  });

  it(@"should report closed after closing", ^{
    [stack close];
    expect([stack isOpen]).to.beFalsy();
  });
});

context(@"database failure", ^{
  __block WHSFakeDatabase *database;

  beforeEach(^{
    auto url = [NSURL fileURLWithPath:LTTemporaryPath(@"test.db")];

    database = [[WHSFakeDatabase alloc] initWithURL:url];
  });

  afterEach(^{
    database = nil;
  });

  it(@"should fail initialization if table cannot be created", ^{
    database.updateError = [NSError lt_errorWithCode:1337];

    NSError *error;
    auto _Nullable stack = [[WHSDatabaseBlobStack alloc] initWithDatabase:database error:&error];

    expect(stack).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeWriteFailed);
  });

  it(@"should indicate failure when pushing blobs fails", ^{
    auto _Nullable stack = [[WHSDatabaseBlobStack alloc] initWithDatabase:database error:nil];

    database.updateError = [NSError lt_errorWithCode:1337];

    NSError *error;
    BOOL pushed = [stack pushBlob:blobs[0] error:&error];

    expect(pushed).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeWriteFailed);
  });

  it(@"should indicate failure when popping blobs fails", ^{
    auto _Nullable stack = [[WHSDatabaseBlobStack alloc] initWithDatabase:database error:nil];

    [stack pushBlob:blobs[0] error:nil];

    database.updateError = [NSError lt_errorWithCode:1337];

    NSError *error;
    BOOL popped = [stack popBlobsFromIndex:0 error:&error];

    expect(popped).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeDeleteFailed);
  });

  it(@"should indicate failure when fetching blob at index fails", ^{
    auto _Nullable stack = [[WHSDatabaseBlobStack alloc] initWithDatabase:database error:nil];

    [stack pushBlob:blobs[0] error:nil];

    database.queryError = [NSError lt_errorWithCode:1337];

    NSError *error;
    auto _Nullable blobs = [stack blobAtIndex:0 error:&error];

    expect(blobs).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeFetchFailed);
  });

  it(@"should indicate failure when fetching blobs in range fails", ^{
    auto _Nullable stack = [[WHSDatabaseBlobStack alloc] initWithDatabase:database error:nil];

    [stack pushBlob:blobs[0] error:nil];

    database.queryError = [NSError lt_errorWithCode:1337];

    NSError *error;
    auto _Nullable blobs = [stack blobsInRange:NSMakeRange(0, 1) error:&error];

    expect(blobs).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeFetchFailed);
  });

  it(@"should indicate failure when fetching count fails", ^{
    auto _Nullable stack = [[WHSDatabaseBlobStack alloc] initWithDatabase:database error:nil];

    database.queryError = [NSError lt_errorWithCode:1337];

    NSError *error;
    auto _Nullable count = [stack countWithError:&error];

    expect(count).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeFetchFailed);
  });
});

SpecEnd
