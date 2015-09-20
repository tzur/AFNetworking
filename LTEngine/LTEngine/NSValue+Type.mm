// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "NSValue+Type.h"

@implementation NSValue (Type)

- (BOOL)lt_isKindOfObjCType:(const char *)type {
  if (!type) {
    return NO;
  }
  return !strcmp(self.objCType, type);
}

@end
