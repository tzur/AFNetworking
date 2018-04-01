// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode+Builder.h"

#import "NSArray+BLUNodeCollection.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BLUNode (Builder)

+ (BLUNodeBuilder *(^)(void))builder {
  return ^{
    return [[BLUNodeBuilder alloc] init];
  };
}

@end

@interface BLUNodeBuilder () {
  /// Name of the node.
  NSString *_name;

  /// Value of the node.
  id _Nullable _value;

  /// Child nodes of the node.
  NSArray<BLUNode *> * _Nullable _childNodes;
}

@end

@implementation BLUNodeBuilder

- (BLUNodeBuilder *(^)(NSString *))name {
  return ^(NSString *name) {
    self->_name = name;
    return self;
  };
}

- (BLUNodeBuilder *(^)(id))value {
  return ^(id value) {
    self->_value = value;
    return self;
  };
}

- (BLUNodeBuilder *(^)(NSArray<BLUNode *> *))childNodes {
  return ^(NSArray<BLUNode *> *childNodes) {
    self->_childNodes = childNodes;
    return self;
  };
}

- (BLUNode *(^)(void))build {
  return ^{
    LTParameterAssert(self->_name, @"Name must be set prior to building the node");
    return [BLUNode nodeWithName:self->_name childNodes:self->_childNodes ?: @[]
                           value:self->_value];
  };
}

@end

NS_ASSUME_NONNULL_END
