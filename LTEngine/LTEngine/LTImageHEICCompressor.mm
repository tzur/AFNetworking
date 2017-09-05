// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTImageHEICCompressor.h"

#import <ImageIO/ImageIO.h>

#import "LTCompressionFormat.h"
#import "LTImageIOCompressor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTImageHEICCompressor

- (instancetype)init {
  return [self initWithQuality:1];
}

- (instancetype)initWithQuality:(CGFloat)quality {
  if (self = [super init]) {
    self.quality = quality;
  }
  return self;
}

- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error {
  if (!LTIsDeviceSupportsCompressionFormat($(LTCompressionFormatHEIC))) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"HEIC compression isn't suppored on this device"];
    }
    return nil;
  }

  auto options = @{
    (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(self.quality)
  };
  auto compressor = [[LTImageIOCompressor alloc] initWithOptions:options format:self.format];
  return [compressor compressImage:image metadata:metadata error:error];
}

- (LTCompressionFormat *)format {
  return $(LTCompressionFormatHEIC);
}

- (void)setQuality:(CGFloat)quality {
  _quality = MIN(MAX(quality, 0), 1);
}

@end

NS_ASSUME_NONNULL_END
