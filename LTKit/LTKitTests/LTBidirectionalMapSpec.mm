// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBidirectionalMap.h"

@interface LTBidirectionalMapObject : NSObject

+ (NSUInteger)instanceCount;

@end

@implementation LTBidirectionalMapObject

static NSUInteger instanceCount = 0;

+ (NSUInteger)instanceCount {
  return instanceCount;
}

- (id)init {
  if (self = [super init]) {
    ++instanceCount;
  }
  return self;
}

- (void)dealloc {
  --instanceCount;
}

@end

SpecBegin(LTBidirectionalMap)

static NSDictionary * const kSampleDict = @{@"a": @1, @"b": @2, @"c": @7};

context(@"initialization", ^{
  it(@"should create an empty map from class method", ^{
    LTBidirectionalMap *map = [LTBidirectionalMap map];

    expect(map.count).to.equal(0);
  });

  it(@"should create an empty map from initializer", ^{
    LTBidirectionalMap *map = [[LTBidirectionalMap alloc] init];

    expect(map.count).to.equal(0);
  });

  it(@"should create map with dictionary from class method", ^{
    LTBidirectionalMap *map = [LTBidirectionalMap mapWithDictionary:kSampleDict];

    expect(map.count).to.equal(3);
  });

  it(@"should create map with dictionary from initializer", ^{
    LTBidirectionalMap *map = [[LTBidirectionalMap alloc] initWithDictionary:kSampleDict];

    expect(map.count).to.equal(3);
  });
});

context(@"mutating the map", ^{
  __block LTBidirectionalMap *map;

  beforeEach(^{
    map = [LTBidirectionalMap map];
    map[@"key"] = @"value";
  });

  it(@"should set new object for key", ^{
    expect(map.count).to.equal(1);
    expect(map[@"key"]).to.equal(@"value");
  });

  it(@"should remove object for key", ^{
    [map removeObjectForKey:@"key"];

    expect(map[@"key"]).to.beNil();
    expect(map.count).to.equal(0);
  });

  it(@"should raise when the object is already associated with a key", ^{
    expect(^{
      map[@"anotherKey"] = @"value";
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not raise when the key already exists in the map", ^{
    expect(^{
      map[@"key"] = @"anotherValue";
    }).toNot.raiseAny();
  });
});

context(@"retrieving keys and values", ^{
  __block LTBidirectionalMap *map;

  beforeEach(^{
    map = [LTBidirectionalMap map];
    map[@"key"] = @"value";
  });

  it(@"should retrieve object for key", ^{
    expect(map[@"key"]).to.equal(@"value");
  });

  it(@"should retrieve key for object", ^{
    expect([map keyForObject:@"value"]).to.equal(@"key");
  });

  it(@"should return nil for an non existing key", ^{
    expect(map[@"foo"]).to.beNil();
  });

  it(@"should return nil for an non existing value", ^{
    expect([map keyForObject:@"foo"]).to.beNil();
  });
});

context(@"memory management", ^{
  it(@"should deallocate object when removed from map", ^{
    LTBidirectionalMap *map = [LTBidirectionalMap map];

    @autoreleasepool {
      LTBidirectionalMapObject *object = [[LTBidirectionalMapObject alloc] init];
      map[@"a"] = object;

      expect([LTBidirectionalMapObject instanceCount]).to.equal(1);
      [map removeObjectForKey:@"a"];
    }

    expect([LTBidirectionalMapObject instanceCount]).to.equal(0);
  });
});

SpecEnd
