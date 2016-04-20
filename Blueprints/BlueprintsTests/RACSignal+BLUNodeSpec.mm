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

SpecEnd
