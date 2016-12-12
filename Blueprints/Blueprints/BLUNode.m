// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode.h"

#import "BLUNodeCollection.h"
#import "NSArray+BLUNodeCollection.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BLUNode

- (instancetype)initWithName:(NSString *)name childNodes:(id<BLUNodeCollection>)childNodes
                       value:(nullable BLUNodeValue)value {
  LTParameterAssert(name);
  LTParameterAssert(childNodes);
  if (self = [super init]) {
    _name = [name copy];
    _childNodes = [childNodes copyWithZone:nil];
    _value = [value copyWithZone:nil];
  }
  return self;
}

+ (instancetype)nodeWithName:(NSString *)name childNodes:(id<BLUNodeCollection>)childNodes
                       value:(nullable BLUNodeValue)value {
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

  return [self.name isEqualToString:object.name] &&
      [self.childNodes isEqual:object.childNodes] &&
      (self.value == object.value || [self.value isEqual:object.value]);
}

- (NSUInteger)hash {
  return self.name.hash ^ self.childNodes.hash ^ self.value.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, name: %@, value: %@, childNodes: %lu>", self.class,
          self, self.name, self.value, (unsigned long)self.childNodes.count];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
