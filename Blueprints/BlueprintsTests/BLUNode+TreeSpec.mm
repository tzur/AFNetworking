// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode+Tree.h"

#import "NSArray+BLUNodeCollection.h"
#import "NSIndexPath+Blueprints.h"
#import "NSIndexSet+Blueprints.h"

SpecBegin(BLUNode_Tree)

__block BLUNode *root;

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

  root = [BLUNode nodeWithName:@"root" childNodes:@[left, right] value:@1];
});

context(@"fetching nodes", ^{
  context(@"at path", ^{
    it(@"should fetch the root node", ^{
      expect(root[@"/"]).to.equal(root);
    });

    it(@"should fetch middle node", ^{
      expect(root[@"/left"]).to.equal(root.childNodes.firstObject);
    });

    it(@"should fetch leaf node", ^{
      BLUNode *left = root.childNodes.firstObject;
      BLUNode *leftRight = left.childNodes.lastObject;
      expect(root[@"/left/leftRight"]).to.equal(leftRight);
    });

    it(@"should return nil for non existing node", ^{
      expect(root[@"/foo"]).to.beNil();
    });
  });

  context(@"at index path", ^{
    it(@"should fetch the root node", ^{
      expect(root[[NSIndexPath blu_empty]]).to.equal(root);
    });

    it(@"should fetch middle node", ^{
      NSIndexPath *indexPath = [NSIndexPath blu_indexPathWithIndexes:{0}];
      expect(root[indexPath]).to.equal(root.childNodes.firstObject);
    });

    it(@"should fetch leaf node", ^{
      BLUNode *left = root.childNodes.firstObject;
      BLUNode *leftRight = left.childNodes.lastObject;
      NSIndexPath *indexPath = [NSIndexPath blu_indexPathWithIndexes:{0, 2}];
      expect(root[indexPath]).to.equal(leftRight);
    });

    it(@"should return nil for non existing node", ^{
      NSIndexPath *indexPath = [NSIndexPath blu_indexPathWithIndexes:{3}];
      expect(root[indexPath]).to.beNil();
    });
  });
});

