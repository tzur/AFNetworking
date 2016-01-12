// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode+Operations.h"

#import "NSArray+BLUNodeCollection.h"

SpecBegin(BLUNode_Operations)

__block BLUNode *firstChild;
__block BLUNode *secondChild;
__block BLUNode *parent;

beforeEach(^{
  firstChild = [BLUNode nodeWithName:@"first" childNodes:@[] value:@5];
  secondChild = [BLUNode nodeWithName:@"second" childNodes:@[] value:@3];
  parent = [BLUNode nodeWithName:@"node" childNodes:@[firstChild, secondChild] value:@7];
});

context(@"removal", ^{
  it(@"should return new node by removing child nodes", ^{
    BLUNode *newParent = [parent nodeByRemovingChildNodes:@[secondChild]];

    expect(newParent.name).to.equal(parent.name);
    expect(newParent.value).to.equal(parent.value);
    expect(newParent.childNodes).to.equal(@[firstChild]);
  });
});

context(@"insertion", ^{
  it(@"should return new node by inserting child node", ^{
    BLUNode *newChild = [BLUNode nodeWithName:@"child" childNodes:@[] value:@1];
    BLUNode *newParent = [parent nodeByInsertingChildNode:newChild atIndex:0];

    expect(newParent.name).to.equal(parent.name);
    expect(newParent.value).to.equal(parent.value);
    expect(newParent.childNodes).to.equal(@[newChild, firstChild, secondChild]);
  });
});

context(@"replacement", ^{
  it(@"should return new node by replacing child nodes at indexes", ^{
    BLUNode *newChild = [BLUNode nodeWithName:@"child" childNodes:@[] value:@1];
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:0];
    BLUNode *newParent = [parent nodeByReplacingChildNodesAtIndexes:indexes
                                                     withChildNodes:@[newChild]];

    expect(newParent.name).to.equal(parent.name);
    expect(newParent.value).to.equal(parent.value);
    expect(newParent.childNodes).to.equal(@[newChild, secondChild]);
  });
});

SpecEnd
