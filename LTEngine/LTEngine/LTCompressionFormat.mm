// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "LTCompressionFormat.h"

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, LTCompressionFormat,
  LTCompressionFormatJPEG,
  LTCompressionFormatPNG,
  LTCompressionFormatTIFF,
  LTCompressionFormatHEIC
);

@implementation LTCompressionFormat (Properties)

- (NSString *)UTI {
  switch (self.value) {
    case LTCompressionFormatJPEG:
      return (NSString *)kUTTypeJPEG;
    case LTCompressionFormatPNG:
      return (NSString *)kUTTypePNG;
    case LTCompressionFormatTIFF:
      return (NSString *)kUTTypeTIFF;
    case LTCompressionFormatHEIC:
#ifdef __IPHONE_11_0
      if(@available(iOS 11.0, *)){
        return AVFileTypeHEIC;
      }
#endif
      return @"public.heic";
  }
}

- (NSString *)fileExtension {
  switch (self.value) {
    case LTCompressionFormatJPEG:
      return @"jpg";
    case LTCompressionFormatPNG:
      return @"png";
    case LTCompressionFormatTIFF:
      return @"tif";
    case LTCompressionFormatHEIC:
      return @".heic";
  }
}

- (NSString *)mimeType {
  switch (self.value) {
    case LTCompressionFormatJPEG:
      return @"image/jpg";
    case LTCompressionFormatPNG:
      return @"image/png";
    case LTCompressionFormatTIFF:
      return @"image/tiff";
    case LTCompressionFormatHEIC:
      return @"image/heic";
  }
}

- (BOOL)isSupported {
  NSArray<NSString *> *types = CFBridgingRelease(CGImageDestinationCopyTypeIdentifiers());
  return [types containsObject:self.UTI];
}

@end

NS_ASSUME_NONNULL_END
