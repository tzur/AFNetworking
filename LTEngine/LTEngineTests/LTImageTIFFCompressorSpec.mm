// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageTIFFCompressor.h"

#import <LTKit/LTRef.h>

#import "LTCompressionFormat.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static BOOL LTVerifyFormat(NSData *compressedImage) {
  const std::vector<uint8_t> kTIFFIIHeader = {'I','I', 0x2A, 0x00};
  const std::vector<uint8_t> kTIFFMMHeader = {'M','M', 0x00, 0x2A};
  const std::vector<uint8_t> header((uint8_t *)compressedImage.bytes,
                                    (uint8_t *)compressedImage.bytes + kTIFFIIHeader.size());
  return kTIFFIIHeader == header || kTIFFMMHeader == header;
}

static NSDictionary *LTGetMetadataFromImageData(NSData *imageData) {
  lt::Ref<CGImageSourceRef> sourceRef(CGImageSourceCreateWithData((__bridge CFDataRef)imageData,
                                                                  NULL));
  LTAssert(sourceRef.get(), @"Failed to create an image source from the given image data");

  CFDictionaryRef propertiesRef = CGImageSourceCopyPropertiesAtIndex(sourceRef.get(), 0, NULL);
  LTAssert(propertiesRef, @"Failed to fetch properties from the given image source");

  return CFBridgingRelease(propertiesRef);
}

static NSDictionary *LTAddTileEnriesToMetadata(NSDictionary *metadata) {
  NSMutableDictionary *mutableTiffDictionary =
      [(metadata[(__bridge NSString *)kCGImagePropertyTIFFDictionary] ?: @{}) mutableCopy];
  mutableTiffDictionary[(__bridge NSString *)kCGImagePropertyTIFFTileWidth] = @4;
  mutableTiffDictionary[(__bridge NSString *)kCGImagePropertyTIFFTileLength] = @4;

  NSMutableDictionary *mutableMetadata = [metadata mutableCopy];
  mutableMetadata[(__bridge NSString *)kCGImagePropertyTIFFDictionary] =
      [mutableTiffDictionary copy];
  return [mutableMetadata copy];
}

SpecBegin(LTImageTIFFCompressor)

__block UIImage *image;
__block LTImageTIFFCompressor *compressor;
__block NSError *error;

beforeEach(^{
  image = LTLoadImage([self class], @"Lena128.png");
  compressor = [[LTImageTIFFCompressor alloc] init];
  error = nil;
});

afterEach(^{
  compressor = nil;
});

it(@"should return correct format", ^{
  expect(compressor.format).to.equal($(LTCompressionFormatTIFF));
});

it(@"should create tiff format data", ^{
  expect(LTVerifyFormat([compressor compressImage:image metadata:nil error:&error]))
      .to.beTruthy();
  expect(error).to.beNil();
});

it(@"should remove tile entries from input metadata", ^{
  NSDictionary *inputMetadata = LTGetMetadataFromImageData(UIImagePNGRepresentation(image));
  NSDictionary *inputMetadataWithTiling = LTAddTileEnriesToMetadata(inputMetadata);

  auto _Nullable outputImageData = [compressor compressImage:image metadata:inputMetadataWithTiling
                                                       error:nil];
  expect(outputImageData).notTo.beNil();
  NSDictionary *outputMetadata = LTGetMetadataFromImageData(outputImageData);
  expect(outputMetadata[(__bridge NSString *)kCGImagePropertyTIFFDictionary]
         [(__bridge NSString *)kCGImagePropertyTIFFTileWidth]).to.beNil();
  expect(outputMetadata[(__bridge NSString *)kCGImagePropertyTIFFDictionary]
         [(__bridge NSString *)kCGImagePropertyTIFFTileLength]).to.beNil();
});

SpecEnd
