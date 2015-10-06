// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSValue+GLKitExtensions.h"

@implementation NSValue (GLKitExtensions)

- (GLKVector2)GLKVector2Value {
  GLKVector2 vector;
  [self getValue:&vector];
  return vector;
}

- (GLKVector3)GLKVector3Value {
  GLKVector3 vector;
  [self getValue:&vector];
  return vector;
}

- (GLKVector4)GLKVector4Value {
  GLKVector4 vector;
  [self getValue:&vector];
  return vector;
}

+ (NSValue *)valueWithGLKVector2:(GLKVector2)vector {
  return [NSValue valueWithBytes:&vector objCType:@encode(GLKVector2)];
}

+ (NSValue *)valueWithGLKVector3:(GLKVector3)vector {
  return [NSValue valueWithBytes:&vector objCType:@encode(GLKVector3)];
}

+ (NSValue *)valueWithGLKVector4:(GLKVector4)vector {
  return [NSValue valueWithBytes:&vector objCType:@encode(GLKVector4)];
}

- (GLKMatrix2)GLKMatrix2Value {
  GLKMatrix2 vector;
  [self getValue:&vector];
  return vector;
}

- (GLKMatrix3)GLKMatrix3Value {
  GLKMatrix3 vector;
  [self getValue:&vector];
  return vector;
}

- (GLKMatrix4)GLKMatrix4Value {
  GLKMatrix4 vector;
  [self getValue:&vector];
  return vector;
}

+ (NSValue *)valueWithGLKMatrix2:(GLKMatrix2)matrix {
  return [NSValue valueWithBytes:&matrix objCType:@encode(GLKMatrix2)];
}

+ (NSValue *)valueWithGLKMatrix3:(GLKMatrix3)matrix {
  return [NSValue valueWithBytes:&matrix objCType:@encode(GLKMatrix3)];
}

+ (NSValue *)valueWithGLKMatrix4:(GLKMatrix4)matrix {
  return [NSValue valueWithBytes:&matrix objCType:@encode(GLKMatrix4)];
}

@end
