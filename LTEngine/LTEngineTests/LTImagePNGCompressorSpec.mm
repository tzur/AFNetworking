// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImagePNGCompressor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static BOOL LTVerifyFormat(NSData *compressedImage) {
  const std::vector<uint8_t> kPNGHeader = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
  const std::vector<uint8_t> header((uint8_t *)compressedImage.bytes,
                                    (uint8_t *)compressedImage.bytes + kPNGHeader.size());
  return kPNGHeader == header;
}

SpecBegin(LTImagePNGCompressor)

__block LTImagePNGCompressor *compressor;
__block NSError *error;

beforeEach(^{
  compressor = [[LTImagePNGCompressor alloc] init];
  error = nil;
});

afterEach(^{
  compressor = nil;
});

it(@"should create png format data", ^{
  UIImage *jpegImage = LTLoadImage([self class], @"Gray.jpg");
  expect(LTVerifyFormat([compressor compressImage:jpegImage metadata:nil error:&error]))
      .to.beTruthy();
  expect(error).to.beNil();
});

SpecEnd
