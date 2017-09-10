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

- (instancetype)init {
  return [self initWithQuality:1];
}

- (instancetype)initWithQuality:(CGFloat)quality {
  LTParameterAssert(quality >= 0 && quality <= 1, @"quality: %g, must be in range [0, 1]", quality);

  if (self = [super init]) {
    _compressor = $(LTCompressionFormatHEIC).isSupported ?
        [[LTImageHEICCompressor alloc] initWithQuality:quality] :
        [[LTImageJPEGCompressor alloc] initWithQuality:quality];
    _format = _compressor.format;
    _quality = quality;
  }
  return self;
}

- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error {
  return [self.compressor compressImage:image metadata:metadata error:error];
}

@end

NS_ASSUME_NONNULL_END
