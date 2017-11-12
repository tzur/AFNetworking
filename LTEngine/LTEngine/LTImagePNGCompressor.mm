// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImagePNGCompressor.h"

#import "LTCompressionFormat.h"
#import "LTImageIOCompressor.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTImagePNGCompressor ()

/// Internal ImageIO compressor used for the actual compression.
@property (readonly, nonatomic) LTImageIOCompressor *compressor;

@end

@implementation LTImagePNGCompressor

- (instancetype)init {
  if (self = [super init]) {
    _compressor = [[LTImageIOCompressor alloc] initWithOptions:nil format:self.format];
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
  return $(LTCompressionFormatPNG);
}

@end

NS_ASSUME_NONNULL_END
