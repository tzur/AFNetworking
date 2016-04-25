// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLULazyNodeCollection.h"

#import "BLUFastEnumerator.h"
#import "BLUNode.h"
#import "NSArray+BLUNodeCollection.h"

@interface BLULazyNodeCollection ()

/// Block used for naming the returned nodes.
@property (copy, nonatomic) BLUNodeNamingBlock namingBlock;

/// Fast enumerator configured to return \c BLUNode instances.
@property (strong, nonatomic) BLUFastEnumerator *fastEnumerator;

@end

@implementation BLULazyNodeCollection

- (instancetype)initWithCollection:(id<LTRandomAccessCollection>)collection
                       namingBlock:(BLUNodeNamingBlock)namingBlock {
  LTParameterAssert(namingBlock);
  if (self = [super init]) {
    _collection = [collection copyWithZone:nil];
    _namingBlock = [namingBlock copy];

    @weakify(self);
    _fastEnumerator = [[[BLUFastEnumerator alloc] initWithSource:self.collection] map:^(id value) {
      @strongify(self);
      return [self nodeWithValue:value];
    }];
  }
  return self;
}

#pragma mark -
#pragma mark LTRandomAccessCollection
#pragma mark -

- (BLUNode *)objectAtIndexedSubscript:(NSUInteger)idx {
  return [self objectAtIndex:idx];
}

- (BLUNode *)objectAtIndex:(NSUInteger)idx {
  id value = self.collection[idx];
  return [self nodeWithValue:value];
}

- (BOOL)containsObject:(BLUNode *)node {
  return [self indexOfObject:node] != NSNotFound;
}

- (NSUInteger)indexOfObject:(BLUNode *)node {
  // We aim to match the internal implementation of \c isEqual: of \c BLUNode by checking that the
  // \c childNodes collection is indeed an \c NSArray.
  if (![node.childNodes isEqual:@[]]) {
    return NSNotFound;
  }
  if (![self.namingBlock(node.value) isEqualToString:node.name]) {
    return NSNotFound;
  }
  return [self.collection indexOfObject:node.value];
}

- (nullable id)firstObject {
  return self.count ? self[0] : nil;
}

- (nullable id)lastObject {
  return self.count ? self[self.collection.count - 1] : nil;
}

- (NSUInteger)count {
  return self.collection.count;
}

- (BLUNode *)nodeWithValue:(id)value {
  return [BLUNode nodeWithName:self.namingBlock(value) childNodes:@[] value:value];
}

#pragma mark -
#pragma mark BLUNodeCollection
#pragma mark -

- (nullable BLUNode *)blu_nodeForName:(NSString *)name {
  for (id value in self.collection) {
    if ([self.namingBlock(value) isEqualToString:name]) {
      return [self nodeWithValue:value];
    }
  }

  return nil;
}

- (instancetype)blu_nodeCollectionByInsertingNode:(BLUNode __unused *)node
                                          atIndex:(__unused NSUInteger)index {
  LTParameterAssert(NO, @"Node collection cannot be recreated with new nodes");
}

- (instancetype)blu_nodeCollectionByRemovingNodes:(NSArray<BLUNode *> __unused *)nodes {
  LTParameterAssert(NO, @"Node collection cannot be recreated with new nodes");
}

- (instancetype)blu_nodeCollectionByReplacingNodesAtIndexes:(NSIndexSet __unused *)indexes
                                                  withNodes:(NSArray<BLUNode *> __unused *)nodes {
  LTParameterAssert(NO, @"Node collection cannot be recreated with new nodes");
}

- (instancetype)blu_nodeCollectionByInsertingNodes:(NSArray<BLUNode *> __unused *)nodes
                                         atIndexes:(NSIndexSet __unused *)indexes {
  LTParameterAssert(NO, @"Node collection cannot be recreated with new nodes");
}

#pragma mark -
#pragma mark NSFastEnumeration
#pragma mark -

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id __unused *)buffer
                                    count:(NSUInteger)len {
  return [self.fastEnumerator countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  // Collection and naming block are already copied, so this class is immutable.
  return self;
}

@end
