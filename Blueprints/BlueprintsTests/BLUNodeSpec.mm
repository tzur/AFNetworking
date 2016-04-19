// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode.h"

#import "NSArray+BLUNodeCollection.h"

SpecBegin(BLUNode)

it(@"should initialize with properties", ^{
  BLUNode<NSNumber *> *child = [BLUNode nodeWithName:@"child" childNodes:@[] value:@7];
  BLUNode<NSNumber *> *parent = [BLUNode nodeWithName:@"parent" childNodes:@[child] value:nil];

  expect(child.name).to.equal(@"child");
  expect(child.childNodes.count).to.equal(0);
  expect(child.value).to.equal(@7);

  expect(parent.name).to.equal(@"parent");
  expect(parent.childNodes.count).to.equal(1);
  expect(parent.childNodes[0]).to.equal(child);
  expect(parent.value).to.beNil();
});

it(@"should copy initializer parameters", ^{
  BLUNode<NSNumber *> *child = [BLUNode nodeWithName:@"child" childNodes:@[] value:@7];

  NSMutableString *name = [@"name" mutableCopy];
  id<BLUNodeCollection> childNodes = [@[child] mutableCopy];
  BLUNodeValue value = [@[@"foo"] mutableCopy];

  BLUNode *parent = [BLUNode nodeWithName:name childNodes:childNodes value:value];

  expect(parent.name).to.equal(name);
  expect(parent.name).notTo.beIdenticalTo(name);

  expect(parent.childNodes).to.equal(childNodes);
  expect(parent.childNodes).notTo.beIdenticalTo(childNodes);

  expect(parent.value).to.equal(value);
  expect(parent.value).notTo.beIdenticalTo(value);
});

context(@"NSObject", ^{
  it(@"should perform isEqual correctly", ^{
    BLUNode<NSNumber *> *node1 = [BLUNode nodeWithName:@"node" childNodes:@[] value:@7];
    BLUNode<NSNumber *> *node2 = [BLUNode nodeWithName:@"node" childNodes:@[] value:@7];
    BLUNode<NSNumber *> *node3 = [BLUNode nodeWithName:@"node3" childNodes:@[] value:@7];
    BLUNode<NSNumber *> *node4 = [BLUNode nodeWithName:@"node" childNodes:@[node2] value:@7];
    BLUNode<NSNumber *> *node5 = [BLUNode nodeWithName:@"node" childNodes:@[] value:@5];
    BLUNode<NSNumber *> *node6 = [BLUNode nodeWithName:@"node" childNodes:@[] value:nil];
    BLUNode<NSNumber *> *node7 = [BLUNode nodeWithName:@"node" childNodes:@[] value:nil];

    expect(node1).to.equal(node2);
    expect(node1).notTo.equal(node3);
    expect(node1).notTo.equal(node4);
    expect(node1).notTo.equal(node5);
    expect(node1).notTo.equal(node6);
    expect(node6).notTo.equal(node7);
  });

  it(@"should perform hash correctly", ^{
    BLUNode<NSNumber *> *node1 = [BLUNode nodeWithName:@"node" childNodes:@[] value:@7];
    BLUNode<NSNumber *> *node2 = [BLUNode nodeWithName:@"node" childNodes:@[] value:@7];

    expect(node1.hash).to.equal(node2.hash);
  });
});

SpecEnd
