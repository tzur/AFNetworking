// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiverNonPersistentStorage.h"

SpecBegin(LTTextureArchiverNonPersistentStorage)

context(@"LTTextureArchiverStorage protocol", ^{
  __block LTTextureArchiverNonPersistentStorage *storage;

  beforeEach(^{
    storage = [[LTTextureArchiverNonPersistentStorage alloc] init];
  });

  afterEach(^{
    storage = nil;
  });

  it(@"should set and return object for keyed subscript", ^{
    storage[@"key1"] = @"a";
    storage[@"key2"] = @1;

    expect(storage[@"key1"]).to.equal(@"a");
    expect(storage[@"key2"]).to.equal(1);
  });

  it(@"should override object for existing key", ^{
    storage[@"key1"] = @"a";
    storage[@"key2"] = @1;

    storage[@"key1"] = @"b";
    storage[@"key2"] = @2;

    expect(storage[@"key1"]).to.equal(@"b");
    expect(storage[@"key2"]).to.equal(2);
  });

  it(@"should return nil for non existing keys", ^{
    storage[@"key1"] = @"a";
    expect(storage[@"key2"]).to.beNil();;
  });

  it(@"should remove object for key", ^{
    storage[@"key1"] = @"a";
    storage[@"key2"] = @1;

    [storage removeObjectForKey:@"key1"];
    [storage removeObjectForKey:@"key2"];

    expect(storage[@"key1"]).to.beNil();
    expect(storage[@"key2"]).to.beNil();
  });

  it(@"should do nothing when trying to remove non existing keys", ^{
    storage[@"key1"] = @"a";
    expect(^{
      [storage removeObjectForKey:@"key2"];
    }).notTo.raiseAny();
  });

  it(@"should return all keys", ^{
    storage[@"key1"] = @"a";
    storage[@"key2"] = @1;
    expect([NSSet setWithArray:storage.allKeys]).to.equal([NSSet setWithArray:@[@"key1", @"key2"]]);
  });
});

SpecEnd
