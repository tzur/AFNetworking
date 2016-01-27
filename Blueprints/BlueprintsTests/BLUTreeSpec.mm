// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUTree.h"

#import "BLUNode.h"
#import "NSArray+BLUNodeCollection.h"

SpecBegin(BLUTree)

__block BLUTree *tree;

beforeEach(^{
  BLUNode *rightMiddle = [BLUNode nodeWithName:@"rightMiddle" childNodes:@[] value:@4];
  BLUNode *right = [BLUNode nodeWithName:@"right"
                             childNodes:@[rightMiddle]
                                  value:@2];

  BLUNode *leftLeft = [BLUNode nodeWithName:@"leftLeft" childNodes:@[] value:@5];
  BLUNode *leftMiddle = [BLUNode nodeWithName:@"leftMiddle" childNodes:@[] value:@6];
  BLUNode *leftRight = [BLUNode nodeWithName:@"leftRight" childNodes:@[] value:@7];
  BLUNode *left = [BLUNode nodeWithName:@"left"
                             childNodes:@[leftLeft, leftMiddle, leftRight]
                                  value:@3];

  BLUNode *root = [BLUNode nodeWithName:@"root" childNodes:@[left, right] value:@1];

  tree = [BLUTree treeWithRoot:root];
});

context(@"fetching node at path", ^{
  it(@"should fetch the root node", ^{
    expect(tree[@"/"]).to.equal(tree.root);
  });

  it(@"should fetch middle node", ^{
    expect(tree[@"/left"]).to.equal(tree.root.childNodes.firstObject);
  });

  it(@"should fetch leaf node", ^{
    BLUNode *left = tree.root.childNodes.firstObject;
    BLUNode *leftRight = left.childNodes.lastObject;
    expect(tree[@"/left/leftRight"]).to.equal(leftRight);
  });

  it(@"should return nil for non existing node", ^{
    expect(tree[@"/foo"]).to.beNil();
  });
});

