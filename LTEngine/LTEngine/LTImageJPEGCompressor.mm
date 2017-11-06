// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageJPEGCompressor.h"

#import <ImageIO/ImageIO.h>

#import "LTCompressionFormat.h"
#import "LTImageIOCompressor.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTImageJPEGCompressor ()

/// Internal ImageIO compressor used for the actual compression.
@property (readonly, nonatomic) LTImageIOCompressor *compressor;

@end

@implementation LTImageJPEGCompressor

- (instancetype)initWithQuality:(CGFloat)quality {
  if (self = [super init]) {
    _quality = MIN(MAX(quality, 0), 1);
    _compressor = [[LTImageIOCompressor alloc] initWithOptions:@{
      (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(self.quality)
    } format:self.format];
  }
  return self;
}

- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error {
  return [self.compressor compressImage:image metadata:metadata error:error];
}

- (BOOL)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata toURL:(NSURL *)url
                error:(NSError *__autoreleasing *)error {
  return [self.compressor compressImage:image metadata:metadata toURL:url error:error];
}

- (LTCompressionFormat *)format {
  return $(LTCompressionFormatJPEG);
}

@end

NS_ASSUME_NONNULL_END
