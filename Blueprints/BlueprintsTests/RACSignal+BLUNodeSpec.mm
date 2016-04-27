// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "RACSignal+BLUNode.h"

#import "BLUNode+Builder.h"
#import "BLUNode+Operations.h"
#import "BLUNode+Tree.h"
#import "BLUNodeCollection.h"
#import "NSErrorCodes+Blueprints.h"

SpecBegin(RACSignal_BLUNode)

__block BLUNode *node;

beforeEach(^{
  node = BLUNode.builder().name(@"root").childNodes(@[
    BLUNode.builder().name(@"first").value(@7).childNodes(@[
      BLUNode.builder().name(@"child").value(@9).childNodes(@[
        BLUNode.builder().name(@"leaf").build()
      ]).build()
    ]).build(),
    BLUNode.builder().name(@"second").value(@5).build()
  ]).build();
});

context(@"subtree at path", ^{
  it(@"should return a subtree of root", ^{
    RACSignal *subtree = [[RACSignal return:node]
        blu_subtreeAtPath:@"/first"];

    expect(subtree).will.sendValues(@[node[@"/first"]]);
  });

  it(@"should return updates when the new root changes", ^{
    BLUNode *newNode = [node nodeByRemovingNodeAtPath:@"/first/child"];

    RACSignal *subtree = [[[RACSignal return:node]
        concat:[RACSignal return:newNode]]
        blu_subtreeAtPath:@"/first"];

    expect(subtree).will.sendValues(@[node[@"/first"], newNode[@"/first"]]);
  });

  it(@"should return updates when a subtree changes", ^{
    BLUNode *newNode = [node nodeByRemovingNodeAtPath:@"/first/child/leaf"];

    RACSignal *subtree = [[[RACSignal return:node]
        concat:[RACSignal return:newNode]]
        blu_subtreeAtPath:@"/first"];

    expect(subtree).will.sendValues(@[node[@"/first"], newNode[@"/first"]]);
  });

  it(@"should complete when the source completes", ^{
    RACSignal *subtree = [[RACSignal return:node]
        blu_subtreeAtPath:@"/first"];

    expect(subtree).will.sendValues(@[node[@"/first"]]);
    expect(subtree).will.complete();
  });

  it(@"should ignore updates when a non related subtree changes", ^{
    BLUNode *newNode = [node nodeByRemovingNodeAtPath:@"/second"];

    RACSignal *subtree = [[[RACSignal return:node]
        concat:[RACSignal return:newNode]]
        blu_subtreeAtPath:@"/first"];

    expect(subtree).will.sendValues(@[node[@"/first"]]);
    expect(subtree).will.complete();
  });

  it(@"should err when the subtree is deleted", ^{
    BLUNode *newNode = [node nodeByRemovingNodeAtPath:@"/first"];

    RACSignal *subtree = [[[[RACSignal return:node]
        concat:[RACSignal return:newNode]]
        concat:[RACSignal never]]
        blu_subtreeAtPath:@"/first"];

    expect(subtree).will.sendError([NSError lt_errorWithCode:BLUErrorCodePathNotFound
                                                        path:@"/first"]);
  });

  it(@"should forward errors correctly", ^{
    NSError *error = [NSError lt_errorWithCode:BLUErrorCodePathNotFound];

    RACSignal *subtree = [[[RACSignal return:node]
        concat:[RACSignal error:error]]
        blu_subtreeAtPath:@"/first"];

    expect(subtree).will.sendError(error);
  });
});

