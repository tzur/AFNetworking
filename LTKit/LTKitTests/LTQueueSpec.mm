// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQueue.h"

#import "LTKeyPathCoding.h"

@interface LTQueueCountTestObserver : NSObject
@property (nonatomic) NSUInteger count;
@property (nonatomic) NSUInteger numberOfNotifications;
@end

@implementation LTQueueCountTestObserver

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString*, id> *)change
                       context:(void __unused *)context {
  LTAssert([keyPath isEqualToString:@instanceKeypath(LTQueue, count)]);
  LTAssert([object isKindOfClass:[LTQueue class]]);
  self.count = [change[@"new"] unsignedIntegerValue];
  self.numberOfNotifications = self.numberOfNotifications + 1;
}

@end

@interface LTQueueArrayTestObserver : NSObject
@property (nonatomic) NSKeyValueChange changeKind;
@property (nonatomic) NSArray *objects;
@end

@implementation LTQueueArrayTestObserver

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString*, id> *)change
                       context:(void __unused *)context {
  LTParameterAssert([keyPath isEqualToString:@instanceKeypath(LTQueue, array)]);
  LTParameterAssert([object isKindOfClass:[LTQueue class]]);
  self.changeKind = (NSKeyValueChange)[change[NSKeyValueChangeKindKey] unsignedIntegerValue];
  self.objects = ((LTQueue *)object).array;
}

@end

SpecBegin(LTQueue)

__block LTQueue<NSObject *> *queue;
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

it(@"should remove first object from the queue", ^{
  [queue pushObject:firstObject];
  [queue pushObject:secondObject];
  [queue pushObject:thirdObject];
  expect(queue.count).to.equal(3);
  [queue removeFirstObject];
  expect(queue.count).to.equal(2);
  expect(queue.firstObject).to.beIdenticalTo(secondObject);
  [queue removeFirstObject];
  expect(queue.count).to.equal(1);
  expect(queue.firstObject).to.beIdenticalTo(thirdObject);
  [queue removeFirstObject];
  expect(queue.count).to.equal(0);
  [queue removeFirstObject];
  expect(queue.count).to.equal(0);
});

it(@"should remove last object from the queue", ^{
  [queue pushObject:firstObject];
  [queue pushObject:secondObject];
  [queue pushObject:thirdObject];
  expect(queue.count).to.equal(3);
  [queue removeLastObject];
  expect(queue.count).to.equal(2);
  expect(queue.lastObject).to.beIdenticalTo(secondObject);
  [queue removeLastObject];
  expect(queue.count).to.equal(1);
  expect(queue.lastObject).to.beIdenticalTo(firstObject);
  [queue removeLastObject];
  expect(queue.count).to.equal(0);
  [queue removeLastObject];
  expect(queue.count).to.equal(0);
});

it(@"should be possible to remove all objects", ^{
  [queue pushObject:firstObject];
  [queue pushObject:secondObject];
  [queue pushObject:thirdObject];
  expect(queue.count).to.equal(3);
  [queue removeAllObjects];
  expect(queue.count).to.equal(0);
});

it(@"should return the index of a given element in the queue", ^{
  [queue pushObject:firstObject];
  [queue pushObject:secondObject];
  expect([queue indexOfObject:firstObject]).to.equal(0);
  expect([queue indexOfObject:secondObject]).to.equal(1);
  expect([queue indexOfObject:thirdObject]).to.equal((NSInteger)NSNotFound);
});

