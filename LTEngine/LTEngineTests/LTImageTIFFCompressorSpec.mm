// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageTIFFCompressor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static BOOL LTVerifyFormat(NSData *compressedImage) {
  const std::vector<uint8_t> kTIFFIIHeader = {'I','I', 0x2A, 0x00};
  const std::vector<uint8_t> kTIFFMMHeader = {'M','M', 0x00, 0x2A};
  const std::vector<uint8_t> header((uint8_t *)compressedImage.bytes,
                                    (uint8_t *)compressedImage.bytes + kTIFFIIHeader.size());
  return kTIFFIIHeader == header || kTIFFMMHeader == header;
}

SpecBegin(LTImageTIFFCompressor)

__block LTImageTIFFCompressor *compressor;
__block NSError *error;

beforeEach(^{
  compressor = [[LTImageTIFFCompressor alloc] init];
  error = nil;
});

afterEach(^{
  compressor = nil;
});

it(@"should create tiff format data", ^{
  UIImage *jpegImage = LTLoadImage([self class], @"Gray.jpg");
  expect(LTVerifyFormat([compressor compressImage:jpegImage metadata:nil error:&error]))
      .to.beTruthy();
  expect(error).to.beNil();
});

SpecEnd
