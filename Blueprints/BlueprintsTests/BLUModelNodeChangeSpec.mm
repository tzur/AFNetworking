// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUModelNodeChange.h"

#import "BLUNode.h"
#import "NSArray+BLUNodeCollection.h"

SpecBegin(BLUModelNodeChange)

it(@"should initialize with beforeNode", ^{
  BLUNode *node = [BLUNode nodeWithName:@"bar" childNodes:@[] value:@7];
  BLUModelNodeChange *change = [BLUModelNodeChange nodeChangeWithPath:@"foo" afterNode:node];

  expect(change.path).to.equal(@"foo");
  expect(change.afterNode).to.equal(node);
});

it(@"should initialize with beforeNode and afterNode", ^{
  BLUNode *beforeNode = [BLUNode nodeWithName:@"bar" childNodes:@[] value:@7];
  BLUNode *afterNode = [BLUNode nodeWithName:@"baz" childNodes:@[] value:@5];
  BLUModelNodeChange *change = [BLUModelNodeChange nodeChangeWithPath:@"foo" beforeNode:beforeNode
                                afterNode:afterNode];

  expect(change.path).to.equal(@"foo");
  expect(change.beforeNode).to.equal(beforeNode);
  expect(change.afterNode).to.equal(afterNode);
});

it(@"should perform isEqual correctly", ^{
  BLUNode *beforeNode = [BLUNode nodeWithName:@"bar" childNodes:@[] value:@7];
  BLUNode *afterNode = [BLUNode nodeWithName:@"baz" childNodes:@[] value:@5];

  BLUModelNodeChange *change1 = [BLUModelNodeChange nodeChangeWithPath:@"foo" beforeNode:beforeNode
                                                             afterNode:afterNode];
  BLUModelNodeChange *change2 = [BLUModelNodeChange nodeChangeWithPath:@"bar" beforeNode:beforeNode
                                                             afterNode:afterNode];
  BLUModelNodeChange *change3 = [BLUModelNodeChange nodeChangeWithPath:@"foo" beforeNode:beforeNode
                                                             afterNode:afterNode];
  BLUModelNodeChange *change4 = [BLUModelNodeChange nodeChangeWithPath:@"foo" beforeNode:afterNode
                                                             afterNode:beforeNode];

  expect(change1).notTo.equal(change2);
  expect(change1).to.equal(change3);
  expect(change1).notTo.equal(change4);
});

it(@"should perform hash correctly", ^{
  BLUNode *node1 = [BLUNode nodeWithName:@"baz" childNodes:@[] value:@7];
  BLUNode *node2 = [BLUNode nodeWithName:@"baz" childNodes:@[] value:@5];

  BLUModelNodeChange *change1 = [BLUModelNodeChange nodeChangeWithPath:@"foo" beforeNode:node1
                                                             afterNode:node2];
  BLUModelNodeChange *change2 = [BLUModelNodeChange nodeChangeWithPath:@"foo" beforeNode:node1
                                                             afterNode:node2];

  expect(change1.hash).to.equal(change2.hash);
});

SpecEnd
