// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "CIContext+PixelFormat.h"

#import "LTGLPixelFormat.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CIContext (PixelFormat)

+ (instancetype)lt_contextWithPixelFormat:(LTGLPixelFormat *)pixelFormat {
  return [CIContext contextWithOptions:@{
    kCIContextWorkingFormat: @([self lt_ciContextWorkingFormatForPixelFormat:pixelFormat]),
    kCIContextWorkingColorSpace: [NSNull null],
    kCIContextOutputColorSpace: [NSNull null]
  }];
}

+ (CIFormat)lt_ciContextWorkingFormatForPixelFormat:(LTGLPixelFormat *)pixelFormat {
  if (pixelFormat.bitDepth == LTGLPixelBitDepth8 &&
      pixelFormat.dataType == LTGLPixelDataTypeUnorm) {
    return kCIFormatRGBA8;
  } else if (pixelFormat.bitDepth == LTGLPixelBitDepth16 &&
             pixelFormat.dataType == LTGLPixelDataTypeFloat) {
    return kCIFormatRGBAh;
  }

  LTParameterAssert(NO, @"Invalid pixel format: %@", pixelFormat);
}

@end

NS_ASSUME_NONNULL_END