context(@"adding nodes", ^{
  __block BLUNode *node;

  beforeEach(^{
    node = [BLUNode nodeWithName:@"node" childNodes:@[] value:@8];
  });

  it(@"should add new node to root", ^{
    BLUNode *newNode = [root nodeByAddingChildNode:node toNodeAtPath:@"/"];
    expect(newNode[@"/node"]).to.equal(node);
    expect(newNode[@"/"].childNodes.lastObject).to.equal(node);
  });

  it(@"should add new node to middle node", ^{
    BLUNode *newNode = [root nodeByAddingChildNode:node toNodeAtPath:@"/left"];
    expect(newNode[@"/left/node"]).to.equal(node);
    expect(newNode[@"/left"].childNodes.lastObject).to.equal(node);
  });

  it(@"should add new node to leaf node", ^{
    BLUNode *newNode = [root nodeByAddingChildNode:node toNodeAtPath:@"/left/leftRight"];
    expect(newNode[@"/left/leftRight/node"]).to.equal(node);
    expect(newNode[@"/left/leftRight"].childNodes.lastObject).to.equal(node);
  });

  it(@"should raise when adding node to a non existing path", ^{
    expect(^{
      [root nodeByAddingChildNode:node toNodeAtPath:@"/foo/bar"];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"inserting single node", ^{
  __block BLUNode *node;

  beforeEach(^{
    node = [BLUNode nodeWithName:@"node" childNodes:@[] value:@8];
  });

  it(@"should insert new node to beginning of root", ^{
    BLUNode *newNode = [root nodeByInsertingChildNode:node toNodeAtPath:@"/" atIndex:0];
    expect(newNode[@"/node"]).to.equal(node);
    expect(newNode[@"/"].childNodes.firstObject).to.equal(node);
  });

  it(@"should insert new node to middle of root", ^{
    BLUNode *newNode = [root nodeByInsertingChildNode:node toNodeAtPath:@"/" atIndex:1];
    expect(newNode[@"/node"]).to.equal(node);
    expect(newNode[@"/"].childNodes[1]).to.equal(node);
  });

  it(@"should insert new node to end of root", ^{
    NSUInteger index = root[@"/"].childNodes.count;
    BLUNode *newNode = [root nodeByInsertingChildNode:node toNodeAtPath:@"/" atIndex:index];
    expect(newNode[@"/node"]).to.equal(node);
    expect(newNode[@"/"].childNodes.lastObject).to.equal(node);
  });

  it(@"should insert new node to beginning of middle node", ^{
    BLUNode *newNode = [root nodeByInsertingChildNode:node toNodeAtPath:@"/left" atIndex:0];
    expect(newNode[@"/left/node"]).to.equal(node);
    expect(newNode[@"/left"].childNodes.firstObject).to.equal(node);
  });

  it(@"should insert new node to middle of middle node", ^{
    BLUNode *newNode = [root nodeByInsertingChildNode:node toNodeAtPath:@"/left" atIndex:1];
    expect(newNode[@"/left/node"]).to.equal(node);
    expect(newNode[@"/left"].childNodes[1]).to.equal(node);
  });

  it(@"should insert new node to end of middle node", ^{
    NSUInteger index = root[@"/left"].childNodes.count;
    BLUNode *newNode = [root nodeByInsertingChildNode:node toNodeAtPath:@"/left" atIndex:index];
    expect(newNode[@"/left/node"]).to.equal(node);
    expect(newNode[@"/left"].childNodes.lastObject).to.equal(node);
  });

  it(@"should insert new node to leaf node", ^{
    BLUNode *newNode = [root nodeByInsertingChildNode:node toNodeAtPath:@"/left/leftRight"
                                              atIndex:0];
    expect(newNode[@"/left/leftRight/node"]).to.equal(node);
    expect(newNode[@"/left/leftRight"].childNodes.firstObject).to.equal(node);
  });

  it(@"should raise when inserting node to invalid index", ^{
    expect(^{
      [root nodeByInsertingChildNode:node toNodeAtPath:@"/left/leftRight" atIndex:1];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"inserting multiple nodes", ^{
  __block NSArray<BLUNode *> *nodes;

  beforeEach(^{
    nodes = @[
      [BLUNode nodeWithName:@"first" childNodes:@[] value:@8],
      [BLUNode nodeWithName:@"second" childNodes:@[] value:@10]
    ];
  });

  it(@"should insert new nodes to beginning of root", ^{
    NSIndexSet *indexes = [NSIndexSet blu_indexSetWithIndexes:{0, 1}];
    BLUNode *newNode = [root nodeByInsertingChildNodes:nodes toNodeAtPath:@"/" atIndexes:indexes];
    expect(newNode[@"/"].childNodes[0]).to.equal(nodes[0]);
    expect(newNode[@"/"].childNodes[1]).to.equal(nodes[1]);
  });

  it(@"should insert new nodes to middle of root", ^{
    NSIndexSet *indexes = [NSIndexSet blu_indexSetWithIndexes:{1, 3}];
    BLUNode *newNode = [root nodeByInsertingChildNodes:nodes toNodeAtPath:@"/" atIndexes:indexes];
    expect(newNode[@"/"].childNodes[1]).to.equal(nodes[0]);
    expect(newNode[@"/"].childNodes[3]).to.equal(nodes[1]);
  });

  it(@"should insert new nodes to end of root", ^{
    NSUInteger count = root[@"/"].childNodes.count;
    NSIndexSet *indexes = [NSIndexSet blu_indexSetWithIndexes:{count, count + 1}];
    BLUNode *newNode = [root nodeByInsertingChildNodes:nodes toNodeAtPath:@"/" atIndexes:indexes];
    expect(newNode[@"/"].childNodes[count]).to.equal(nodes[0]);
    expect(newNode[@"/"].childNodes[count + 1]).to.equal(nodes[1]);
  });

  it(@"should insert new nodes to beginning of middle node", ^{
    NSIndexSet *indexes = [NSIndexSet blu_indexSetWithIndexes:{0, 1}];
    BLUNode *newNode = [root nodeByInsertingChildNodes:nodes toNodeAtPath:@"/left"
                                             atIndexes:indexes];
    expect(newNode[@"/left"].childNodes[0]).to.equal(nodes[0]);
    expect(newNode[@"/left"].childNodes[1]).to.equal(nodes[1]);
  });

  it(@"should insert new nodes to middle of middle node", ^{
    NSIndexSet *indexes = [NSIndexSet blu_indexSetWithIndexes:{0, 2}];
    BLUNode *newNode = [root nodeByInsertingChildNodes:nodes toNodeAtPath:@"/left"
                                             atIndexes:indexes];
    expect(newNode[@"/left"].childNodes[0]).to.equal(nodes[0]);
    expect(newNode[@"/left"].childNodes[2]).to.equal(nodes[1]);
  });

  it(@"should insert new nodes to end of middle node", ^{
    NSUInteger count = root[@"/left"].childNodes.count;
    NSIndexSet *indexes = [NSIndexSet blu_indexSetWithIndexes:{count, count + 1}];
    BLUNode *newNode = [root nodeByInsertingChildNodes:nodes toNodeAtPath:@"/left"
                                             atIndexes:indexes];
    expect(newNode[@"/left"].childNodes[count]).to.equal(nodes[0]);
    expect(newNode[@"/left"].childNodes[count + 1]).to.equal(nodes[1]);
  });

  it(@"should insert new nodes to leaf node", ^{
    NSIndexSet *indexes = [NSIndexSet blu_indexSetWithIndexes:{0, 1}];
    BLUNode *newNode = [root nodeByInsertingChildNodes:nodes toNodeAtPath:@"/left/leftRight"
                                             atIndexes:indexes];
    expect(newNode[@"/left/leftRight"].childNodes[0]).to.equal(nodes[0]);
    expect(newNode[@"/left/leftRight"].childNodes[1]).to.equal(nodes[1]);
  });

  it(@"should raise when inserting nodes to invalid index", ^{
    expect(^{
      NSIndexSet *indexes = [NSIndexSet blu_indexSetWithIndexes:{}];
      [root nodeByInsertingChildNodes:nodes toNodeAtPath:@"/left/leftRight" atIndexes:indexes];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"removing nodes", ^{
  it(@"should remove node from root", ^{
    BLUNode *newNode = [root nodeByRemovingNodeAtPath:@"/left"];
    expect(newNode[@"/left"]).to.beNil();
  });

  it(@"should remove new node from leaf node", ^{
    BLUNode *newNode = [root nodeByRemovingNodeAtPath:@"/left/leftRight"];
    expect(newNode[@"/left/leftRight"]).to.beNil();
  });

  it(@"should raise when removing the root node", ^{
    expect(^{
      [root nodeByRemovingNodeAtPath:@"/"];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"replacing nodes", ^{
  __block BLUNode *node;

  beforeEach(^{
    node = [BLUNode nodeWithName:@"node" childNodes:@[] value:@8];
  });

  it(@"should replace root node", ^{
    BLUNode *newNode = [root nodeByReplacingNodeAtPath:@"/" withNode:node];
    expect(newNode).to.equal(node);
  });

  it(@"should replace child node of the root node", ^{
    BLUNode *newNode = [root nodeByReplacingNodeAtPath:@"/left" withNode:node];
    expect(newNode[@"/node"]).to.equal(node);
    expect(newNode[@"/left"]).to.beNil();
  });

  it(@"should replace child node of a middle node", ^{
    BLUNode *newNode = [root nodeByReplacingNodeAtPath:@"/right/rightMiddle" withNode:node];
    expect(newNode[@"/right/node"]).to.equal(node);
    expect(newNode[@"/right/rightMiddle"]).to.beNil();
  });
});

context(@"filtering child nodes", ^{
  it(@"should return equal tree when no filter is applied", ^{
    BLUNode *filtered = [root nodeByFilteringChildNodes:^BOOL(BLUNode *) {
      return YES;
    } atPath:@"/left"];

    expect(filtered).to.equal(root);
  });

  it(@"should return no childnodes when filtering all nodes", ^{
    BLUNode *filtered = [root nodeByFilteringChildNodes:^BOOL(BLUNode *) {
      return NO;
    } atPath:@"/left"];

    expect(filtered[@"/left"].childNodes.count).to.equal(0);
  });

  it(@"should return filtered node with the same name", ^{
    BLUNode *filtered = [root nodeByFilteringChildNodes:^BOOL(BLUNode *) {
      return NO;
    } atPath:@"/left"];

    expect(filtered[@"/left"].name).to.equal(root[@"/left"].name);
  });

  it(@"should return filtered node with the same value", ^{
    BLUNode *filtered = [root nodeByFilteringChildNodes:^BOOL(BLUNode *) {
      return NO;
    } atPath:@"/left"];

    expect(filtered[@"/left"].value).to.equal(root[@"/left"].value);
  });

  it(@"should filter child nodes", ^{
    BLUNode *filtered = [root nodeByFilteringChildNodes:^BOOL(BLUNode *node) {
      return [node.name isEqual:@"leftLeft"];
    } atPath:@"/left"];

    BLUNode *first = filtered[@"/left"];

    expect(first.childNodes.count).to.equal(1);
    expect(first.childNodes.firstObject).to.equal(root[@"/left/leftLeft"]);
  });
});

context(@"mapping child nodes", ^{
  it(@"should return equal node when given identity mapping", ^{
    BLUNode *mapped = [root nodeByMappingChildNodes:^BLUNode *(BLUNode *node) {
      return node;
    } atPath:@"/left"];

    expect(mapped).to.equal(root);
  });

  it(@"should map child nodes", ^{
    BLUNode *mapped = [root nodeByMappingChildNodes:^BLUNode *(BLUNode *node) {
      return [BLUNode nodeWithName:[node.value stringValue] childNodes:@[] value:node.name];
    } atPath:@"/left"];

    for (NSUInteger i = 0; i < mapped.childNodes.count; ++i) {
      BLUNode *mappedChild = mapped[@"/first"].childNodes[i];
      BLUNode *originalChild = root[@"/first"].childNodes[i];

      expect(mappedChild.name).to.equal([originalChild.value stringValue]);
      expect(mappedChild.value).to.equal(originalChild.name);
      expect(mappedChild.childNodes.count).to.equal(0);
    }
  });
});

context(@"enumeration", ^{
  it(@"should enumerate tree pre-order", ^{
    NSMutableArray *nodes = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];

    [root enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePreOrder
                                usingBlock:^(BLUNode *node, NSString *path, BOOL *) {
      [nodes addObject:node];
      [paths addObject:path];
    }];

    NSArray *expectedPaths = @[@"/", @"/left", @"/left/leftLeft", @"/left/leftMiddle",
                               @"/left/leftRight", @"/right", @"/right/rightMiddle"];
    NSArray *expectedNodes = [expectedPaths.rac_sequence map:^BLUNode *(NSString *path) {
      return root[path];
    }].array;

    expect(paths).to.equal(expectedPaths);
    expect(nodes).to.equal(expectedNodes);
  });

  it(@"should enumerate tree post-order", ^{
    NSMutableArray *nodes = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];

    [root enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePostOrder
                                usingBlock:^(BLUNode *node, NSString *path, BOOL *) {
      [nodes addObject:node];
      [paths addObject:path];
    }];

    NSArray *expectedPaths = @[@"/left/leftLeft", @"/left/leftMiddle", @"/left/leftRight", @"/left",
                               @"/right/rightMiddle", @"/right", @"/"];
    NSArray *expectedNodes = [expectedPaths.rac_sequence map:^BLUNode *(NSString *path) {
      return root[path];
    }].array;

    expect(paths).to.equal(expectedPaths);
    expect(nodes).to.equal(expectedNodes);
  });

  it(@"should stop while enumerating pre order", ^{
    NSMutableArray *nodes = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];

    [root enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePreOrder
                                usingBlock:^(BLUNode *node, NSString *path, BOOL *stop) {
      *stop = YES;
      [nodes addObject:node];
      [paths addObject:path];
    }];

    expect(paths).to.equal(@[@"/"]);
    expect(nodes).to.equal(@[root[@"/"]]);
  });

  it(@"should stop while enumerating childs", ^{
    NSMutableArray *nodes = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];

    [root enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePreOrder
                                usingBlock:^(BLUNode *node, NSString *path, BOOL *stop) {
      if ([path isEqualToString:@"/left"]) {
        *stop = YES;
      }
      [nodes addObject:node];
      [paths addObject:path];
    }];

    expect(paths).to.equal(@[@"/", @"/left"]);
    expect(nodes).to.equal(@[root[@"/"], root[@"/left"]]);
  });

  it(@"should stop while enumerating post order", ^{
    NSMutableArray *nodes = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];

    [root enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePostOrder
                                usingBlock:^(BLUNode *node, NSString *path, BOOL *stop) {
      *stop = YES;
      [nodes addObject:node];
      [paths addObject:path];
    }];

    expect(paths).to.equal(@[@"/left/leftLeft"]);
    expect(nodes).to.equal(@[root[@"/left/leftLeft"]]);
  });
});

context(@"tree description", ^{
  it(@"should provide correct tree description", ^{
    NSString *description = [root treeDescription];

    NSArray *expectedLines = @[
      @"/",
      @"|-- left -> 3",
      @"|   `-- leftLeft -> 5",
      @"|   `-- leftMiddle -> 6",
      @"|   `-- leftRight -> 7",
      @"|-- right -> 2",
      @"|   `-- rightMiddle -> 4",
    ];

    expect(description).to.equal([expectedLines componentsJoinedByString:@"\n"]);
  });
});

SpecEnd
