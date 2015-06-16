// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageTIFFCompressor.h"

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "LTImageIOCompressor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTImageTIFFCompressor

- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error {
  // NSTIFFCompressionLZW defined in NSBitmapImageRep.h of OSX, and not for iOS. For that reason,
  // we need to put the actual value of the enum. This issue was discussed with the ImageIO
  // development team, which confirmed that it uses libtiff under the hood, and the constant is not
  // likely to change.
  static const NSUInteger kLZWCompression = 5;
  NSDictionary *options = @{
    (__bridge NSString *)kCGImagePropertyTIFFDictionary: @{
      (__bridge NSString *)kCGImagePropertyTIFFCompression: @(kLZWCompression)
    }
  };

  LTImageIOCompressor *compressor =
      [[LTImageIOCompressor alloc] initWithOptions:options UTI:kUTTypeTIFF];

  return [compressor compressImage:image metadata:metadata error:error];
}

@end

NS_ASSUME_NONNULL_END
