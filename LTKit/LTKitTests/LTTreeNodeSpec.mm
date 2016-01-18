// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTreeNode.h"

static NSString * const kLTTreeNodeExamples = @"LTTreeNodeExamples";

static NSString * const kLTTreeNodeClass = @"LTTreeNodeClass";

static NSString * const kLTTreeNodeEnumerationExamples = @"LTTreeNodeEnumerationExamples";

static NSString * const kLTTreeNodeEnumerationOrder = @"LTTreeNodeEnumerationOrder";

static NSString * const kLTTreeNodeEnumerationExpectedNumbers =
    @"LTTreeNodeEnumerationExpectedNumbers";

SpecBegin(LTTreeNode)

sharedExamplesFor(kLTTreeNodeExamples, ^(NSDictionary *data) {
  __block Class nodeClass;
  __block NSNumber *number;
  __block NSArray<LTTreeNode *> *children;

  beforeEach(^{
    nodeClass = data[kLTTreeNodeClass];
    number = @1;
    children = @[];
  });

  context(@"initialization", ^{
    it(@"should initialize with a given object and children", ^{
      LTTreeNode<NSNumber *> *node = [[nodeClass alloc] initWithObject:number children:children];

      expect(node.object).to.equal(number);
      expect(node.children).to.equal(children);
    });

    it(@"should use a copy of the object provided upon initialization", ^{
      NSMutableArray *object = [NSMutableArray array];
      LTTreeNode<NSMutableArray *> *node =
          [[nodeClass alloc] initWithObject:object children:children];
      expect(node.object).to.equal(object);
      expect(node.object).toNot.beIdenticalTo(object);
    });

    it(@"should use a copy of the children provided upon initialization", ^{
      NSMutableArray *mutableArray = [NSMutableArray array];
      LTTreeNode *node = [[nodeClass alloc] initWithObject:number children:mutableArray];
      expect(node.children).to.equal(mutableArray);
      expect(node.children).toNot.beIdenticalTo(mutableArray);
    });
  });

  context(@"equality", ^{
    __block LTTreeNode<NSNumber *> *node;

    beforeEach(^{
      node = [[nodeClass alloc] initWithObject:number children:children];
    });

    it(@"should return YES when comparing to itself", ^{
      expect([node isEqual:node]).to.beTruthy();
    });

    it(@"should return YES when comparing to a node with equal object", ^{
      LTTreeNode<NSNumber *> *anotherNode =
          [[LTTreeNode alloc] initWithObject:number children:children];
      expect([node isEqual:anotherNode]).to.beTruthy();
    });

    it(@"should return NO when comparing to nil", ^{
      LTTreeNode<NSNumber *> *anotherNode = nil;
      expect([node isEqual:anotherNode]).to.beFalsy();
    });

    it(@"should return NO when comparing to an object of a different class", ^{
      expect([node isEqual:[[NSObject alloc] init]]).to.beFalsy();
    });

    it(@"should return NO when comparing to a node with different object", ^{
      LTTreeNode<NSNumber *> *anotherNode =
          [[LTTreeNode alloc] initWithObject:@2 children:children];
      expect([node isEqual:anotherNode]).to.beFalsy();
    });

    it(@"should return NO when comparing to a node with different number of children", ^{
      LTTreeNode<NSNumber *> *anotherNode =
          [[LTTreeNode alloc] initWithObject:number children:@[]];
      LTTreeNode<NSNumber *> *yetAnotherNode =
          [[LTTreeNode alloc] initWithObject:number children:@[anotherNode]];
      expect([node isEqual:yetAnotherNode]).to.beFalsy();
    });

    it(@"should return NO when comparing to a node with different descendants", ^{
      LTTreeNode<NSNumber *> *root =
          [[LTTreeNode alloc] initWithObject:number children:@[node]];
      LTTreeNode<NSNumber *> *node2 =
          [[LTTreeNode alloc] initWithObject:@2 children:@[]];
      LTTreeNode<NSNumber *> *root2 =
          [[LTTreeNode alloc] initWithObject:number children:@[node2]];
      expect([root isEqual:root2]).to.beFalsy();
    });
  });

  context(@"hash", ^{
    it(@"should return the same hash value for equal objects", ^{
      LTTreeNode<NSNumber *> *node = [[nodeClass alloc] initWithObject:number children:children];
      LTTreeNode<NSNumber *> *node2 = [[nodeClass alloc] initWithObject:number children:children];
      expect(node.hash).to.equal(node2.hash);
    });
  });

  context(@"enumeration", ^{
    sharedExamplesFor(kLTTreeNodeEnumerationExamples, ^(NSDictionary *data) {
      __block LTTreeNode<NSNumber *> *root;
      __block LTTreeTraversalOrder order;

      beforeEach(^{
        LTTreeNode *child = [[LTTreeNode alloc] initWithObject:@2 children:@[]];
        LTTreeNode *anotherChild = [[LTTreeNode alloc] initWithObject:@3 children:@[]];
        LTTreeNode *innerNode = [[LTTreeNode alloc] initWithObject:@1 children:@[child]];
        root = [[LTTreeNode alloc] initWithObject:@0 children:@[innerNode, anotherChild]];
        order = (LTTreeTraversalOrder)[data[kLTTreeNodeEnumerationOrder] integerValue];
      });

      it(@"should correctly iterate over tree", ^{
        NSMutableArray *numbers = [NSMutableArray arrayWithCapacity:4];

        [root enumerateObjectsWithTraversalOrder:order
                                      usingBlock:^(LTTreeNode<NSNumber *> *node, BOOL *) {
          NSLog(@"Test: %@", node);
          [numbers addObject:node.object];
        }];

        expect(numbers).to.equal(data[kLTTreeNodeEnumerationExpectedNumbers]);
      });

      it(@"should stop execution of block when requested", ^{
        NSMutableArray *numbers = [NSMutableArray arrayWithCapacity:4];

        [root enumerateObjectsWithTraversalOrder:order
                                      usingBlock:^(LTTreeNode<NSNumber *> *node, BOOL *stop) {
          [numbers addObject:node.object];
          if ([node.object isEqual:@1]) {
            *stop = YES;
          }
        }];

        NSArray<NSNumber *> *expectedNumbers = data[kLTTreeNodeEnumerationExpectedNumbers];
        NSUInteger i = [expectedNumbers indexOfObject:@1];
        expect(numbers).to.equal([expectedNumbers subarrayWithRange:NSMakeRange(0, i + 1)]);
      });
    });

    itShouldBehaveLike(kLTTreeNodeEnumerationExamples, @{
      kLTTreeNodeEnumerationOrder: @(LTTreeTraversalOrderPreOrder),
      kLTTreeNodeEnumerationExpectedNumbers: @[@0, @1, @2, @3]
    });
    
    itShouldBehaveLike(kLTTreeNodeEnumerationExamples, @{
      kLTTreeNodeEnumerationOrder: @(LTTreeTraversalOrderPostOrder),
      kLTTreeNodeEnumerationExpectedNumbers: @[@2, @1, @3, @0]
    });
  });
});

