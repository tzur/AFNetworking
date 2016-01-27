// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNodeData.h"

#import "BLUNodeCollection.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BLUNodeData

- (instancetype)initWithValue:(BLUNodeValue)value childNodes:(id<BLUNodeCollection>)childNodes {
  if (self = [super init]) {
    _value = value;
    _childNodes = childNodes;
  }
  return self;
}

+ (instancetype)nodeDataWithValue:(id)value childNodes:(id<BLUNodeCollection>)childNodes {
  return [[BLUNodeData alloc] initWithValue:value childNodes:childNodes];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(BLUNodeData *)object {
  if (self == object) {
    return YES;
  }

  if (![self isKindOfClass:object.class]) {
    return NO;
  }

  return [self.value isEqual:object.value] && [self.childNodes isEqual:object.childNodes];
}

- (NSUInteger)hash {
  return self.value.hash ^ self.childNodes.hash;
}

@end

NS_ASSUME_NONNULL_END
