// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Category for boxing and unboxing GLKit structs.
@interface NSValue (GLKitExtensions)

- (GLKVector2)GLKVector2Value;
- (GLKVector3)GLKVector3Value;
- (GLKVector4)GLKVector4Value;

+ (NSValue *)valueWithGLKVector2:(GLKVector2)vector;
+ (NSValue *)valueWithGLKVector3:(GLKVector3)vector;
+ (NSValue *)valueWithGLKVector4:(GLKVector4)vector;

- (GLKMatrix2)GLKMatrix2Value;
- (GLKMatrix3)GLKMatrix3Value;
- (GLKMatrix4)GLKMatrix4Value;

+ (NSValue *)valueWithGLKMatrix2:(GLKMatrix2)matrix;
+ (NSValue *)valueWithGLKMatrix3:(GLKMatrix3)matrix;
+ (NSValue *)valueWithGLKMatrix4:(GLKMatrix4)matrix;

@end