context(@"LTTreeNode", ^{
  __block NSNumber *number;
  __block NSArray<LTTreeNode<NSNumber *> *> *children;
  __block LTTreeNode<NSNumber *> *node;

  beforeEach(^{
    children = @[];
    number = @1;
    node = [[LTTreeNode alloc] initWithObject:number children:children];
  });

  itShouldBehaveLike(kLTTreeNodeExamples, @{kLTTreeNodeClass: [LTTreeNode class]});

  context(@"copying", ^{
    it(@"should return itself as copy, due to immutability", ^{
      expect([node copy]).to.beIdenticalTo(node);
    });
  });

  context(@"deep copying", ^{
    it(@"should return itself as deep copy if the entire tree is immutable", ^{
      LTTreeNode<NSNumber *> *root = [[LTTreeNode alloc] initWithObject:number children:@[node]];
      expect([root deepCopy]).to.beIdenticalTo(root);
    });

    it(@"should return a new instance as deep copy if parts of the tree are mutable", ^{
      LTMutableTreeNode<NSNumber *> *mutableNode =
          [[LTMutableTreeNode alloc] initWithObject:number children:@[]];
      LTTreeNode<NSNumber *> *root =
          [[LTTreeNode alloc] initWithObject:number children:@[node, mutableNode]];

      LTTreeNode<NSNumber *> *copyOfTree = [root deepCopy];
      expect(copyOfTree).toNot.beIdenticalTo(root);
      expect(copyOfTree).to.equal(root);
      expect(copyOfTree.children).to.equal(root.children);
    });
  });

  context(@"mutable copying", ^{
    it(@"should return a mutable copy of itself", ^{
      LTMutableTreeNode *mutableNode = [node mutableCopy];

      expect(mutableNode).to.beMemberOf([LTMutableTreeNode class]);
      expect(mutableNode.object).to.equal(node.object);
      expect(mutableNode.children).to.equal(node.children);
    });
  });

  context(@"mutable deep copying", ^{
    it(@"should return a mutable deep copy", ^{
      LTTreeNode<NSNumber *> *root =
          [[LTTreeNode alloc] initWithObject:number children:@[node]];

      LTMutableTreeNode<NSNumber *> *mutableCopyOfTree = [root mutableDeepCopy];
      expect(mutableCopyOfTree).to.equal(root);
      expect(mutableCopyOfTree.children).to.equal(root.children);
      expect(mutableCopyOfTree.children.firstObject).to.beMemberOf([LTMutableTreeNode class]);
    });
  });
});

