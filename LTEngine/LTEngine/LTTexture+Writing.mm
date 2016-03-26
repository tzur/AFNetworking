// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture+Writing.h"

#import "LTTexture+Protected.h"

@implementation LTTexture (Writing)

- (void)writeToAttachmentWithBlock:(LTVoidBlock)block {
  LTParameterAssert(block);
  [self beginWritingWithGPU];
  block();
  [self endWritingWithGPU];
}

- (void)clearAttachmentWithColor:(LTVector4)color block:(LTVoidBlock)block {
  [self writeToAttachmentWithBlock:block];

  // Not a mipmap - fill color applies to the entire texture.
  if (!self.maxMipmapLevel) {
    self.fillColor = color;
    return;
  }

  // Mipmap - unset fill color if one of the levels were cleared with a different color than the
  // current fill color.
  if (self.fillColor != color) {
    self.fillColor = LTVector4::null();
  }
}

- (void)beginWritingWithGPU {
  LTMethodNotImplemented();
}

- (void)endWritingWithGPU {
  LTMethodNotImplemented();
}

@end