it(@"should replace an object at a given index with another object", ^{
  [queue pushObject:firstObject];
  [queue pushObject:secondObject];
  [queue replaceObjectAtIndex:0 withObject:thirdObject];
  expect(queue.array[0]).to.equal(thirdObject);
  expect(queue.array[1]).to.equal(secondObject);
  expect(^{
    [queue replaceObjectAtIndex:2 withObject:thirdObject];
  }).to.raise(NSRangeException);
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

context(@"KVO compliance", ^{
  __block LTQueueArrayTestObserver *observer;

  context(@"array property", ^{
    beforeEach(^{
      observer = [[LTQueueArrayTestObserver alloc] init];
      [queue addObserver:observer forKeyPath:@keypath(queue, array)
                 options:NSKeyValueObservingOptionNew context:NULL];
    });

    afterEach(^{
      [queue removeObserver:observer forKeyPath:@keypath(queue, array)];
      observer = nil;
    });

    it(@"should send KVO notification when objects are pushed", ^{
      [queue pushObject:@1];
      expect(observer.changeKind).to.equal(NSKeyValueChangeInsertion);
      expect(observer.objects).to.equal(@[@1]);
    });

    it(@"should send KVO notification when objects are popped", ^{
      [queue pushObject:@1];
      [queue popObject];
      expect(observer.changeKind).to.equal(NSKeyValueChangeRemoval);
      expect(observer.objects).to.equal(@[]);
    });

    it(@"should send KVO notification when objects are replaced", ^{
      [queue pushObject:@1];
      [queue replaceObjectAtIndex:0 withObject:@2];
      expect(observer.changeKind).to.equal(NSKeyValueChangeReplacement);
      expect(observer.objects).to.equal(@[@2]);
    });

    it(@"should send KVO notification when first object is removed", ^{
      [queue pushObject:@1];
      [queue pushObject:@2];
      [queue removeFirstObject];
      expect(observer.changeKind).to.equal(NSKeyValueChangeRemoval);
      expect(observer.objects).to.equal(@[@2]);
    });

    it(@"should send KVO notification when last object is removed", ^{
      [queue pushObject:@1];
      [queue pushObject:@2];
      [queue removeLastObject];
      expect(observer.changeKind).to.equal(NSKeyValueChangeRemoval);
      expect(observer.objects).to.equal(@[@1]);
    });

    it(@"should send KVO notification when a certain object is removed", ^{
      [queue pushObject:@1];
      [queue pushObject:@2];
      [queue removeObject:@1];
      expect(observer.changeKind).to.equal(NSKeyValueChangeRemoval);
      expect(observer.objects).to.equal(@[@2]);
    });

    it(@"should send KVO notification when all objects are removed", ^{
      [queue pushObject:@1];
      [queue pushObject:@2];
      [queue removeLastObject];
      expect(observer.changeKind).to.equal(NSKeyValueChangeRemoval);
      expect(observer.objects).to.equal(@[@1]);
    });
  });

  it(@"should have a KVO-compliant count property", ^{
    LTQueueCountTestObserver *observer = [[LTQueueCountTestObserver alloc] init];
    [queue addObserver:observer forKeyPath:@keypath(queue, count)
               options:NSKeyValueObservingOptionNew context:NULL];

    expect(observer.count).to.equal(0);
    expect(observer.numberOfNotifications).to.equal(0);
    [queue pushObject:@1];
    expect(observer.count).to.equal(1);
    expect(observer.numberOfNotifications).to.equal(1);
    [queue popObject];
    expect(observer.count).to.equal(0);
    expect(observer.numberOfNotifications).to.equal(2);
    [queue pushObject:@1];
    expect(observer.count).to.equal(1);
    expect(observer.numberOfNotifications).to.equal(3);
    [queue pushObject:@2];
    expect(observer.count).to.equal(2);
    expect(observer.numberOfNotifications).to.equal(4);
    [queue replaceObjectAtIndex:0 withObject:@1];
    expect(observer.count).to.equal(2);
    expect(observer.numberOfNotifications).to.equal(4);
    [queue removeFirstObject];
    expect(observer.count).to.equal(1);
    expect(observer.numberOfNotifications).to.equal(5);
    [queue removeLastObject];
    expect(observer.count).to.equal(0);
    expect(observer.numberOfNotifications).to.equal(6);
    [queue pushObject:@1];
    expect(observer.count).to.equal(1);
    expect(observer.numberOfNotifications).to.equal(7);
    [queue pushObject:@2];
    expect(observer.count).to.equal(2);
    expect(observer.numberOfNotifications).to.equal(8);
    [queue removeObject:nn(queue.lastObject)];
    expect(observer.count).to.equal(1);
    expect(observer.numberOfNotifications).to.equal(9);
    [queue removeAllObjects];
    expect(observer.count).to.equal(0);
    expect(observer.numberOfNotifications).to.equal(10);

    [queue removeObserver:observer forKeyPath:@keypath(queue, count)];
  });
});

SpecEnd
