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
  if (self = [super init]) {
    _compressor = $(LTCompressionFormatHEIC).isSupported ?
        [[LTImageHEICCompressor alloc] init] : [[LTImageJPEGCompressor alloc] init];
    _format = _compressor.format;
  }
  return self;
}

- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error {
  return [self.compressor compressImage:image metadata:metadata error:error];
}

@end

NS_ASSUME_NONNULL_END
