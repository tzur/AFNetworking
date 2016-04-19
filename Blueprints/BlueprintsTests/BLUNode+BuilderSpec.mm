// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode+Builder.h"

#import "BLUNode+Tree.h"
#import "BLUNodeCollection.h"

SpecBegin(BLUNode_Builder)

it(@"should build proper tree", ^{
  BLUNode *node = BLUNode.builder().name(@"root").childNodes(@[
    BLUNode.builder().name(@"firstChild").value(@5).build(),
    BLUNode.builder().name(@"secondChild").value(@3).build(),
    BLUNode.builder().name(@"thirdChild").build()
  ]).build();

  expect(node.name).to.equal(@"root");
  expect(node.childNodes.count).to.equal(3);

  expect(node[@"/firstChild"].name).to.equal(@"firstChild");
  expect(node[@"/firstChild"].value).to.equal(@5);

  expect(node[@"/secondChild"].name).to.equal(@"secondChild");
  expect(node[@"/secondChild"].value).to.equal(@3);

  expect(node[@"/thirdChild"].name).to.equal(@"thirdChild");
  expect(node[@"/thirdChild"].value).to.beNil();
});

it(@"should fail building a node without a name", ^{
  expect(^{
    BLUNode.builder().value(@7).build();
  }).to.raise(NSInvalidArgumentException);

  expect(^{
    BLUNode.builder().value(@7).childNodes(@[
      BLUNode.builder().name(@"firstChild").value(@5).build()
    ]).build();
  }).to.raise(NSInvalidArgumentException);
});

SpecEnd
