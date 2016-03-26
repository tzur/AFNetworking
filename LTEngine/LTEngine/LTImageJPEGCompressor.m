// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageJPEGCompressor.h"

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "LTImageIOCompressor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTImageJPEGCompressor

- (instancetype)init {
  return [self initWithQuality:self.defaultQuality];
}

- (instancetype)initWithQuality:(CGFloat)quality {
  if (self = [super init]) {
    self.quality = quality;
  }
  return self;
}

- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error {
  NSDictionary *options = @{
    (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(self.quality)
  };

  LTImageIOCompressor *compressor =
      [[LTImageIOCompressor alloc] initWithOptions:options UTI:kUTTypeJPEG];
  
  return [compressor compressImage:image metadata:metadata error:error];
}

LTProperty(CGFloat, quality, Quality, 0, 1, 1);

@end

NS_ASSUME_NONNULL_END
