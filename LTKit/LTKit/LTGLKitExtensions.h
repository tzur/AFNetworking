// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <GLKit/GLKMath.h>

GLK_INLINE GLKMatrix3 GLKMatrix3MakeTranslation(float tx, float ty) {
  return GLKMatrix3Make(1, 0, 0,
                        0, 1, 0,
                        tx, ty, 1);
}
