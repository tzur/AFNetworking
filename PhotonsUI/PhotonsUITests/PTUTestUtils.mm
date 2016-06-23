// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUTestUtils.h"

#import "PTUChangesetMove.h"

NS_ASSUME_NONNULL_BEGIN

PTUChangesetMove *PTUCreateChangesetMove(NSUInteger from, NSUInteger to, NSUInteger section) {
  NSIndexPath *fromPath = [NSIndexPath indexPathForItem:from inSection:section];
  NSIndexPath *toPath = [NSIndexPath indexPathForItem:to inSection:section];
  return [PTUChangesetMove changesetMoveFrom:fromPath to:toPath];
}

NS_ASSUME_NONNULL_END
