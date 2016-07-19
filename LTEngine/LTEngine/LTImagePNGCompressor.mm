// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImagePNGCompressor.h"

#import "LTCompressionFormat.h"
#import "LTImageIOCompressor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTImagePNGCompressor

- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error {
  LTImageIOCompressor *compressor = [[LTImageIOCompressor alloc] initWithOptions:nil
                                                                          format:self.format];
  return [compressor compressImage:image metadata:metadata error:error];
}

- (LTCompressionFormat *)format {
  return $(LTCompressionFormatPNG);
}

@end

NS_ASSUME_NONNULL_END
