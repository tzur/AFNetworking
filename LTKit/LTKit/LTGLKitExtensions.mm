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

GLKVector4 GLKRGBA2HSVA(const GLKVector4 &rgba) {
  float h, s, v, delta;
  float min = MIN(rgba.r, MIN(rgba.g, rgba.b));
  float max = MAX(rgba.r, MAX(rgba.g, rgba.b));
  delta = max - min;
  
  v = max;
  if (max <= 0) {
    return GLKVector4Make(0, 0, 0, 1);
  }
  s = delta / max;
  
  if (rgba.r == max) {
    // Between yellow & magenta.
    h = (rgba.g - rgba.b) / delta;
  } else if (rgba.g == max) {
    // Between cyan & yellow.
    h = 2 + (rgba.b - rgba.r) / delta;
  } else {
    // Between magenta & cyan.
    h = 4 + (rgba.r - rgba.g) / delta;
  }
  h /= 6;
  return GLKVector4Make(h > 0 ? h : h + 1, s, v, rgba.a);
}