context(@"adding nodes", ^{
  __block BLUNode *node;

  beforeEach(^{
    node = [BLUNode nodeWithName:@"node" childNodes:@[] value:@8];
  });

  it(@"should add new node to root", ^{
    BLUTree *newTree = [tree treeByAddingChildNode:node toNodeAtPath:@"/"];
    expect(newTree[@"/node"]).to.equal(node);
    expect(newTree[@"/"].childNodes.lastObject).to.equal(node);
  });

  it(@"should add new node to middle node", ^{
    BLUTree *newTree = [tree treeByAddingChildNode:node toNodeAtPath:@"/left"];
    expect(newTree[@"/left/node"]).to.equal(node);
    expect(newTree[@"/left"].childNodes.lastObject).to.equal(node);
  });

  it(@"should add new node to leaf node", ^{
    BLUTree *newTree = [tree treeByAddingChildNode:node toNodeAtPath:@"/left/leftRight"];
    expect(newTree[@"/left/leftRight/node"]).to.equal(node);
    expect(newTree[@"/left/leftRight"].childNodes.lastObject).to.equal(node);
  });

  it(@"should raise when adding node to a non existing path", ^{
    expect(^{
      [tree treeByAddingChildNode:node toNodeAtPath:@"/foo/bar"];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"inserting nodes", ^{
  __block BLUNode *node;

  beforeEach(^{
    node = [BLUNode nodeWithName:@"node" childNodes:@[] value:@8];
  });

  it(@"should insert new node to beginning of root", ^{
    BLUTree *newTree = [tree treeByInsertingChildNode:node toNodeAtPath:@"/" atIndex:0];
    expect(newTree[@"/node"]).to.equal(node);
    expect(newTree[@"/"].childNodes.firstObject).to.equal(node);
  });

  it(@"should insert new node to middle of root", ^{
    BLUTree *newTree = [tree treeByInsertingChildNode:node toNodeAtPath:@"/" atIndex:1];
    expect(newTree[@"/node"]).to.equal(node);
    expect(newTree[@"/"].childNodes[1]).to.equal(node);
  });

  it(@"should insert new node to end of root", ^{
    NSUInteger index = tree[@"/"].childNodes.count;
    BLUTree *newTree = [tree treeByInsertingChildNode:node toNodeAtPath:@"/" atIndex:index];
    expect(newTree[@"/node"]).to.equal(node);
    expect(newTree[@"/"].childNodes.lastObject).to.equal(node);
  });

  it(@"should insert new node to beginning of middle node", ^{
    BLUTree *newTree = [tree treeByInsertingChildNode:node toNodeAtPath:@"/left" atIndex:0];
    expect(newTree[@"/left/node"]).to.equal(node);
    expect(newTree[@"/left"].childNodes.firstObject).to.equal(node);
  });

  it(@"should insert new node to middle of middle node", ^{
    BLUTree *newTree = [tree treeByInsertingChildNode:node toNodeAtPath:@"/left" atIndex:1];
    expect(newTree[@"/left/node"]).to.equal(node);
    expect(newTree[@"/left"].childNodes[1]).to.equal(node);
  });

  it(@"should insert new node to end of middle node", ^{
    NSUInteger index = tree[@"/left"].childNodes.count;
    BLUTree *newTree = [tree treeByInsertingChildNode:node toNodeAtPath:@"/left" atIndex:index];
    expect(newTree[@"/left/node"]).to.equal(node);
    expect(newTree[@"/left"].childNodes.lastObject).to.equal(node);
  });

  it(@"should insert new node to leaf node", ^{
    BLUTree *newTree = [tree treeByInsertingChildNode:node toNodeAtPath:@"/left/leftRight"
                                              atIndex:0];
    expect(newTree[@"/left/leftRight/node"]).to.equal(node);
    expect(newTree[@"/left/leftRight"].childNodes.firstObject).to.equal(node);
  });

  it(@"should raise when inserting node to invalid index", ^{
    expect(^{
      [tree treeByInsertingChildNode:node toNodeAtPath:@"/left/leftRight" atIndex:1];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"removing nodes", ^{
  it(@"should remove node from root", ^{
    BLUTree *newTree = [tree treeByRemovingNodeAtPath:@"/left"];
    expect(newTree[@"/left"]).to.beNil();
  });

  it(@"should remove new node from leaf node", ^{
    BLUTree *newTree = [tree treeByRemovingNodeAtPath:@"/left/leftRight"];
    expect(newTree[@"/left/leftRight"]).to.beNil();
  });

  it(@"should raise when removing the root node", ^{
    expect(^{
      [tree treeByRemovingNodeAtPath:@"/"];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"replacing nodes", ^{
  __block BLUNode *node;

  beforeEach(^{
    node = [BLUNode nodeWithName:@"node" childNodes:@[] value:@8];
  });

  it(@"should replace root node", ^{
    BLUTree *newTree = [tree treeByReplacingNodeAtPath:@"/" withNode:node];
    expect(newTree.root).to.equal(node);
  });

  it(@"should replace child node of the root node", ^{
    BLUTree *newTree = [tree treeByReplacingNodeAtPath:@"/left" withNode:node];
    expect(newTree[@"/node"]).to.equal(node);
    expect(newTree[@"/left"]).to.beNil();
  });

  it(@"should replace child node of a middle node", ^{
    BLUTree *newTree = [tree treeByReplacingNodeAtPath:@"/right/rightMiddle" withNode:node];
    expect(newTree[@"/right/node"]).to.equal(node);
    expect(newTree[@"/right/rightMiddle"]).to.beNil();
  });
});

context(@"enumeration", ^{
  it(@"should enumerate tree pre-order", ^{
    NSMutableArray *nodes = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];

    [tree enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePreOrder
                                usingBlock:^(BLUNode *node, NSString *path, BOOL *) {
      [nodes addObject:node];
      [paths addObject:path];
    }];

    NSArray *expectedPaths = @[@"/", @"/left", @"/left/leftLeft", @"/left/leftMiddle",
                               @"/left/leftRight", @"/right", @"/right/rightMiddle"];
    NSArray *expectedNodes = [expectedPaths.rac_sequence map:^BLUNode *(NSString *path) {
      return tree[path];
    }].array;

    expect(paths).to.equal(expectedPaths);
    expect(nodes).to.equal(expectedNodes);
  });

  it(@"should enumerate tree post-order", ^{
    NSMutableArray *nodes = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];

    [tree enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePostOrder
                                usingBlock:^(BLUNode *node, NSString *path, BOOL *) {
      [nodes addObject:node];
      [paths addObject:path];
    }];

    NSArray *expectedPaths = @[@"/left/leftLeft", @"/left/leftMiddle", @"/left/leftRight", @"/left",
                               @"/right/rightMiddle", @"/right", @"/"];
    NSArray *expectedNodes = [expectedPaths.rac_sequence map:^BLUNode *(NSString *path) {
      return tree[path];
    }].array;

    expect(paths).to.equal(expectedPaths);
    expect(nodes).to.equal(expectedNodes);
  });

  it(@"should stop while enumerating pre order", ^{
    NSMutableArray *nodes = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];

    [tree enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePreOrder
                                usingBlock:^(BLUNode *node, NSString *path, BOOL *stop) {
      *stop = YES;
      [nodes addObject:node];
      [paths addObject:path];
    }];

    expect(paths).to.equal(@[@"/"]);
    expect(nodes).to.equal(@[tree[@"/"]]);
  });

  it(@"should stop while enumerating childs", ^{
    NSMutableArray *nodes = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];

    [tree enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePreOrder
                                usingBlock:^(BLUNode *node, NSString *path, BOOL *stop) {
      if ([path isEqualToString:@"/left"]) {
        *stop = YES;
      }
      [nodes addObject:node];
      [paths addObject:path];
    }];

    expect(paths).to.equal(@[@"/", @"/left"]);
    expect(nodes).to.equal(@[tree[@"/"], tree[@"/left"]]);
  });

  it(@"should stop while enumerating post order", ^{
    NSMutableArray *nodes = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];

    [tree enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePostOrder
                                usingBlock:^(BLUNode *node, NSString *path, BOOL *stop) {
      *stop = YES;
      [nodes addObject:node];
      [paths addObject:path];
    }];

    expect(paths).to.equal(@[@"/left/leftLeft"]);
    expect(nodes).to.equal(@[tree[@"/left/leftLeft"]]);
  });
});

context(@"NSObject", ^{
  __block BLUTree *tree1;
  __block BLUTree *tree2;
  __block BLUTree *tree3;

  beforeEach(^{
    BLUNode *left = [BLUNode nodeWithName:@"left" childNodes:@[] value:@3];
    BLUNode *right = [BLUNode nodeWithName:@"right" childNodes:@[] value:@2];
    BLUNode *root = [BLUNode nodeWithName:@"root" childNodes:@[left, right] value:@1];
    BLUNode *root2 = [BLUNode nodeWithName:@"root" childNodes:@[left, right] value:@1];

    tree1 = [BLUTree treeWithRoot:root];
    tree2 = [BLUTree treeWithRoot:root2];
    tree3 = [BLUTree treeWithRoot:right];
  });

  it(@"should perform isEqual correctly", ^{
    expect(tree1).to.equal(tree2);
    expect(tree1).toNot.equal(tree3);
  });

  it(@"should create proper hash", ^{
    expect(tree1.hash).to.equal(tree2.hash);
  });
});

SpecEnd
