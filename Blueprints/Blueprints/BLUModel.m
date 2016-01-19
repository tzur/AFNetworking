// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUModel.h"

#import "BLUModelNodeChange.h"
#import "BLUNode.h"
#import "BLUTree.h"
#import "NSErrorCodes+Blueprints.h"

NS_ASSUME_NONNULL_BEGIN

@interface BLUModel ()

/// Tree which backs the model. The tree will be changed each time it is manipulated.
@property (strong, nonatomic) BLUTree *tree;

/// Lock which protects the tree from being simultaneously modified from multiple threads.
@property (strong, nonatomic) NSRecursiveLock *lock;

/// Signal that sends \c BLUModelNodeChanges.
@property (strong, nonatomic) RACSubject *nodeChangesSignal;

@end

@implementation BLUModel

- (instancetype)initWithTree:(BLUTree *)tree {
  if (self = [super init]) {
    self.tree = tree;
    self.lock = [[NSRecursiveLock alloc] init];
    self.nodeChangesSignal = [RACSubject subject];
  }
  return self;
}

- (void)replaceValueOfNodeAtPath:(NSString *)path withValue:(BLUNodeValue)value {
  [self lockAndExecute:^{
    BLUNode * _Nullable node = self.tree[path];
    LTParameterAssert(node, @"Trying to replace value of node at a non-existing path: %@", path);

    BLUNode *newNode = [BLUNode nodeWithName:node.name childNodes:node.childNodes value:value];
    self.tree = [self.tree treeByReplacingNodeAtPath:path withNode:newNode];

    [self sendNodeChangeAtPath:path beforeNode:node afterNode:newNode];
  }];
}

- (void)replaceChildNodesOfNodeAtPath:(NSString *)path
                       withChildNodes:(id<BLUNodeCollection>)childNodes {
  [self lockAndExecute:^{
    BLUNode * _Nullable node = self.tree[path];
    LTParameterAssert(node, @"Trying to replace child nodes of node at a non-existing path: %@",
                      path);

    BLUNode *newNode = [BLUNode nodeWithName:node.name childNodes:childNodes value:node.value];
    self.tree = [self.tree treeByReplacingNodeAtPath:path withNode:newNode];

    [self sendNodeChangeAtPath:path beforeNode:node afterNode:newNode];
  }];
}

- (void)sendNodeChangeAtPath:(NSString *)path beforeNode:(BLUNode *)beforeNode
                   afterNode:(BLUNode *)afterNode {
  BLUModelNodeChange *change = [BLUModelNodeChange nodeChangeWithPath:path beforeNode:beforeNode
                                                            afterNode:afterNode];
  [self.nodeChangesSignal sendNext:change];
}

- (RACSignal *)changesForNodeAtPath:(NSString *)path {
  __block RACSignal *signal;

  [self lockAndExecute:^{
    BLUNode *node = self.tree[path];
    if (!node) {
      signal = [RACSignal error:[NSError lt_errorWithCode:BLUErrorCodeNodeNotFound path:path]];
      return;
    }

    RACSignal *initialChange = [RACSignal return:[BLUModelNodeChange nodeChangeWithPath:path
                                                                              afterNode:node]];

    @weakify(self);
    RACSignal *nodeHasBeenRemoved = [self.nodeChangesSignal
        filter:^BOOL(BLUModelNodeChange *change) {
          @strongify(self);
          return [path hasPrefix:change.path] && !self.tree[path];
        }];
    RACSignal *nextChanges = [[self.nodeChangesSignal
        filter:^BOOL(BLUModelNodeChange *change) {
          return [change.path isEqualToString:path];
        }]
        takeUntil:nodeHasBeenRemoved];

    signal = [initialChange concat:nextChanges];
  }];

  return signal;
}

- (RACSignal *)treeModel {
  return RACObserve(self, tree);
}

- (void)lockAndExecute:(LTVoidBlock)block {
  [self.lock lock];
  block();
  [self.lock unlock];
}

@end

NS_ASSUME_NONNULL_END
