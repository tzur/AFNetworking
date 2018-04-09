// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTreeNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTTreeNode ()

/// Object wrapped by this instance.
@property (strong, readwrite, nonatomic) LTTreeNodeObject object;

/// Ordered collection of children of this instance.
@property (strong, readwrite, nonatomic) NSArray<LTTreeNode<LTTreeNodeObject> *> *children;

@end

@implementation LTTreeNode

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithObject:(LTTreeNodeObject)object
                      children:(NSArray<LTTreeNode<LTTreeNodeObject> *> *)children {
  if (self = [super init]) {
    self.object = [object copyWithZone:nil];
    self.children = [children copy];
  }
  return self;
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (void)enumerateObjectsWithTraversalOrder:(LTTreeTraversalOrder)traversalOrder
                                usingBlock:(NS_NOESCAPE LTTreeTraversalBlock)block {
  __block BOOL stop = NO;
  [self enumerateObjectsWithTraversalOrder:traversalOrder usingBlock:block stop:&stop node:self];
}

- (void)enumerateObjectsWithTraversalOrder:(LTTreeTraversalOrder)traversalOrder
                                usingBlock:(NS_NOESCAPE LTTreeTraversalBlock)block
                                      stop:(BOOL *)stop node:(nullable LTTreeNode *)node {
  if (!node) {
    return;
  }

  if (traversalOrder == LTTreeTraversalOrderPreOrder) {
    block(nn(node), stop);
    if (*stop) {
      return;
    }
  }

  for (LTTreeNode *child in node.children) {
    [self enumerateObjectsWithTraversalOrder:traversalOrder usingBlock:block stop:stop node:child];
    if (*stop) {
      return;
    }
  }

  if (traversalOrder == LTTreeTraversalOrderPostOrder) {
    // No need to check the \c stop variable here since it has been done as last command in the
    // previous loop.
    block(nn(node), stop);
  }
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(nullable LTTreeNode *)node {
  if (node == self) {
    return YES;
  }

  if (![node isKindOfClass:[LTTreeNode class]]) {
    return NO;
  }

  return [self.object isEqual:node.object] && [node.children isEqualToArray:self.children];
}

- (NSUInteger)hash {
  NSUInteger hash = self.object.hash;

  for (LTTreeNode *child in self.children) {
    hash ^= child.hash;
  }

  return hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, object: %@, children count: %lu>",
          self.class, self, self.object, (unsigned long)self.children.count];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark NSMutableCopying
#pragma mark -

- (LTMutableTreeNode<LTTreeNodeObject> *)mutableCopyWithZone:(nullable NSZone __unused *)zone {
  return [[LTMutableTreeNode alloc] initWithObject:self.object
                                            children:[self.children mutableCopy]];
}

#pragma mark -
#pragma mark Deep Copying
#pragma mark -

- (LTTreeNode<LTTreeNodeObject> *)deepCopy {
  NSMutableArray *children =
      self.children ? [NSMutableArray arrayWithCapacity:self.children.count] : nil;

  BOOL createdNewNodeInstance = NO;

  for (LTTreeNode *child in self.children) {
    LTTreeNode *copyOfChild = [child deepCopy];
    [children addObject:copyOfChild];
    createdNewNodeInstance |= (copyOfChild != child);
  }

  if (!createdNewNodeInstance) {
    return [self copy];
  }

  return [[LTTreeNode alloc] initWithObject:self.object children:[children copy]];
}

#pragma mark -
#pragma mark Mutable Deep Copying
#pragma mark -

- (LTMutableTreeNode<LTTreeNodeObject> *)mutableDeepCopy {
  NSMutableArray *children =
      self.children ? [NSMutableArray arrayWithCapacity:self.children.count] : nil;

  for (LTTreeNode *child in self.children) {
    [children addObject:[child mutableDeepCopy]];
  }

  return [[LTMutableTreeNode alloc] initWithObject:self.object children:[children copy]];
}

@end

@implementation LTMutableTreeNode

@dynamic object;
@dynamic children;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithObject:(LTTreeNodeObject)object
                      children:(NSArray<LTTreeNode<LTTreeNodeObject> *> *)children {
  if (self = [super initWithObject:object children:@[]]) {
    self.children = [children mutableCopy];
  }
  return self;
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return [[LTTreeNode alloc] initWithObject:self.object children:[self.children copy]];
}

@end

NS_ASSUME_NONNULL_END
