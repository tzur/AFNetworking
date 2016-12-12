// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode+Builder.h"

#import "NSArray+BLUNodeCollection.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BLUNode (Builder)

+ (BLUNodeBuilder *(^)())builder {
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
    _name = name;
    return self;
  };
}

- (BLUNodeBuilder *(^)(id))value {
  return ^(id value) {
    _value = value;
    return self;
  };
}

- (BLUNodeBuilder *(^)(NSArray<BLUNode *> *))childNodes {
  return ^(NSArray<BLUNode *> *childNodes) {
    _childNodes = childNodes;
    return self;
  };
}

- (BLUNode *(^)())build {
  return ^{
    LTParameterAssert(_name, @"Name must be set prior to building the node");
    return [BLUNode nodeWithName:_name childNodes:_childNodes ?: @[] value:_value];
  };
}

@end

NS_ASSUME_NONNULL_END
