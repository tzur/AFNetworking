// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTGLKitExtensions.h"

const GLKVector4 GLKVector4Zero = {{0, 0, 0, 0}};

const GLKVector3 GLKVector3Zero = {{0, 0, 0}};

const GLKVector2 GLKVector2Zero = {{0, 0}};

const GLKVector4 GLKVector4One = {{1, 1, 1, 1}};

const GLKVector3 GLKVector3One = {{1, 1, 1}};

const GLKVector2 GLKVector2One = {{1, 1}};

GLKVector3 GLKLineEquation(const GLKVector2 &source, const GLKVector2 &target) {
  if (source == target) {
    return GLKVector3Zero;
  }
  
  GLKVector2 normal = GLKVector2NormalTo(target - source);
  GLKVector3 line;
  if (source == GLKVector2Zero) {
    line = GLKVector3Make(normal.x, normal.y, -GLKVector2DotProduct(normal, target));
  } else {
    line = GLKVector3Make(normal.x, normal.y, -GLKVector2DotProduct(normal, source));
  }
  return line / (line.z ? ABS(line.z) : 1.0);
}
