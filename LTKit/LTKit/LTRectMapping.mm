// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectMapping.h"

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTRotatedRect.h"

#pragma mark -
#pragma mark Rects
#pragma mark -

GLKMatrix3 LTTextureMatrix3ForRect(CGRect rect, CGSize textureSize) {
  CGRect normalizedRect = CGRectMake(rect.origin.x / textureSize.width,
                                     rect.origin.y / textureSize.height,
                                     rect.size.width / textureSize.width,
                                     rect.size.height / textureSize.height);
  return LTMatrix3ForRect(normalizedRect);
}

GLKMatrix3 LTMatrix3ForRect(CGRect rect) {
  GLKMatrix3 scale = GLKMatrix3MakeScale(rect.size.width, rect.size.height, 1);
  GLKMatrix3 translate = GLKMatrix3MakeTranslation(rect.origin.x, rect.origin.y);
  return GLKMatrix3Multiply(translate, scale);
}

GLKMatrix4 LTMatrix4ForRect(CGRect rect) {
  GLKMatrix4 scale = GLKMatrix4MakeScale(rect.size.width, rect.size.height, 1);
  GLKMatrix4 translate = GLKMatrix4MakeTranslation(rect.origin.x, rect.origin.y, 0);
  return GLKMatrix4Multiply(translate, scale);
}

#pragma mark -
#pragma mark Rotated rects
#pragma mark -

GLKMatrix3 LTTextureMatrix3ForRotatedRect(LTRotatedRect *rotatedRect, CGSize textureSize) {
  LTRotatedRect *normalizedRect = [LTRotatedRect rectWithCenter:rotatedRect.center / textureSize
                                                           size:rotatedRect.rect.size / textureSize
                                                          angle:rotatedRect.angle];
  return LTMatrix3ForRotatedRect(normalizedRect);
}

GLKMatrix3 LTMatrix3ForRotatedRect(LTRotatedRect *rotatedRect) {
  CGRect rect = rotatedRect.rect;
  GLKMatrix3 scale = GLKMatrix3MakeScale(rect.size.width, rect.size.height, 1);
  GLKMatrix3 translateToCenter = GLKMatrix3MakeTranslation(-rect.size.width / 2,
                                                           -rect.size.height / 2);
  GLKMatrix3 rotate = GLKMatrix3MakeRotation(rotatedRect.angle, 0, 0, 1);
  GLKMatrix3 translate = GLKMatrix3MakeTranslation(rect.origin.x + rect.size.width / 2,
                                                   rect.origin.y + rect.size.height / 2);
  return GLKMatrix3Multiply(translate,
                            GLKMatrix3Multiply(rotate,
                                               GLKMatrix3Multiply(translateToCenter, scale)));
}

GLKMatrix4 LTMatrix4ForRotatedRect(LTRotatedRect *rotatedRect) {
  CGRect rect = rotatedRect.rect;
  GLKMatrix4 scale = GLKMatrix4MakeScale(rect.size.width, rect.size.height, 1);
  GLKMatrix4 translateToCenter = GLKMatrix4MakeTranslation(-rect.size.width / 2,
                                                           -rect.size.height / 2, 0);
  GLKMatrix4 rotate = GLKMatrix4MakeRotation(rotatedRect.angle, 0, 0, 1);
  GLKMatrix4 translate = GLKMatrix4MakeTranslation(rect.origin.x + rect.size.width / 2,
                                                   rect.origin.y + rect.size.height / 2, 0);
  return GLKMatrix4Multiply(translate,
                            GLKMatrix4Multiply(rotate,
                                               GLKMatrix4Multiply(translateToCenter, scale)));
}