context(@"LTMutableTreeNode", ^{
  __block LTMutableTreeNode<NSNumber *> *mutableNode;
  __block NSNumber *number;
  __block NSArray<LTMutableTreeNode<NSNumber *> *> *children;

  beforeEach(^{
    children = @[];
    number = @1;
  });

  beforeEach(^{
    mutableNode = [[LTMutableTreeNode alloc] initWithObject:number children:children];
  });

  itShouldBehaveLike(kLTTreeNodeExamples, @{kLTTreeNodeClass: [LTMutableTreeNode class]});

  context(@"mutability", ^{
    it(@"should have a mutable object", ^{
      mutableNode.object = @2;

      expect(mutableNode.object).toNot.equal(number);
      expect(mutableNode.object).to.equal(@2);
    });

    it(@"should have a mutable collection of children", ^{
      LTTreeNode<NSNumber *> *anotherNode = [[LTTreeNode alloc] initWithObject:@2 children:@[]];

      [mutableNode.children addObject:anotherNode];

      expect(mutableNode.children).toNot.equal(children);
      expect(mutableNode.children).to.equal(@[anotherNode]);
    });
  });

  context(@"copying", ^{
    it(@"should return an immutable copy of itself", ^{
      LTTreeNode *copyOfNode = [mutableNode copy];
      expect(copyOfNode).to.beMemberOf([LTTreeNode class]);
      expect(copyOfNode.object).to.equal(mutableNode.object);
      expect(copyOfNode.children).to.equal(mutableNode.children);
    });
  });

  context(@"deep copying", ^{
    it(@"should return a new instance as deep copy", ^{
      LTMutableTreeNode<NSNumber *> *anotherMutableNode =
          [[LTMutableTreeNode alloc] initWithObject:number children:@[]];
      LTMutableTreeNode<NSNumber *> *root =
          [[LTMutableTreeNode alloc] initWithObject:number
                                           children:@[mutableNode, anotherMutableNode]];

      LTTreeNode<NSNumber *> *copyOfTree = [root deepCopy];
      expect(copyOfTree).toNot.beIdenticalTo(root);
      expect(copyOfTree).to.equal(root);
      expect(copyOfTree.children).to.equal(root.children);
    });
  });

  context(@"mutable copying", ^{
    it(@"should return a mutable copy of itself", ^{
      LTMutableTreeNode *mutableCopyOfNode = [mutableNode mutableCopy];

      expect(mutableCopyOfNode).to.beMemberOf([LTMutableTreeNode class]);
      expect(mutableCopyOfNode.object).to.equal(mutableNode.object);
      expect(mutableCopyOfNode.children).to.equal(mutableNode.children);
    });
  });
});

SpecEnd
