// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUModel.h"

#import "BLUNodeCollection.h"
#import "BLUModelNodeChange.h"
#import "BLUNode.h"
#import "BLUNodeData.h"
#import "BLUProvider.h"
#import "BLUProviderDescriptor.h"
#import "BLUTree.h"
#import "NSArray+BLUNodeCollection.h"
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

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithTree:(BLUTree *)tree {
  if (self = [super init]) {
    self.tree = tree;
    self.lock = [[NSRecursiveLock alloc] init];
    self.nodeChangesSignal = [RACSubject subject];

    [self attachProvidersToTree:self.tree];
  }
  return self;
}

- (void)attachProvidersToTree:(BLUTree *)tree {
  /// Pair of node and its associated path.
  typedef std::pair<BLUNode *, NSString *> BLUNodeAndPath;

  __block std::vector<BLUNodeAndPath> providersNodeAndPath;

  [tree enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePreOrder usingBlock:^(BLUNode *node,
                                                                                     NSString *path,
                                                                                     BOOL *) {
    if ([node.value conformsToProtocol:@protocol(BLUProviderDescriptor)]) {
      providersNodeAndPath.push_back({node, path});
    }
  }];

  for (const BLUNodeAndPath &nodeAndPath: providersNodeAndPath) {
    [self attachProviderToNode:nodeAndPath.first atPath:nodeAndPath.second];
  }
}

- (void)attachProviderToNode:(BLUNode *)node atPath:(NSString *)path {
  id<BLUProviderDescriptor> descriptor = node.value;
  id<BLUProvider> provider = [descriptor provider];

  // Clear the node value and child nodes, as they should be filled by the provider.
  BLUNodeData *nodeData = [BLUNodeData nodeDataWithValue:[NSNull null] childNodes:@[]];
  [self replaceDataOfNodeAtPath:path withNodeData:nodeData];

  [[provider provideNodeData] subscribeNext:^(BLUNodeData *nodeData) {
    [self replaceDataOfNodeAtPath:path withNodeData:nodeData];
  }];
}

#pragma mark -
#pragma mark Mutations
#pragma mark -

- (void)replaceDataOfNodeAtPath:(NSString *)path withNodeData:(BLUNodeData *)data {
  [self lockAndExecute:^{
    BLUNode * _Nullable node = self.tree[path];
    LTParameterAssert(node, @"Trying to replace data of node at a non-existing path: %@", path);

    if ([node.value isEqual:data.value] && [node.childNodes isEqual:data.childNodes]) {
      return;
    }

    BLUNode *newNode = [BLUNode nodeWithName:node.name childNodes:data.childNodes value:data.value];
    self.tree = [self.tree treeByReplacingNodeAtPath:path withNode:newNode];

    [self sendNodeChangeAtPath:path beforeNode:node afterNode:newNode];
  }];
}

#pragma mark -
#pragma mark Changes
#pragma mark -

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

#pragma mark -
#pragma mark Utilities
#pragma mark -

- (void)lockAndExecute:(LTVoidBlock)block {
  [self.lock lock];
  block();
  [self.lock unlock];
}

@end

NS_ASSUME_NONNULL_END
