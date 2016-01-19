// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUModel.h"

#import "BLUModelNodeChange.h"
#import "BLUNode.h"
#import "BLUTree.h"
#import "NSArray+BLUNodeCollection.h"
#import "NSErrorCodes+Blueprints.h"

SpecBegin(BLUModel)

__block BLUTree *tree;
__block BLUModel *model;

beforeEach(^{
  BLUNode *first = [BLUNode nodeWithName:@"first" childNodes:@[] value:@5];
  BLUNode *second = [BLUNode nodeWithName:@"second" childNodes:@[] value:@3];
  BLUNode *root = [BLUNode nodeWithName:@"root" childNodes:@[first, second] value:@7];

  tree = [BLUTree treeWithRoot:root];
  model = [[BLUModel alloc] initWithTree:tree];
});

context(@"tree model", ^{
  it(@"should send the initial tree model", ^{
    expect(model.treeModel).will.sendValues(@[tree]);
  });

  it(@"should send the initial tree model on second subscription", ^{
    expect(model.treeModel).will.sendValues(@[tree]);
    expect(model.treeModel).will.sendValues(@[tree]);
  });

  it(@"should send new tree upon changing value of a node", ^{
    LLSignalTestRecorder *recorder = [model.treeModel testRecorder];

    [model replaceValueOfNodeAtPath:@"/first" withValue:@42];

    expect(recorder.values.count).will.equal(2);
    expect(recorder.values.firstObject).notTo.equal(recorder.values.lastObject);
  });

  it(@"should send new tree upon changing child nodes of a node", ^{
    LLSignalTestRecorder *recorder = [model.treeModel testRecorder];

    BLUNode *child = [BLUNode nodeWithName:@"child" childNodes:@[] value:@1];
    [model replaceChildNodesOfNodeAtPath:@"/first" withChildNodes:@[child]];

    expect(recorder.values.count).to.equal(2);
    expect(recorder.values.firstObject).notTo.equal(recorder.values.lastObject);
  });
});

context(@"model manipulations", ^{
  it(@"should replace value of node", ^{
    [model replaceValueOfNodeAtPath:@"/first" withValue:@42];

    BLUTree *tree = model.treeModel.first;
    expect(tree[@"/first"].value).to.equal(@42);
  });

  it(@"should replace child nodes of node", ^{
    BLUNode *child = [BLUNode nodeWithName:@"child" childNodes:@[] value:@1];
    [model replaceChildNodesOfNodeAtPath:@"/first" withChildNodes:@[child]];

    BLUTree *tree = model.treeModel.first;
    expect(tree[@"/first/child"].value).to.equal(@1);
  });
});

context(@"observations", ^{
  it(@"should send change for node when its value is changed", ^{
    LLSignalTestRecorder *recorder = [[model changesForNodeAtPath:@"/first"] testRecorder];

    [model replaceValueOfNodeAtPath:@"/first" withValue:@42];

    BLUNode *oldNode = tree[@"/first"];
    BLUNode *newNode = [BLUNode nodeWithName:oldNode.name childNodes:oldNode.childNodes value:@42];

    expect(recorder.values).will.equal(@[
      [BLUModelNodeChange nodeChangeWithPath:@"/first" afterNode:oldNode],
      [BLUModelNodeChange nodeChangeWithPath:@"/first" beforeNode:oldNode afterNode:newNode]
    ]);
  });

  it(@"should send change for node when its child nodes are changed", ^{
    LLSignalTestRecorder *recorder = [[model changesForNodeAtPath:@"/first"] testRecorder];

    BLUNode *child = [BLUNode nodeWithName:@"child" childNodes:@[] value:@1];
    [model replaceChildNodesOfNodeAtPath:@"/first" withChildNodes:@[child]];

    BLUNode *oldNode = tree[@"/first"];
    BLUNode *newNode = [BLUNode nodeWithName:oldNode.name childNodes:@[child] value:oldNode.value];

    expect(recorder.values).will.equal(@[
      [BLUModelNodeChange nodeChangeWithPath:@"/first" afterNode:oldNode],
      [BLUModelNodeChange nodeChangeWithPath:@"/first" beforeNode:oldNode afterNode:newNode]
    ]);
  });

  it(@"should send error when trying to observe an invalid path", ^{
    expect([model changesForNodeAtPath:@"/foo/bar"]).will.matchError(^BOOL(NSError *error) {
      return [error.domain isEqual:kLTErrorDomain] && error.code == BLUErrorCodeNodeNotFound;
    });
  });

  it(@"should complete when observed node is removed", ^{
    LLSignalTestRecorder *recorder = [[model changesForNodeAtPath:@"/first"] testRecorder];

    [model replaceChildNodesOfNodeAtPath:@"/" withChildNodes:@[]];

    expect(recorder.hasCompleted).will.beTruthy();
  });
});

SpecEnd
