// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "LTCompressionType.h"

#import <MobileCoreServices/MobileCoreServices.h>

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, LTCompressionType,
  LTCompressionTypeJPEG,
  LTCompressionTypePNG,
  LTCompressionTypeTIFF
);

@implementation LTCompressionType (Properties)

- (NSString *)UTI {
  switch (self.value) {
    case LTCompressionTypeJPEG:
      return (NSString *)kUTTypeJPEG;
    case LTCompressionTypePNG:
      return (NSString *)kUTTypePNG;
    case LTCompressionTypeTIFF:
      return (NSString *)kUTTypeTIFF;
  }
}

- (NSString *)fileExtention {
  switch (self.value) {
    case LTCompressionTypeJPEG:
      return @"jpg";
    case LTCompressionTypePNG:
      return @"png";
    case LTCompressionTypeTIFF:
      return @"tiff";
  }
}

- (NSString *)mimeType {
  switch (self.value) {
    case LTCompressionTypeJPEG:
      return @"image/jpg";
    case LTCompressionTypePNG:
      return @"image/png";
    case LTCompressionTypeTIFF:
      return @"image/tiff";
  }
}

@end

NS_ASSUME_NONNULL_END
