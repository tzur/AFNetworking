// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode.h"

#import "BLUNodeCollection.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BLUNode

- (instancetype)initWithName:(NSString *)name childNodes:(id<BLUNodeCollection>)childNodes
                       value:(BLUNodeValue)value {
  LTParameterAssert(name);
  LTParameterAssert(childNodes);
  LTParameterAssert(value);
  if (self = [super init]) {
    _name = [name copy];
    _childNodes = [childNodes copyWithZone:nil];
    _value = [value copyWithZone:nil];
  }
  return self;
}

+ (instancetype)nodeWithName:(NSString *)name childNodes:(id<BLUNodeCollection>)childNodes
                       value:(BLUNodeValue)value {
  return [[BLUNode alloc] initWithName:name childNodes:childNodes value:value];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(BLUNode *)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:BLUNode.class]) {
    return NO;
  }

  return [self.name isEqualToString:object.name] && [self.childNodes isEqual:object.childNodes] &&
      [self.value isEqual:object.value];
}

- (NSUInteger)hash {
  return self.name.hash ^ self.childNodes.hash ^ self.value.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, name: %@, value: %@>", self.class, self, self.name,
          self.value];
}

@end

NS_ASSUME_NONNULL_END
