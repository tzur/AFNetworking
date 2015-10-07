// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "NSValue+Type.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSValue (Type)

- (BOOL)lt_isKindOfObjCType:(const char *)type {
  if (!type) {
    return NO;
  }
  return !strcmp(self.objCType, type);
}

@end

NS_ASSUME_NONNULL_END
