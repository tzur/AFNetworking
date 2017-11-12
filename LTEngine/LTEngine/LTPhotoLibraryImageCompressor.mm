// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTPhotoLibraryImageCompressor.h"

#import "LTCompressionFormat.h"
#import "LTImageHEICCompressor.h"
#import "LTImageJPEGCompressor.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTPhotoLibraryImageCompressor ()

/// Selected compressor to use.
@property (readonly, nonatomic) id<LTImageCompressor> compressor;

@end

@implementation LTPhotoLibraryImageCompressor

@synthesize format = _format;

- (instancetype)initWithQuality:(CGFloat)quality {
  if (self = [super init]) {
    _quality = MIN(MAX(quality, 0), 1);

    [self setupCompressor];
    _format = _compressor.format;
  }
  return self;
}

- (void)setupCompressor {
  if (@available(iOS 11.0, *)) {
    _compressor = $(LTCompressionFormatHEIC).isSupported ?
        [[LTImageHEICCompressor alloc] initWithQuality:self.quality] :
        [[LTImageJPEGCompressor alloc] initWithQuality:self.quality];
  } else {
    _compressor = [[LTImageJPEGCompressor alloc] initWithQuality:self.quality];
  }
}

- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error {
  return [self.compressor compressImage:image metadata:metadata error:error];
}

- (BOOL)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata toURL:(NSURL *)url
                error:(NSError *__autoreleasing *)error {
  return [self.compressor compressImage:image metadata:metadata toURL:url error:error];
}

@end

NS_ASSUME_NONNULL_END
