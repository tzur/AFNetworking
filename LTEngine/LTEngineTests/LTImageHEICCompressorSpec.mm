// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTImageHEICCompressor.h"

#import "LTCompressionFormat.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static BOOL LTVerifyFormat(NSData *imageData) {
  // HEIC image header starts with 'ftypheic' from the 5th byte. For reference implementation see:
  // https://github.com/nokiatech/heif/blob/master/Srcs/reader/hevcimagefilereader.cpp#L1038
  uint8_t *headerStart = (uint8_t *)imageData.bytes + 4;
  const std::vector<uint8_t> kHeader = {0x66, 0x74, 0x79, 0x70, 0x68};
  const std::vector<uint8_t> header(headerStart, headerStart + kHeader.size());
  return kHeader == header;
}

NS_CLASS_AVAILABLE_IOS(11_0) SpecBegin(LTImageHEICCompressor)

__block LTImageHEICCompressor *compressor;

beforeEach(^{
  compressor = [[LTImageHEICCompressor alloc] initWithQuality:1];
});

it(@"should return correct format", ^{
  expect(compressor.format).to.equal($(LTCompressionFormatHEIC));
});

it(@"should set quality property" , ^{
  expect(compressor.quality).to.equal(1);
});

it(@"should clamp quality value", ^{
  auto qualityBelowCompressor = [[LTImageHEICCompressor alloc] initWithQuality:-1];
  auto qualityAboveCompressor = [[LTImageHEICCompressor alloc] initWithQuality:2];

  expect(qualityBelowCompressor.quality).to.equal(0);
  expect(qualityAboveCompressor.quality).to.equal(1);
});

// The following tests should run only on HEIC compression supporting devices.
if ($(LTCompressionFormatHEIC).isSupported) {
  it(@"should create HEVC format data", ^{
    UIImage *image = LTLoadImage([self class], @"Lena.png");

    NSError *error;
    NSData *data = [compressor compressImage:image metadata:nil error:&error];

    expect(LTVerifyFormat(data)).to.beTruthy();
    expect(error).to.beNil();
  });

  it(@"should verify that the quality option affects the output", ^{
    UIImage *image = LTLoadImage([self class], @"Gray.jpg");

    NSError *error;
    NSData *highQualityData = [compressor compressImage:image metadata:nil error:&error];
    expect(error).to.beNil();

    LTImageHEICCompressor *lowQualityCompressor =
        [[LTImageHEICCompressor alloc] initWithQuality:0.5];
    NSData *lowQualityData = [lowQualityCompressor compressImage:image metadata:nil error:&error];

    expect(error).to.beNil();
    expect(highQualityData).notTo.equal(lowQualityData);
  });

  it(@"should compress same data to file as to in memory data", ^{
    UIImage *image = LTLoadImage([self class], @"Lena.png");
    auto url = [NSURL fileURLWithPath:LTTemporaryPath(@"temp.heic")];

    NSError *error;
    auto compressed = [compressor compressImage:image metadata:nil toURL:url error:&error];
    auto expectedData = [compressor compressImage:image metadata:nil error:nil];
    auto actualData = [NSData dataWithContentsOfURL:url];

    expect(compressed).to.beTruthy();
    expect(error).to.beNil();
    expect(expectedData).notTo.beNil();
    expect(expectedData).to.equal(actualData);
  });
}

SpecEnd
