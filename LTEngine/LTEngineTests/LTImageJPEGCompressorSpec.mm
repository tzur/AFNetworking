// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageJPEGCompressor.h"

#import "LTCompressionFormat.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static BOOL LTVerifyFormat(NSData *compressedImage) {
  const std::vector<uint8_t> kJPEGHeader = {0xFF, 0xD8, 0xFF};
  const std::vector<uint8_t> header((uint8_t *)compressedImage.bytes,
                                    (uint8_t *)compressedImage.bytes + kJPEGHeader.size());
  return kJPEGHeader == header;
}

SpecBegin(LTImageJPEGCompressor)

__block LTImageJPEGCompressor *compressor;

beforeEach(^{
  compressor = [[LTImageJPEGCompressor alloc] initWithQuality:1];
});

afterEach(^{
  compressor = nil;
});

it(@"should return correct format", ^{
  expect(compressor.format).to.equal($(LTCompressionFormatJPEG));
});

it(@"should clamp quality value", ^{
  auto qualityBelowCompressor = [[LTImageJPEGCompressor alloc] initWithQuality:-1];
  auto qualityAboveCompressor = [[LTImageJPEGCompressor alloc] initWithQuality:2];

  expect(qualityBelowCompressor.quality).to.equal(0);
  expect(qualityAboveCompressor.quality).to.equal(1);
});

it(@"should create jpeg format data", ^{
  UIImage *jpegImage = LTLoadImage([self class], @"Gray.jpg");

  NSError *error;
  NSData *data = [compressor compressImage:jpegImage metadata:nil error:&error];

  expect(LTVerifyFormat(data)).to.beTruthy();
  expect(error).to.beNil();
});

it(@"should change output when using different quality value", ^{
  UIImage *image = LTLoadImage([self class], @"Lena.png");

  NSData *highQualityData = [compressor compressImage:image metadata:nil error:nil];
  expect(highQualityData).notTo.beNil();

  LTImageJPEGCompressor *otherCompressor = [[LTImageJPEGCompressor alloc] initWithQuality:0];
  NSData *lowQualityData = [otherCompressor compressImage:image metadata:nil error:nil];
  expect(lowQualityData).notTo.beNil();

  expect(highQualityData).notTo.equal(lowQualityData);
});

it(@"should compress same data to file as to in memory data", ^{
  UIImage *image = LTLoadImage([self class], @"Lena.png");
  auto url = [NSURL fileURLWithPath:LTTemporaryPath(@"temp.jpg")];

  NSError *error;
  auto compressed = [compressor compressImage:image metadata:nil toURL:url error:&error];
  auto expectedData = [compressor compressImage:image metadata:nil error:nil];
  auto actualData = [NSData dataWithContentsOfURL:url];

  expect(compressed).to.beTruthy();
  expect(error).to.beNil();
  expect(expectedData).notTo.beNil();
  expect(expectedData).to.equal(actualData);
});

SpecEnd
