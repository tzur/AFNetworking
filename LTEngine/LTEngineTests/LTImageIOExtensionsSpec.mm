// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LTImageIOExtensions.h"

#import <LTKit/NSBundle+Path.h>
#import <opencv2/imgcodecs.hpp>

#import "LTImage.h"

static NSString * const kUserComment = @"user comment";
static NSString * const kLensModel = @"iPod touch front camera 2.18mm f/2.4";

static BOOL LTVerifyJPEGFormat(NSData *compressedImage) {
  const std::vector<uint8_t> kJPEGHeader = {0xFF, 0xD8, 0xFF};
  const std::vector<uint8_t> header((uint8_t *)compressedImage.bytes,
                                    (uint8_t *)compressedImage.bytes + kJPEGHeader.size());
  return kJPEGHeader == header;
}

static BOOL LTVerifyPNGFormat(NSData *compressedImage) {
  const std::vector<uint8_t> kPNGHeader = {0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a};
  const std::vector<uint8_t> header((uint8_t *)compressedImage.bytes,
                                    (uint8_t *)compressedImage.bytes + kPNGHeader.size());
  return kPNGHeader == header;
}

static BOOL LTVerifyTIFFFormat(NSData *compressedImage) {
  const std::vector<uint8_t> kTiffHeader1 = {0x49, 0x49, 0x2A, 0x00};
  const std::vector<uint8_t> kTiffHeader2 = {0x4D, 0x4D, 0x00, 0x2A};
  const std::vector<uint8_t> header((uint8_t *)compressedImage.bytes,
                                    (uint8_t *)compressedImage.bytes + kTiffHeader1.size());
  return (kTiffHeader1 == header) || (kTiffHeader2 == header);
}

static BOOL LTVerifyMetadata(NSData *compressedImage) {
  lt::Ref<CGImageSourceRef> source(
    CGImageSourceCreateWithData((__bridge CFDataRef)compressedImage, NULL)
  );
  if (!source) {
    return NO;
  }

  CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source.get(), 0, NULL);
  if (!properties) {
    return NO;
  }

  NSDictionary *imageMetadata = CFBridgingRelease(properties);
  NSDictionary *exifData =
      imageMetadata[(__bridge NSString *)kCGImagePropertyExifDictionary];
  NSString *userComment = exifData[(__bridge NSString *)kCGImagePropertyExifUserComment];
  NSString *lensModel = exifData[(__bridge NSString *)kCGImagePropertyExifLensModel];

  return [kUserComment isEqualToString:userComment] && [kLensModel isEqualToString:lensModel];
}

SpecBegin(LTImageIOExtensions)

__block cv::Mat imageRGBA;
__block cv::Mat imageBGR;
__block NSDictionary *metadata;

beforeEach(^{
  imageRGBA = cv::Mat4b(5, 5, cv::Vec4b(192, 128, 64, 255));
  cv::cvtColor(imageRGBA, imageBGR, cv::COLOR_RGBA2BGR);
  metadata = @{
    (__bridge NSString *)kCGImagePropertyExifDictionary: @{
      (__bridge NSString *)kCGImagePropertyExifUserComment: kUserComment,
      (__bridge NSString *)kCGImagePropertyExifLensModel: kLensModel
    }
  };
});

context(@"combining to data", ^{
  it(@"should save correct image and metadata when combining jpeg image data with metadata", ^{
    std::vector<uchar> jpegBuffer;
    cv::imencode(".jpg", imageBGR, jpegBuffer);
    auto jpegData = [NSData dataWithBytesNoCopy:jpegBuffer.data() length:jpegBuffer.size()
                                   freeWhenDone:NO];
    NSError *error;
    auto combinedJpegData = LTCombineImageWithMetadata(jpegData, metadata, &error);

    expect(error).to.beNil();
    expect(LTVerifyJPEGFormat(combinedJpegData)).to.beTruthy();
    expect(LTVerifyMetadata(combinedJpegData)).to.beTruthy();

    auto compressedImage = [[LTImage alloc]
                            initWithImage:[UIImage imageWithData:combinedJpegData]];

    expect($(compressedImage.mat)).to.beCloseToMatWithin($(imageRGBA), 2);
  });

  it(@"should save correct image and metadata when combining png image data with metadata", ^{
    std::vector<uchar> pngBuffer;
    cv::imencode(".png", imageBGR, pngBuffer);
    auto pngData = [NSData dataWithBytesNoCopy:pngBuffer.data() length:pngBuffer.size()
                                  freeWhenDone:NO];
    NSError *error;
    auto combinedPngData = LTCombineImageWithMetadata(pngData, metadata, &error);

    expect(error).to.beNil();
    expect(LTVerifyPNGFormat(combinedPngData)).to.beTruthy();
    expect(LTVerifyMetadata(combinedPngData)).to.beTruthy();

    auto compressedImage = [[LTImage alloc] initWithImage:[UIImage imageWithData:combinedPngData]];

    expect($(compressedImage.mat)).to.beCloseToMatWithin($(imageRGBA), 2);
  });

  it(@"should save correct image and metadata when combining tiff image data with metadata", ^{
    NSBundle *bundle = NSBundle.lt_testBundle;
    NSString *path = [bundle lt_pathForResource:@"Flower.tiff"];

    auto originalData = [[NSFileManager defaultManager] contentsAtPath:path];
    auto originalImage = [[LTImage alloc] initWithImage:[UIImage imageWithData:originalData]];

    NSError *error;
    NSData *combinedData = LTCombineImageWithMetadata(originalData, metadata, &error);

    expect(error).to.beNil();
    expect(LTVerifyTIFFFormat(combinedData)).to.beTruthy();
    expect(LTVerifyMetadata(combinedData)).to.beTruthy();

    auto combinedImage = [[LTImage alloc] initWithImage:[UIImage imageWithData:combinedData]];

    expect($(combinedImage.mat)).to.beCloseToMat($(originalImage.mat));
  });
});

context(@"combining to a file", ^{
  __block NSURL *url;

  beforeEach(^{
    url = [NSURL fileURLWithPath:LTTemporaryPath(@"temp.jpg")];
  });

  it(@"should combine successfully to a file", ^{
    NSError *error;
    std::vector<uchar> jpegBuffer;
    cv::imencode(".jpg", imageBGR, jpegBuffer);
    auto jpegData = [NSData dataWithBytesNoCopy:jpegBuffer.data() length:jpegBuffer.size()
                                   freeWhenDone:NO];

    auto combined = LTCombineImageWithMetadataAndSavetoURL(jpegData, metadata, url, &error);

    expect(error).to.beNil();
    expect(combined).to.beTruthy();
  });

  it(@"should combine same data to file as to in memory data", ^{
    std::vector<uchar> jpegBuffer;
    cv::imencode(".jpg", imageBGR, jpegBuffer);
    NSData *jpegData = [NSData dataWithBytesNoCopy:jpegBuffer.data() length:jpegBuffer.size()
                                      freeWhenDone:NO];

    auto combined = LTCombineImageWithMetadataAndSavetoURL(jpegData, metadata, url, nil);
    auto expectedData = LTCombineImageWithMetadata(jpegData, metadata, nil);
    auto actualData = [NSData dataWithContentsOfURL:url];

    expect(combined).to.beTruthy();
    expect(expectedData).notTo.beNil();
    expect(expectedData).to.equal(actualData);
  });
});

SpecEnd
