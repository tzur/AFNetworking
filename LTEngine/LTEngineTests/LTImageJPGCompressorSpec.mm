// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageJPEGCompressor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static BOOL LTVerifyFormat(NSData *compressedImage) {
  const std::vector<uint8_t> kJPEGHeader = {0xFF, 0xD8, 0xFF};
  const std::vector<uint8_t> header((uint8_t *)compressedImage.bytes,
                                    (uint8_t *)compressedImage.bytes + kJPEGHeader.size());
  return kJPEGHeader == header;
}

LTSpecBegin(LTImageJPEGCompressor)

__block LTImageJPEGCompressor *compressor;
__block NSError *error;

beforeEach(^{
  compressor = [[LTImageJPEGCompressor alloc] init];
  error = nil;
});

afterEach(^{
  compressor = nil;
});

it(@"should update properties" , ^{
  expect(compressor.quality).to.equal(compressor.defaultQuality);

  CGFloat quality = 0.5;
  compressor = [[LTImageJPEGCompressor alloc] initWithQuality:quality];
  expect(compressor.quality).to.equal(quality);
});

it(@"should create jpeg format data", ^{
  UIImage *jpegImage = LTLoadImage([self class], @"Gray.jpg");
  expect(LTVerifyFormat([compressor compressImage:jpegImage metadata:nil error:&error]))
      .to.beTruthy();
  expect(error).to.beNil();
});

it(@"should verify that the quality option has effect", ^{
  UIImage *image = LTLoadImage([self class], @"Lena.png");
  NSData *highestQualityData = [compressor compressImage:image metadata:nil error:&error];
  expect(error).to.beNil();
  error = nil;

  compressor = [[LTImageJPEGCompressor alloc] initWithQuality:0];
  NSData *lowestQualityData = [compressor compressImage:image metadata:nil error:&error];
  expect(error).to.beNil();

  expect(highestQualityData).notTo.equal(lowestQualityData);
});

LTSpecEnd
