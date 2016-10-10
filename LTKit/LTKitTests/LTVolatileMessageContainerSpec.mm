// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "LTVolatileMessageContainer.h"

SpecBegin(LTVolatileMessageContainer)

__block LTVolatileMessageContainer *container;
__block NSUInteger maxNumberOfEntries;

beforeEach(^{
  maxNumberOfEntries = 20;
  container = [[LTVolatileMessageContainer alloc] initWithMaxNumberOfEntries:maxNumberOfEntries];
});

it(@"should initialize correctly", ^{
  expect(container).toNot.beNil();
  expect(container.maxNumberOfEntries).to.equal(maxNumberOfEntries);
});

it(@"should add logs", ^{
  NSString *hello = @"hello";

  [container addMessage:hello];

  expect(container.messageLog).to.equal(hello);
  expect(container.messages).to.equal(@[hello]);
});

it(@"should log events in order", ^{
  NSString *hello = @"hello";
  NSString *world = @"world";

  [container addMessage:hello];
  [container addMessage:world];

  expect([container.messageLog rangeOfString:hello].location)
      .to.beLessThan([container.messageLog rangeOfString:world].location);
  expect(container.messages).to.equal(@[hello, world]);
});

it(@"should clear log when it's too long", ^{
  container = [[LTVolatileMessageContainer alloc] initWithMaxNumberOfEntries:1];
  NSString *hello = @"hello";
  NSString *world = @"world";

  [container addMessage:hello];
  [container addMessage:world];

  expect(container.messageLog).toNot.contain(hello);
  expect(container.messageLog).to.equal(world);
  expect(container.messages).to.equal(@[world]);
});

it(@"should separate logs with a newline character", ^{
  NSString *hello = @"hello";
  NSString *world = @"world";

  [container addMessage:hello];
  [container addMessage:world];

  expect(container.messageLog).to.equal([container.messages componentsJoinedByString:@"\n"]);
});

SpecEnd
