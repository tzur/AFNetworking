// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "CIContext+PixelFormat.h"

#import "LTGLPixelFormat.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CIContext (PixelFormat)

+ (instancetype)lt_contextWithPixelFormat:(LTGLPixelFormat *)pixelFormat {
  return [self lt_contextWithOptions:@{
    kCIContextWorkingFormat: @([self lt_ciContextWorkingFormatForPixelFormat:pixelFormat]),
    kCIContextWorkingColorSpace: [NSNull null],
    kCIContextOutputColorSpace: [NSNull null]
  }];
}

+ (CIFormat)lt_ciContextWorkingFormatForPixelFormat:(LTGLPixelFormat *)pixelFormat {
  if (pixelFormat.dataType == LTGLPixelDataType8Unorm) {
    return kCIFormatRGBA8;
  } else if (pixelFormat.dataType == LTGLPixelDataType16Float) {
    return kCIFormatRGBAh;
  }

  LTParameterAssert(NO, @"Invalid pixel format: %@", pixelFormat);
}

/// Maps between context options to the context instance.
static NSMutableDictionary<NSDictionary<NSString *, id> *, CIContext *> *mapping;

+ (instancetype)lt_contextWithOptions:(NSDictionary<NSString *, id> *)options {
  @synchronized (self) {
    if (!mapping) {
      mapping = [NSMutableDictionary dictionary];
    }

    CIContext * _Nullable context = mapping[options];
    if (context) {
      return context;
    }

    CIContext *newContext = [CIContext contextWithOptions:options];
    mapping[options] = newContext;
    return newContext;
  }
}

+ (void)lt_clearContextCache {
  @synchronized (self) {
    [mapping removeAllObjects];
  }
}

@end

NS_ASSUME_NONNULL_END
