// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "UIColor+Vector.h"

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"

@implementation UIColor (GLKVector)

- (GLKVector4)glVector {
  CGFloat r, g, b, a;
  if ([self getRed:&r green:&g blue:&b alpha:&a]) {
    return GLKVector4Make(r, g, b, a);
  } else if ([self getWhite:&r alpha:&a]) {
    return GLKVector4Make(r, r, r, a);
  }
  return GLKVector4();
}

- (cv::Vec4b)cvVector {
  GLKVector4 glVector = self.glVector * UCHAR_MAX;
  return cv::Vec4b(glVector.r, glVector.g, glVector.b, glVector.a);
}

@end
