// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "LTCompressionFormat.h"

#import <AVFoundation/AVMediaFormat.h>
#import <MobileCoreServices/MobileCoreServices.h>

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, LTCompressionFormat,
  LTCompressionFormatJPEG,
  LTCompressionFormatPNG,
  LTCompressionFormatTIFF,
  LTCompressionFormatHEVC
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
    case LTCompressionFormatHEVC:
      return AVFileTypeHEIC;
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
    case LTCompressionFormatHEVC:
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
    case LTCompressionFormatHEVC:
      return @"image/heic";
  }
}

@end

NS_ASSUME_NONNULL_END
