// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAlbumChangesetMove.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNAlbumChangesetMove

+ (instancetype)changesetMoveFrom:(NSUInteger)fromIndex to:(NSUInteger)toIndex {
  PTNAlbumChangesetMove *move = [[PTNAlbumChangesetMove alloc] init];
  move->_fromIndex = fromIndex;
  move->_toIndex = toIndex;
  return move;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNAlbumChangesetMove *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return self.fromIndex == object.fromIndex && self.toIndex == object.toIndex;
}

- (NSUInteger)hash {
  return self.fromIndex ^ self.toIndex;
}

@end

NS_ASSUME_NONNULL_END
