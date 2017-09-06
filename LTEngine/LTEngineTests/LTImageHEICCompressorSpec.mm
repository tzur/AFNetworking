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
__block NSError *error;

beforeEach(^{
  compressor = [[LTImageHEICCompressor alloc] init];
  error = nil;
});

it(@"should return correct format", ^{
  expect(compressor.format).to.equal($(LTCompressionFormatHEIC));
});

it(@"should update properties" , ^{
  expect(compressor.quality).to.equal(1);

  CGFloat quality = 0.5;
  compressor = [[LTImageHEICCompressor alloc] initWithQuality:quality];
  expect(compressor.quality).to.equal(quality);
});

it(@"should clamp quality values", ^{
  compressor.quality = -.1;
  expect(compressor.quality).to.equal(0);

  compressor.quality = 1.1;
  expect(compressor.quality).to.equal(1);
});

// The following tests should run only on HEIC compression supporting devices.
if ($(LTCompressionFormatHEIC).isSupported) {
  dit(@"should create HEVC format data", ^{
    UIImage *image = LTLoadImage([self class], @"Lena.png");
    auto data = [compressor compressImage:image metadata:nil error:&error];
    expect(LTVerifyFormat(data)).to.beTruthy();
    expect(error).to.beNil();
  });

  dit(@"should verify that the quality option affects the output", ^{
    UIImage *image = LTLoadImage([self class], @"Gray.jpg");
    NSData *highestQualityData = [compressor compressImage:image metadata:nil error:&error];
    expect(error).to.beNil();
    error = nil;

    compressor = [[LTImageHEICCompressor alloc] initWithQuality:0.5];
    NSData *lowestQualityData = [compressor compressImage:image metadata:nil error:&error];
    expect(error).to.beNil();

    expect(highestQualityData).notTo.equal(lowestQualityData);
  });
}

SpecEnd
