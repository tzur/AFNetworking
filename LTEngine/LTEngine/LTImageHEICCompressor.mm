// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTImageHEICCompressor.h"

#import <ImageIO/ImageIO.h>

#import "LTCompressionFormat.h"
#import "LTImageIOCompressor.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTImageHEICCompressor ()

/// Internal ImageIO compressor used for the actual compression.
@property (readonly, nonatomic, nullable) LTImageIOCompressor *compressor;

@end

@implementation LTImageHEICCompressor

- (instancetype)initWithQuality:(CGFloat)quality {
  if (self = [super init]) {
    _quality = MIN(MAX(quality, 0), 1);

    [self setupCompressor];
  }
  return self;
}

- (void)setupCompressor {
  if (!$(LTCompressionFormatHEIC).isSupported) {
    return;
  }

  _compressor = [[LTImageIOCompressor alloc] initWithOptions:@{
    (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(self.quality)
  } format:self.format];
}

- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error {
  if (!self.compressor) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"HEIC compression isn't suppored on this device"];
    }
    return nil;
  }

  return [self.compressor compressImage:image metadata:metadata error:error];
}

- (BOOL)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata toURL:(NSURL *)url
                error:(NSError *__autoreleasing *)error {
  if (!self.compressor) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                                     url:url
                             description:@"HEIC compression isn't suppored on this device"];
    }
    return NO;
  }

  return [self.compressor compressImage:image metadata:metadata toURL:url error:error];
}

- (LTCompressionFormat *)format {
  return $(LTCompressionFormatHEIC);
}

- (void)setQuality:(CGFloat)quality {
  _quality = MIN(MAX(quality, 0), 1);
}

@end

NS_ASSUME_NONNULL_END
