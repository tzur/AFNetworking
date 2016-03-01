// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUChangesetMove.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTUChangesetMove : NSObject

- (instancetype)initFrom:(NSIndexPath *)fromIndex to:(NSIndexPath *)toIndex {
  if (self = [super init]) {
    _fromIndex = fromIndex;
    _toIndex = toIndex;
  }
  return self;
}

+ (instancetype)changesetMoveFrom:(NSIndexPath *)fromIndex to:(NSIndexPath *)toIndex {
  return [[PTUChangesetMove alloc] initFrom:fromIndex to:toIndex];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTUChangesetMove *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.fromIndex isEqual:object.fromIndex] && [self.toIndex isEqual:object.toIndex];
}

- (NSUInteger)hash {
  return self.fromIndex.hash ^ self.toIndex.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, from: %@, to: %@>", self.class, self,
          self.fromIndex, self.toIndex];
}

@end

NS_ASSUME_NONNULL_END
