// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUModelNodeChange.h"

#import "BLUNode.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BLUModelNodeChange

- (instancetype)initWithPath:(NSString *)path beforeNode:(nullable BLUNode *)beforeNode
                   afterNode:(BLUNode *)afterNode {
  if (self = [super init]) {
    _path = [path copy];
    _beforeNode = beforeNode;
    _afterNode = afterNode;
  }
  return self;
}

+ (instancetype)nodeChangeWithPath:(NSString *)path afterNode:(nonnull BLUNode *)afterNode {
  return [[BLUModelNodeChange alloc] initWithPath:path beforeNode:nil afterNode:afterNode];
}

+ (instancetype)nodeChangeWithPath:(NSString *)path beforeNode:(BLUNode *)beforeNode
                         afterNode:(BLUNode *)afterNode {
  return [[BLUModelNodeChange alloc] initWithPath:path beforeNode:beforeNode afterNode:afterNode];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(BLUModelNodeChange *)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.path isEqualToString:object.path] &&
      (self.beforeNode == object.beforeNode || [self.beforeNode isEqual:object.beforeNode]) &&
      [self.afterNode isEqual:object.afterNode];
}

- (NSUInteger)hash {
  return self.beforeNode.hash ^ self.afterNode.hash;
}

- (NSString *)description {
  NSString *beforeNodeDescription = @"";
  if (self.afterNode) {
    beforeNodeDescription = [NSString stringWithFormat:@"beforeNode: %@, ", self.beforeNode];
  }
  return [NSString stringWithFormat:@"<%@: %p, path: %@, %@afterNode: %@>",
          self.class, self, self.path, beforeNodeDescription, self.afterNode];
}

@end

NS_ASSUME_NONNULL_END
