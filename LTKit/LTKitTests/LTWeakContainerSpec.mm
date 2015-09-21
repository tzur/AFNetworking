// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTWeakContainer.h"

SpecBegin(LTWeakContainer)

__block LTWeakContainer *container;

afterEach(^{
  container = nil;
});

it(@"should initialize with object", ^{
  id object = [[NSObject alloc] init];
  container = [[LTWeakContainer alloc] initWithObject:object];
  expect(container.object).to.beIdenticalTo(object);
});

it(@"should initialize without object", ^{
  container = [[LTWeakContainer alloc] initWithObject:nil];
  expect(container.object).to.beNil();
});

it(@"should weakly hold the contained object", ^{
  __weak id weakObject;
  @autoreleasepool {
    id object = [[NSObject alloc] init];
    container = [[LTWeakContainer alloc] initWithObject:object];
    weakObject = object;
  }
  expect(weakObject).to.beNil();
});

it(@"should set the contained object to nil when it is deallocated", ^{
  @autoreleasepool {
    id object = [[NSObject alloc] init];
    container = [[LTWeakContainer alloc] initWithObject:object];
  }
  expect(container.object).to.beNil();
});

SpecEnd
