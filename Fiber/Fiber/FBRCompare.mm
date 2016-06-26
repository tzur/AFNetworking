// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRCompare.h"

NS_ASSUME_NONNULL_BEGIN

BOOL FBRCompare(id _Nullable first, id _Nullable second) {
  return first == second || [second isEqual:first];
}

NS_ASSUME_NONNULL_END
