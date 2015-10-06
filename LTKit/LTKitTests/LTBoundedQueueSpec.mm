// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBoundedQueue.h"

SpecBegin(LTBoundedQueue)

__block LTBoundedQueue<NSObject *> *singleObjectQueue;
__block LTBoundedQueue<NSObject *> *multipleObjectQueue;

__block id firstObject;
__block id secondObject;
__block id thirdObject;

beforeEach(^{
  singleObjectQueue = [[LTBoundedQueue alloc] initWithMaximalCapacity:1];
  multipleObjectQueue = [[LTBoundedQueue alloc] initWithMaximalCapacity:3];

  firstObject = [[NSObject alloc] init];
  secondObject = [[NSObject alloc] init];
  thirdObject = [[NSObject alloc] init];
});

it(@"should be a subclass of ENQueue", ^{
  expect([[LTBoundedQueue class] isSubclassOfClass:[LTQueue class]]).to.beTruthy();
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
  expect(multipleObjectQueue.firstObject).to.beIdenticalTo(firstObject);
  expect(multipleObjectQueue.lastObject).to.beIdenticalTo(thirdObject);
});

it(@"should add objects and return old ones after maximum capacity is reached if desired", ^{
  expect([singleObjectQueue pushObjectAndReturnPoppedObject:firstObject]).to.beNil();
  expect([multipleObjectQueue pushObjectAndReturnPoppedObject:firstObject]).to.beNil();
  expect([singleObjectQueue
          pushObjectAndReturnPoppedObject:secondObject]).to.beIdenticalTo(firstObject);
  expect([multipleObjectQueue pushObjectAndReturnPoppedObject:secondObject]).to.beNil();
  expect([singleObjectQueue
          pushObjectAndReturnPoppedObject:thirdObject]).to.beIdenticalTo(secondObject);
  expect([multipleObjectQueue pushObjectAndReturnPoppedObject:thirdObject]).to.beNil();
  expect(singleObjectQueue.count).to.equal(1);
  expect(multipleObjectQueue.count).to.equal(3);
  expect(singleObjectQueue.firstObject).to.beIdenticalTo(thirdObject);
  expect(multipleObjectQueue.firstObject).to.beIdenticalTo(firstObject);
  expect(multipleObjectQueue.lastObject).to.beIdenticalTo(thirdObject);
});

SpecEnd
