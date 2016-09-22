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
  if (pixelFormat.bitDepth == LTGLPixelBitDepth8 &&
      pixelFormat.dataType == LTGLPixelDataTypeUnorm) {
    return kCIFormatRGBA8;
  } else if (pixelFormat.bitDepth == LTGLPixelBitDepth16 &&
             pixelFormat.dataType == LTGLPixelDataTypeFloat) {
    return kCIFormatRGBAh;
  }

  LTParameterAssert(NO, @"Invalid pixel format: %@", pixelFormat);
}

/// Thread-specific \c CIContext key.
static NSString * const kCIContextMappingKey = @"com.lightricks.LTEngine.CIContextMappingKey";

+ (instancetype)lt_contextWithOptions:(NSDictionary<NSString *, id> *)options {
  typedef NSMutableDictionary<NSDictionary<NSString *, id> *, CIContext *> LTCIContextMapping;

  LTCIContextMapping *mapping = [[NSThread currentThread] threadDictionary][kCIContextMappingKey] ?:
      [NSMutableDictionary dictionary];
  CIContext * _Nullable context = mapping[options];
  if (context) {
    return context;
  }

  CIContext *newContext = [CIContext contextWithOptions:options];
  mapping[options] = newContext;
  [[NSThread currentThread] threadDictionary][kCIContextMappingKey] = mapping;

  return newContext;
}

+ (void)lt_cleanContextCache {
  [[[NSThread currentThread] threadDictionary] removeObjectForKey:kCIContextMappingKey];
}

@end

NS_ASSUME_NONNULL_END
