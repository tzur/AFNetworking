// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageIOCompressor.h"

#import <ImageIO/ImageIO.h>
#import <LTKit/LTCFExtensions.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static BOOL LTVerifyFormat(NSData *compressedImage) {
  const std::vector<uint8_t> kJPEGHeader = {0xFF, 0xD8, 0xFF};
  const std::vector<uint8_t> header((uint8_t *)compressedImage.bytes,
                                    (uint8_t *)compressedImage.bytes + kJPEGHeader.size());
  return kJPEGHeader == header;
}

static NSDictionary *LTGetMetadata(NSData *compressedImage) {
  __block CGImageSourceRef sourceRef =
      CGImageSourceCreateWithData((__bridge CFDataRef)compressedImage, NULL);
  @onExit {
    LTCFSafeRelease(sourceRef);
  };

  if (!sourceRef) {
    return nil;
  }

  CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
  if (!properties) {
    return nil;
  }

  return CFBridgingRelease(properties);
}

LTSpecBegin(LTImageIOCompressor)

__block LTImageIOCompressor *compressor;
__block NSError *error;

beforeEach(^{
  compressor = [[LTImageIOCompressor alloc] initWithOptions:nil UTI:kUTTypeJPEG];
  error = nil;
});

it(@"should create jpeg format data from texture", ^{
  cv::Mat4b imageMat(5, 5, cv::Vec4b(192, 128, 64, 255));
  UIImage *uiImage = [[LTImage alloc] initWithMat:imageMat copy:YES].UIImage;

  expect(LTVerifyFormat([compressor compressImage:uiImage metadata:nil error:&error]))
      .to.beTruthy();
  expect(error).to.beNil();
});

it(@"should create png format data from jpeg", ^{
  UIImage *jpegImage = LTLoadImage([self class], @"Gray.jpg");
  expect(LTVerifyFormat([compressor compressImage:jpegImage metadata:nil error:&error]))
      .to.beTruthy();
  expect(error).to.beNil();
});

it(@"should create png format data from png", ^{
  UIImage *jpegImage = LTLoadImage([self class], @"Lena.png");
  expect(LTVerifyFormat([compressor compressImage:jpegImage metadata:nil error:&error]))
      .to.beTruthy();
  expect(error).to.beNil();
});

it(@"should create png format data from tiff", ^{
  UIImage *tiffImage = LTLoadImage([self class], @"ImageCompressorInput.tiff");
  expect(LTVerifyFormat([compressor compressImage:tiffImage metadata:nil error:&error]))
      .to.beTruthy();
  expect(error).to.beNil();
});

it(@"should verify options are passed by checking setting the quality option", ^{
  UIImage *image = LTLoadImage([self class], @"Lena.png");
  NSDictionary *options = @{
    (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @1
  };
  LTImageIOCompressor *compressor =
      [[LTImageIOCompressor alloc] initWithOptions:options UTI:kUTTypeJPEG];
  NSData *highQualityData = [compressor compressImage:image metadata:nil error:&error];
  expect(error).to.beNil();

  options = @{
    (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @0.5
  };
  compressor = [[LTImageIOCompressor alloc] initWithOptions:options UTI:kUTTypeJPEG];
  NSData *lowQualityData = [compressor compressImage:image metadata:nil error:&error];

  expect(error).to.beNil();
  expect(highQualityData).notTo.equal(lowQualityData);
});

static const NSString * kUserComment = @"user comment";
static const NSString * kLensModel = @"iPod touch front camera 2.18mm f/2.4";

it(@"should add metadata", ^{
  UIImage *image = LTLoadImage([self class], @"Lena.png");
  NSDictionary *metadata = @{(__bridge NSString *)kCGImagePropertyExifDictionary: @{
    (__bridge NSString *)kCGImagePropertyExifUserComment: kUserComment,
    (__bridge NSString *)kCGImagePropertyExifLensModel: kLensModel
  }};

  LTImageIOCompressor *compressor =
      [[LTImageIOCompressor alloc] initWithOptions:nil UTI:kUTTypeJPEG];
  NSData *imageData = [compressor compressImage:image metadata:metadata error:&error];
  NSDictionary *uncompressedMetadata = LTGetMetadata(imageData);
  NSDictionary *exifData =
      uncompressedMetadata[(__bridge NSString *)kCGImagePropertyExifDictionary];

  expect(error).to.beNil();
  expect(exifData[(__bridge NSString *)kCGImagePropertyExifUserComment]).to.equal(kUserComment);
  expect(exifData[(__bridge NSString *)kCGImagePropertyExifLensModel]).to.equal(kLensModel);
});

it(@"should verify options and metadata are merged correctly by checking the final metadata", ^{
  UIImage *image = LTLoadImage([self class], @"Lena.png");
  NSDictionary *options = @{(__bridge NSString *)kCGImagePropertyExifDictionary: @{
    (__bridge NSString *)kCGImagePropertyExifUserComment: kUserComment,
  }};
  NSDictionary *metadata = @{(__bridge NSString *)kCGImagePropertyExifDictionary: @{
    (__bridge NSString *)kCGImagePropertyExifLensModel: kLensModel
  }};

  LTImageIOCompressor *compressor =
      [[LTImageIOCompressor alloc] initWithOptions:options UTI:kUTTypeJPEG];
  NSData *imageData = [compressor compressImage:image metadata:metadata error:&error];
  NSDictionary *uncompressedMetadata = LTGetMetadata(imageData);
  NSDictionary *exifData =
      uncompressedMetadata[(__bridge NSString *)kCGImagePropertyExifDictionary];

  expect(error).to.beNil();
  expect(exifData[(__bridge NSString *)kCGImagePropertyExifUserComment]).to.equal(kUserComment);
  expect(exifData[(__bridge NSString *)kCGImagePropertyExifLensModel]).to.equal(kLensModel);
});

it(@"should create valid data from non-contiguous texture", ^{
  cv::Mat4b imageMat(10, 10);
  imageMat(cv::Rect(0, 0, 10, 5)) = cv::Vec4b(0, 0, 0, 255);
  imageMat(cv::Rect(0, 5, 10, 5)) = cv::Vec4b(255, 255, 255, 255);
  cv::Mat4b nonContiguousImageMat = imageMat(cv::Rect(2, 2, 5, 5));

  LTImageIOCompressor *compressor =
      [[LTImageIOCompressor alloc] initWithOptions:nil UTI:kUTTypeJPEG];

  UIImage *image = [[LTImage alloc] initWithMat:nonContiguousImageMat copy:YES].UIImage;
  NSData *imageData = [compressor compressImage:image metadata:nil error:&error];
  LTImage *compressedImage = [[LTImage alloc] initWithImage:[UIImage imageWithData:imageData]];
  expect($(compressedImage.mat)).to.beCloseToMatWithin($(nonContiguousImageMat), 2);
  expect(error).to.beNil();
});

LTSpecEnd
