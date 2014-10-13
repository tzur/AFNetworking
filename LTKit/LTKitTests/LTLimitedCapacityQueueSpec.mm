// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTLimitedCapacityQueue.h"

SpecBegin(LTLimitedCapacityQueue)

__block LTLimitedCapacityQueue *singleObjectQueue;
__block LTLimitedCapacityQueue *multipleObjectQueue;
__block id firstObject;
__block id secondObject;
__block id thirdObject;

beforeEach(^{
  singleObjectQueue = [[LTLimitedCapacityQueue alloc] initWithMaximalCapacity:1];
  multipleObjectQueue = [[LTLimitedCapacityQueue alloc] initWithMaximalCapacity:3];
  firstObject = [[NSObject alloc] init];
  secondObject = [[NSObject alloc] init];
  thirdObject = [[NSObject alloc] init];
});

it(@"should be a subclass of ENQueue", ^{
  expect([[LTLimitedCapacityQueue class] isSubclassOfClass:[LTQueue class]]).to.beTruthy();
});

it(@"should be empty after initialization", ^{
  expect(singleObjectQueue.count).to.equal(0);
  expect(multipleObjectQueue.count).to.equal(0);
});

it(@"should add objects without discarding old ones before maximum capacity is reached", ^{
  [multipleObjectQueue pushObject:firstObject];
  expect(multipleObjectQueue.count).to.equal(1);
  [multipleObjectQueue pushObject:secondObject];
  expect(multipleObjectQueue.count).to.equal(2);
  [multipleObjectQueue pushObject:thirdObject];
  expect(multipleObjectQueue.count).to.equal(3);
  expect(multipleObjectQueue.firstObject).to.beIdenticalTo(firstObject);
  expect(multipleObjectQueue.lastObject).to.beIdenticalTo(thirdObject);
});

it(@"should add objects and discard old ones after maximum capacity is reached", ^{
  [singleObjectQueue pushObject:firstObject];
  [multipleObjectQueue pushObject:firstObject];
  [singleObjectQueue pushObject:secondObject];
  [multipleObjectQueue pushObject:secondObject];
  [singleObjectQueue pushObject:thirdObject];
  [multipleObjectQueue pushObject:thirdObject];
  expect(singleObjectQueue.count).to.equal(1);
  expect(multipleObjectQueue.count).to.equal(3);
  expect(singleObjectQueue.firstObject).to.beIdenticalTo(thirdObject);
  expect(singleObjectQueue.lastObject).to.beIdenticalTo(thirdObject);
  expect(multipleObjectQueue.firstObject).to.beIdenticalTo(firstObject);
  expect(multipleObjectQueue.lastObject).to.beIdenticalTo(thirdObject);
});

SpecEnd