context(@"add child nodes", ^{
  __block NSArray<BLUNode *> *nodesToAdd;

  beforeEach(^{
    nodesToAdd = @[
      BLUNode.builder().name(@"foo").build(),
      BLUNode.builder().name(@"bar").build()
    ];
  });

  it(@"should return initial node before child node signal is sending values", ^{
    RACSignal *mergedNode = [[RACSignal
        return:node]
        blu_addChildNodes:[RACSignal never] toPath:@"/first"];

    expect(mergedNode).will.sendValues(@[node]);
  });

  it(@"should add child nodes", ^{
    RACSignal *mergedNode = [[RACSignal
        return:node]
        blu_addChildNodes:[RACSignal return:nodesToAdd] toPath:@"/first"];

    NSRange range = NSMakeRange([node[@"/first"].childNodes count], nodesToAdd.count);
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:range];
    BLUNode *newNode = [node nodeByInsertingChildNodes:nodesToAdd toNodeAtPath:@"/first"
                                             atIndexes:indexes];
    expect(mergedNode).will.sendValues(@[node, newNode]);
  });

  it(@"should err when initially adding child nodes to invalid path", ^{
    RACSignal *mergedNode = [[RACSignal return:node]
        blu_addChildNodes:[RACSignal return:nodesToAdd] toPath:@"/foo"];

    expect(mergedNode).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BLUErrorCodePathNotFound;
    });
  });

  it(@"should err when adding child nodes to invalid path after path deletion", ^{
    BLUNode *newNode = [node nodeByRemovingNodeAtPath:@"/first"];

    RACSignal *mergedNode = [[[RACSignal
        return:node]
        concat:[RACSignal return:newNode]]
        blu_addChildNodes:[RACSignal return:nodesToAdd] toPath:@"/foo"];

    expect(mergedNode).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BLUErrorCodePathNotFound;
    });
  });

  it(@"should complete when both signals complete", ^{
    RACSignal *mergedNode = [[RACSignal
        return:node]
        blu_addChildNodes:[RACSignal return:nodesToAdd] toPath:@"/first"];

    expect(mergedNode).will.complete();
  });
});

context(@"insert child nodes", ^{
  __block NSArray<BLUNode *> *nodesToInsert;
  __block NSIndexSet *indexesToInsert;
  __block RACTuple *nodesAndIndexes;

  beforeEach(^{
    nodesToInsert = @[
      BLUNode.builder().name(@"foo").build(),
      BLUNode.builder().name(@"bar").build()
    ];
    indexesToInsert = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, nodesToInsert.count)];

    nodesAndIndexes = RACTuplePack(nodesToInsert, indexesToInsert);
  });

  it(@"should return initial node before child node signal is sending values", ^{
    RACSignal *mergedNode = [[RACSignal
        return:node]
        blu_insertChildNodes:[RACSignal never] toPath:@"/first"];

    expect(mergedNode).will.sendValues(@[node]);
  });

  it(@"should insert child nodes", ^{
    RACSignal *mergedNode = [[RACSignal
        return:node]
        blu_insertChildNodes:[RACSignal return:nodesAndIndexes] toPath:@"/first"];

    BLUNode *newNode = [node nodeByInsertingChildNodes:nodesToInsert toNodeAtPath:@"/first"
                                             atIndexes:indexesToInsert];
    expect(mergedNode).will.sendValues(@[node, newNode]);
  });

  it(@"should err when initially adding child nodes to invalid path", ^{
    RACSignal *mergedNode = [[RACSignal
        return:node]
        blu_insertChildNodes:[RACSignal return:nodesAndIndexes] toPath:@"/foo"];

    expect(mergedNode).will.matchError(^BOOL(NSError *error) {
      return error.code == BLUErrorCodePathNotFound;
    });
  });

  it(@"should err when adding child nodes to invalid path after path deletion", ^{
    BLUNode *newNode = [node nodeByRemovingNodeAtPath:@"/first"];

    RACSignal *mergedNode = [[[RACSignal
        return:node]
        concat:[RACSignal return:newNode]]
        blu_insertChildNodes:[RACSignal return:nodesAndIndexes] toPath:@"/foo"];

    expect(mergedNode).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BLUErrorCodePathNotFound;
    });
  });

  it(@"should complete when both signals complete", ^{
    RACSignal *mergedNode = [[RACSignal
        return:node]
        blu_insertChildNodes:[RACSignal return:nodesAndIndexes] toPath:@"/first"];

    expect(mergedNode).will.complete();
  });
});

SpecEnd
