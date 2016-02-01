// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUModel.h"

#import "BLUModelNodeChange.h"
#import "BLUModelTestUtils.h"
#import "BLUNode.h"
#import "BLUNodeData.h"
#import "BLUTree.h"
#import "NSArray+BLUNodeCollection.h"
#import "NSErrorCodes+Blueprints.h"

SpecBegin(BLUModel)

__block BLUFakeProvider *provider;
__block BLUTree *tree;
__block BLUModel *model;

beforeEach(^{
  BLUNode *child = [BLUNode nodeWithName:@"child" childNodes:@[] value:@3];

  BLUFakeProviderDescriptor *descriptor = [[BLUFakeProviderDescriptor alloc] init];
  provider = descriptor.fakeProvider;
  BLUNode *second = [BLUNode nodeWithName:@"second" childNodes:@[child] value:descriptor];

  BLUNode *first = [BLUNode nodeWithName:@"first" childNodes:@[] value:@5];
  BLUNode *root = [BLUNode nodeWithName:@"root" childNodes:@[first, second] value:@7];

  tree = [BLUTree treeWithRoot:root];
  model = [[BLUModel alloc] initWithTree:tree];
});

context(@"tree model", ^{
  __block BLUTree *treeAfterAttachment;

  beforeEach(^{
    BLUNode *emptyNode = [BLUNode nodeWithName:@"second" childNodes:@[] value:[NSNull null]];
    treeAfterAttachment = [tree treeByReplacingNodeAtPath:@"/second" withNode:emptyNode];
  });

  it(@"should send the initial tree model", ^{
    BLUNode *emptyNode = [BLUNode nodeWithName:@"second" childNodes:@[] value:[NSNull null]];
    BLUTree *treeAfterAttachment = [tree treeByReplacingNodeAtPath:@"/second" withNode:emptyNode];

    expect(model.treeModel).will.sendValues(@[treeAfterAttachment]);
  });

  it(@"should send the initial tree model on second subscription", ^{
    expect(model.treeModel).will.sendValues(@[treeAfterAttachment]);
    expect(model.treeModel).will.sendValues(@[treeAfterAttachment]);
  });

  it(@"should send new tree upon changing value of a node", ^{
    LLSignalTestRecorder *recorder = [model.treeModel testRecorder];

    BLUNodeData *nodeData = [BLUNodeData nodeDataWithValue:@42 childNodes:@[]];
    [provider sendNodeData:nodeData];

    expect(recorder.values.count).will.equal(2);
    expect(recorder.values.firstObject).notTo.equal(recorder.values.lastObject);
  });

  it(@"should send new tree upon changing child nodes of a node", ^{
    LLSignalTestRecorder *recorder = [model.treeModel testRecorder];

    BLUNode *child = [BLUNode nodeWithName:@"child" childNodes:@[] value:@1];
    BLUNodeData *nodeData = [BLUNodeData nodeDataWithValue:[NSNull null] childNodes:@[child]];
    [provider sendNodeData:nodeData];

    expect(recorder.values.count).to.equal(2);
    expect(recorder.values.firstObject).notTo.equal(recorder.values.lastObject);
  });
});

context(@"model manipulations", ^{
  it(@"should replace value of node", ^{
    BLUNodeData *nodeData = [BLUNodeData nodeDataWithValue:@42 childNodes:@[]];
    [provider sendNodeData:nodeData];

    BLUTree *tree = model.treeModel.first;
    expect(tree[@"/second"].value).to.equal(@42);
  });

  it(@"should replace child nodes of node", ^{
    BLUNode *child = [BLUNode nodeWithName:@"child" childNodes:@[] value:@1];
    BLUNodeData *nodeData = [BLUNodeData nodeDataWithValue:[NSNull null] childNodes:@[child]];
    [provider sendNodeData:nodeData];

    BLUTree *tree = model.treeModel.first;
    expect(tree[@"/second/child"].value).to.equal(@1);
  });
});

context(@"observations", ^{
  it(@"should send change for node when its value is changed", ^{
    LLSignalTestRecorder *recorder = [[model changesForNodeAtPath:@"/second"] testRecorder];

    BLUNode *oldNode = model.treeModel.first[@"/second"];
    BLUNode *newNode = [BLUNode nodeWithName:oldNode.name childNodes:oldNode.childNodes value:@42];

    BLUNodeData *nodeData = [BLUNodeData nodeDataWithValue:@42 childNodes:@[]];
    [provider sendNodeData:nodeData];

    expect(recorder.values).will.equal(@[
      [BLUModelNodeChange nodeChangeWithPath:@"/second" afterNode:oldNode],
      [BLUModelNodeChange nodeChangeWithPath:@"/second" beforeNode:oldNode afterNode:newNode]
    ]);
  });

  it(@"should send change for node when its child nodes are changed", ^{
    LLSignalTestRecorder *recorder = [[model changesForNodeAtPath:@"/second"] testRecorder];

    BLUNode *child = [BLUNode nodeWithName:@"child" childNodes:@[] value:@1];
    BLUNodeData *nodeData = [BLUNodeData nodeDataWithValue:[NSNull null] childNodes:@[child]];

    BLUNode *oldNode = model.treeModel.first[@"/second"];
    BLUNode *newNode = [BLUNode nodeWithName:oldNode.name childNodes:@[child] value:oldNode.value];

    [provider sendNodeData:nodeData];

    expect(recorder.values).will.equal(@[
      [BLUModelNodeChange nodeChangeWithPath:@"/second" afterNode:oldNode],
      [BLUModelNodeChange nodeChangeWithPath:@"/second" beforeNode:oldNode afterNode:newNode]
    ]);
  });

  it(@"should send error when trying to observe an invalid path", ^{
    expect([model changesForNodeAtPath:@"/foo/bar"]).will.matchError(^BOOL(NSError *error) {
      return [error.domain isEqual:kLTErrorDomain] && error.code == BLUErrorCodeNodeNotFound;
    });
  });

  it(@"should complete when observed node is removed", ^{
    BLUNode *child = [BLUNode nodeWithName:@"child" childNodes:@[] value:@1];
    BLUNodeData *nodeData = [BLUNodeData nodeDataWithValue:[NSNull null] childNodes:@[child]];
    [provider sendNodeData:nodeData];

    LLSignalTestRecorder *recorder = [[model changesForNodeAtPath:@"/second/child"] testRecorder];

    BLUNodeData *nodeWithoutChildrenData = [BLUNodeData nodeDataWithValue:@42 childNodes:@[]];
    [provider sendNodeData:nodeWithoutChildrenData];

    expect(recorder.hasCompleted).will.beTruthy();
  });
});

SpecEnd
