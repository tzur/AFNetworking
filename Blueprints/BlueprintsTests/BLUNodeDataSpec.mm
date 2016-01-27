// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNodeData.h"

#import "NSArray+BLUNodeCollection.h"

SpecBegin(BLUNodeData)

__block BLUNodeData<NSNumber *> *nodeData;

__block id value;
__block NSArray *childNodes;

beforeEach(^{
  BLUNode *first = [BLUNode nodeWithName:@"first" childNodes:@[] value:@1];
  BLUNode *second = [BLUNode nodeWithName:@"second" childNodes:@[] value:@2];

  childNodes = @[first, second];
  value = @7;

  nodeData = [BLUNodeData nodeDataWithValue:value childNodes:childNodes];
});

it(@"should initialize with value and childnodes", ^{
  expect(nodeData.value).to.equal(@7);
  expect(nodeData.childNodes).to.equal(childNodes);
});

context(@"NSObject", ^{
  it(@"should perform isEqual correctly", ^{
    BLUNodeData *nodeData1 = [BLUNodeData nodeDataWithValue:@1 childNodes:childNodes];
    BLUNodeData *nodeData2 = [BLUNodeData nodeDataWithValue:@1 childNodes:childNodes];
    BLUNodeData *nodeData3 = [BLUNodeData nodeDataWithValue:@1 childNodes:@[]];
    BLUNodeData *nodeData4 = [BLUNodeData nodeDataWithValue:@2 childNodes:childNodes];

    expect(nodeData1).to.equal(nodeData2);
    expect(nodeData1).notTo.equal(nodeData3);
    expect(nodeData1).notTo.equal(nodeData4);
  });

  it(@"should perform hash correctly", ^{
    BLUNodeData *nodeData1 = [BLUNodeData nodeDataWithValue:@1 childNodes:childNodes];
    BLUNodeData *nodeData2 = [BLUNodeData nodeDataWithValue:@1 childNodes:childNodes];

    expect(nodeData1.hash).to.equal(nodeData2.hash);
  });
});

SpecEnd
