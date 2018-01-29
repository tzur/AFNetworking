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

- (instancetype)init {
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

static NSDictionary<NSString *, NSNumber *> * const kSampleDict = @{@"a": @1, @"b": @2, @"c": @7};

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
    LTBidirectionalMap<NSString *, NSNumber *> *map =
        [LTBidirectionalMap mapWithDictionary:kSampleDict];

    expect(map.count).to.equal(3);
  });

  it(@"should create map with dictionary from initializer", ^{
    LTBidirectionalMap<NSString *, NSNumber *> *map =
        [[LTBidirectionalMap alloc] initWithDictionary:kSampleDict];

    expect(map.count).to.equal(3);
  });

#if defined(DEBUG) && DEBUG
  it(@"should raise when attempting to create a non-bijective map", ^{
    NSDictionary<NSString *, NSNumber *> *nonBijectiveMap = @{@"a": @1, @"b": @1};

    expect(^{
      LTBidirectionalMap<NSString *, NSNumber *> __unused *map =
          [[LTBidirectionalMap alloc] initWithDictionary:nonBijectiveMap];
    }).to.raise(NSInvalidArgumentException);
  });
#endif
});

context(@"mutating the map", ^{
  __block LTBidirectionalMap<NSString *, NSString *> *map;

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
  __block LTBidirectionalMap<NSString *, NSString *> *map;

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

  it(@"should return all keys", ^{
    map = [LTBidirectionalMap mapWithDictionary:kSampleDict];
    expect([[map allKeys] sortedArrayUsingSelector:@selector(compare:)])
        .to.equal(@[@"a", @"b", @"c"]);
  });

  it(@"should return all values", ^{
    map = [LTBidirectionalMap mapWithDictionary:kSampleDict];
    expect([[map allValues] sortedArrayUsingSelector:@selector(compare:)]).to.equal(@[@1, @2, @7]);
  });

  it(@"should return all key-value pairs", ^{
    map = [LTBidirectionalMap mapWithDictionary:kSampleDict];
    expect([map dictionary]).to.equal(kSampleDict);
  });
});

context(@"memory management", ^{
  it(@"should persist objects that are stored in the map", ^{
    LTBidirectionalMap<NSString *, LTBidirectionalMapObject *> *map = [LTBidirectionalMap map];
    LTBidirectionalMapObject *object = [[LTBidirectionalMapObject alloc] init];

    @autoreleasepool {
      NSString *key = [@"a" mutableCopy];
      map[key] = object;
    }

    expect([map keyForObject:object]).to.equal(@"a");
    expect(map[@"a"]).to.equal(object);
  });

  it(@"should deallocate object when removed from map", ^{
    LTBidirectionalMap<NSString *, LTBidirectionalMapObject *> *map = [LTBidirectionalMap map];

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
