// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQueue.h"

SpecBegin(LTQueue)

__block LTQueue *queue;
__block id firstObject;
__block id secondObject;
__block id thirdObject;

beforeEach(^{
  queue = [[LTQueue alloc] init];
  firstObject = [[NSObject alloc] init];
  secondObject = [[NSObject alloc] init];
  thirdObject = [[NSObject alloc] init];
});

it(@"should be empty after initialization", ^{
  expect(queue.count).to.equal(0);
});

it(@"should increase in size when pushing (even identical) objects", ^{
  [queue pushObject:firstObject];
  expect(queue.count).to.equal(1);
  [queue pushObject:firstObject];
  expect(queue.count).to.equal(2);
  [queue pushObject:secondObject];
  expect(queue.count).to.equal(3);
});

it(@"should decrease in size when popping objects", ^{
  [queue pushObject:firstObject];
  [queue pushObject:secondObject];
  [queue pushObject:thirdObject];
  [queue popObject];
  expect(queue.count).to.equal(2);
  [queue popObject];
  expect(queue.count).to.equal(1);
  [queue popObject];
  expect(queue.count).to.equal(0);
});

it(@"should maintain the order of the objects", ^{
  [queue pushObject:firstObject];
  [queue pushObject:secondObject];
  [queue pushObject:thirdObject];
  id firstPoppedObject = [queue popObject];
  id secondPoppedObject = [queue popObject];
  id thirdPoppedObject = [queue popObject];
  expect(firstObject).to.beIdenticalTo(firstPoppedObject);
  expect(secondObject).to.beIdenticalTo(secondPoppedObject);
  expect(thirdObject).to.beIdenticalTo(thirdPoppedObject);
});

it(@"should correctly report whether an object is contained in the queue or not", ^{
  [queue pushObject:firstObject];
  expect([queue containsObject:firstObject]).to.beTruthy();
  expect([queue containsObject:secondObject]).to.beFalsy();
});

it(@"should correctly remove an object from the queue", ^{
  [queue pushObject:firstObject];
  [queue pushObject:secondObject];
  [queue pushObject:thirdObject];
  expect(queue.count).to.equal(3);
  [queue removeObject:secondObject];
  expect(queue.count).to.equal(2);
  id poppedObject = [queue popObject];
  expect(poppedObject).to.beIdenticalTo(firstObject);
  poppedObject = [queue popObject];
  expect(poppedObject).to.beIdenticalTo(thirdObject);
});

it(@"should return an array containing the objects of the queue in correct order", ^{
  [queue pushObject:firstObject];
  [queue pushObject:secondObject];
  [queue pushObject:thirdObject];
  [queue pushObject:secondObject];
  NSArray *array = queue.array;
  NSArray *expectedArray = @[firstObject, secondObject, thirdObject, secondObject];
  expect(array.count).to.equal(expectedArray.count);
  for (NSUInteger i = 0; i < array.count; i++) {
    expect(array[i]).to.beIdenticalTo(expectedArray[i]);
  }
});

it(@"should provide access to the least recently added object", ^{
  [queue pushObject:firstObject];
  expect(queue.firstObject).to.beIdenticalTo(firstObject);
  [queue pushObject:secondObject];
  expect(queue.firstObject).to.beIdenticalTo(firstObject);
  [queue pushObject:thirdObject];
  expect(queue.firstObject).to.beIdenticalTo(firstObject);
});

it(@"should provide access to the most recently added object", ^{
  [queue pushObject:firstObject];
  expect(queue.lastObject).to.beIdenticalTo(firstObject);
  [queue pushObject:secondObject];
  expect(queue.lastObject).to.beIdenticalTo(secondObject);
  [queue pushObject:thirdObject];
  expect(queue.lastObject).to.beIdenticalTo(thirdObject);
});

SpecEnd
