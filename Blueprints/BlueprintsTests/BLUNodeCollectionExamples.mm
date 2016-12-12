// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNodeCollectionExamples.h"

#import "BLUNode.h"
#import "BLUNodeCollection.h"
#import "NSArray+BLUNodeCollection.h"
#import "NSIndexSet+Blueprints.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kBLUNodeCollectionExamples = @"BLUNodeCollectionExamples";
NSString * const kBLUNodeCollectionExamplesCollection = @"BLUNodeCollectionExamplesCollection";

SharedExampleGroupsBegin(BLUNodeCollectionExamples)

sharedExamplesFor(kBLUNodeCollectionExamples, ^(NSDictionary *data) {
  __block id<BLUNodeCollection> collection;

  beforeEach(^{
    collection = data[kBLUNodeCollectionExamplesCollection];
  });

  context(@"removal", ^{
    it(@"should return new collection by removing nodes", ^{
      NSArray *nodes = @[collection.firstObject, collection.lastObject];
      id<BLUNodeCollection> newCollection = [collection blu_nodeCollectionByRemovingNodes:nodes];

      expect(newCollection.count).to.equal(collection.count - 2);
      expect([newCollection indexOfObject:nodes.firstObject]).to.equal(NSNotFound);
      expect([newCollection indexOfObject:nodes.lastObject]).to.equal(NSNotFound);
    });
  });

  context(@"insertion", ^{
    it(@"should return new collection by inserting node at the beginning", ^{
      BLUNode *node = [BLUNode nodeWithName:@"node" childNodes:@[] value:@10];
      id<BLUNodeCollection> newCollection = [collection blu_nodeCollectionByInsertingNode:node
                                                                                  atIndex:0];

      expect(newCollection.count).to.equal(collection.count + 1);
      expect(newCollection.firstObject).to.equal(node);
    });

    it(@"should return new collection by inserting node at the end", ^{
      BLUNode *node = [BLUNode nodeWithName:@"node" childNodes:@[] value:@10];
      id<BLUNodeCollection> newCollection = [collection
                                             blu_nodeCollectionByInsertingNode:node
                                             atIndex:collection.count];

      expect(newCollection.count).to.equal(collection.count + 1);
      expect(newCollection.lastObject).to.equal(node);
    });

    it(@"should return new collection by inserting nodes at indexes", ^{
      BLUNode *first = [BLUNode nodeWithName:@"foo" childNodes:@[] value:@15];
      BLUNode *second = [BLUNode nodeWithName:@"bar" childNodes:@[] value:@25];

      NSIndexSet *indexSet = [NSIndexSet blu_indexSetWithIndexes:{0, collection.count + 1}];
      id<BLUNodeCollection> newCollection = [collection
                                             blu_nodeCollectionByInsertingNodes:@[first, second]
                                             atIndexes:indexSet];

      expect(newCollection.count).to.equal(collection.count + 2);
      expect(newCollection.firstObject).to.equal(first);
      expect(newCollection.lastObject).to.equal(second);
    });
  });

  context(@"replacement", ^{
    it(@"should return new collection by replacing nodes at indexes with nodes", ^{
      BLUNode *first = [BLUNode nodeWithName:@"foo" childNodes:@[] value:@15];
      BLUNode *second = [BLUNode nodeWithName:@"bar" childNodes:@[] value:@25];

      NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
      NSArray *nodes = @[first, second];
      id<BLUNodeCollection> newCollection = [collection
                                             blu_nodeCollectionByReplacingNodesAtIndexes:indexes
                                             withNodes:nodes];

      expect(newCollection.count).to.equal(collection.count);
      expect(newCollection[0]).to.equal(first);
      expect(newCollection[1]).to.equal(second);
    });
  });

  context(@"name resolving", ^{
    it(@"should return node for name", ^{
      BLUNode *firstNode = collection.firstObject;
      expect([collection blu_nodeForName:firstNode.name]).to.equal(firstNode);

      BLUNode *lastNode = collection.lastObject;
      expect([collection blu_nodeForName:lastNode.name]).to.equal(lastNode);
    });
  });
});

SharedExampleGroupsEnd

NS_ASSUME_NONNULL_END
