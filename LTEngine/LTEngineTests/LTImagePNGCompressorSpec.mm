// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImagePNGCompressor.h"

#import "LTCompressionFormat.h"
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

beforeEach(^{
  compressor = [[LTImagePNGCompressor alloc] init];
});

afterEach(^{
  compressor = nil;
});

it(@"should return correct format", ^{
  expect(compressor.format).to.equal($(LTCompressionFormatPNG));
});

it(@"should create png format data", ^{
  UIImage *jpegImage = LTLoadImage([self class], @"Gray.jpg");

  NSError *error;
  NSData *data = [compressor compressImage:jpegImage metadata:nil error:&error];

  expect(LTVerifyFormat(data)).to.beTruthy();
  expect(error).to.beNil();
});

it(@"should compress same data to file as to in memory data", ^{
  LTCreateTemporaryDirectory();

  UIImage *image = LTLoadImage([self class], @"Lena.png");
  auto url = [NSURL fileURLWithPath:LTTemporaryPath(@"temp.png")];

  NSError *error;
  auto compressed = [compressor compressImage:image metadata:nil toURL:url error:&error];
  auto expectedData = [compressor compressImage:image metadata:nil error:nil];
  auto actualData = [NSData dataWithContentsOfURL:url];

  expect(compressed).to.beTruthy();
  expect(error).to.beNil();
  expect(expectedData).notTo.beNil();
  expect(expectedData).to.equal(actualData);

  [[NSFileManager defaultManager] removeItemAtPath:LTTemporaryPath() error:nil];
});

SpecEnd
