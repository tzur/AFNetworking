// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageTIFFCompressor.h"

#import <ImageIO/ImageIO.h>

#import "LTCompressionFormat.h"
#import "LTImageIOCompressor.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTImageTIFFCompressor ()

/// Internal ImageIO compressor used for the actual compression.
@property (readonly, nonatomic) LTImageIOCompressor *compressor;

@end

@implementation LTImageTIFFCompressor

- (instancetype)init {
  if (self = [super init]) {
    // NSTIFFCompressionLZW defined in NSBitmapImageRep.h of OSX, and not for iOS. For that reason,
    // we need to put the actual value of the enum. This issue was discussed with the ImageIO
    // development team, which confirmed that it uses libtiff under the hood, and the constant is
    // not likely to change.
    static const NSUInteger kLZWCompression = 5;
    NSDictionary *options = @{
      (__bridge NSString *)kCGImagePropertyTIFFDictionary: @{
        (__bridge NSString *)kCGImagePropertyTIFFCompression: @(kLZWCompression)
      }
    };

    _compressor = [[LTImageIOCompressor alloc] initWithOptions:options format:self.format];
  }
  return self;
}

- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error {
  auto metadataWithoutTiling = [self removeTileEntriesFromMetadata:metadata ?: @{}];
  return [self.compressor compressImage:image metadata:metadataWithoutTiling error:error];
}

- (BOOL)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata toURL:(NSURL *)url
                error:(NSError * __autoreleasing *)error {
  auto metadataWithoutTiling = [self removeTileEntriesFromMetadata:metadata ?: @{}];
  return [self.compressor compressImage:image metadata:metadataWithoutTiling toURL:url error:error];
}

- (NSDictionary *)removeTileEntriesFromMetadata:(NSDictionary *)metadata {
  // TIFF compression with declared tiling in the image metadata leads to unexpected observed
  // behaviours:
  // 1) When exporting the image to Instagram, the image is presented as BGRA.
  // 2) When exporting the image to Mac using Image Capture and then entering the "get info" window
  // of the image file, the preview version of the image in the window is also presented as BGRA.
  //
  // The reason for these behaviours is not certainly known: it might be that the compressor doesn't
  // compress the image correctly with tiling or that some decoding method (used by Instagram or the
  // preview image in Mac) doesn't handle the compress tiled image as it should.
  // The current solution that works in practice is to remove the tiling declaration entries from
  // the \c metadata dictionary.
  NSDictionary * _Nullable tiffDictionary =
      metadata[(__bridge NSString *)kCGImagePropertyTIFFDictionary];

  if (!tiffDictionary) {
    return metadata;
  }

  NSMutableDictionary *mutableTiffDictionary = [tiffDictionary mutableCopy];
  mutableTiffDictionary[(__bridge NSString *)kCGImagePropertyTIFFTileWidth] = nil;
  mutableTiffDictionary[(__bridge NSString *)kCGImagePropertyTIFFTileLength] = nil;
  NSDictionary *tiffDictionaryWithoutTiling = [mutableTiffDictionary copy];

  NSMutableDictionary *mutableMetadata = [metadata mutableCopy];
  mutableMetadata[(__bridge NSString *)kCGImagePropertyTIFFDictionary] =
      tiffDictionaryWithoutTiling;

  return [mutableMetadata copy];
}

- (LTCompressionFormat *)format {
  return $(LTCompressionFormatTIFF);
}

@end

NS_ASSUME_NONNULL_END
