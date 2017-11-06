// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageIOCompressor.h"

#import <ImageIO/ImageIO.h>

#import "LTCompressionFormat.h"
#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"
#import "UIImage+Factory.h"

static BOOL LTVerifyFormat(NSData *compressedImage) {
  const std::vector<uint8_t> kJPEGHeader = {0xFF, 0xD8, 0xFF};
  const std::vector<uint8_t> header((uint8_t *)compressedImage.bytes,
                                    (uint8_t *)compressedImage.bytes + kJPEGHeader.size());
  return kJPEGHeader == header;
}

static NSDictionary *LTGetMetadata(NSData *compressedImage) {
  lt::Ref<CGImageSourceRef> source(
    CGImageSourceCreateWithData((__bridge CFDataRef)compressedImage, NULL)
  );
  if (!source) {
    return nil;
  }

  CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source.get(), 0, NULL);
  if (!properties) {
    return nil;
  }

  return CFBridgingRelease(properties);
}

SpecBegin(LTImageIOCompressor)

context(@"compression to data", ^{
  __block LTImageIOCompressor *compressor;

  beforeEach(^{
    compressor = [[LTImageIOCompressor alloc] initWithOptions:nil
                                                       format:$(LTCompressionFormatJPEG)];
  });

  it(@"should return correct format", ^{
    expect(compressor.format).to.equal($(LTCompressionFormatJPEG));
  });

  it(@"should compress jpeg from cv::Mat", ^{
    cv::Mat4b mat(5, 5, cv::Vec4b(192, 128, 64, 255));
    UIImage *image = [UIImage lt_imageWithMat:mat];

    NSError *error;
    NSData *data = [compressor compressImage:image metadata:nil error:&error];

    expect(LTVerifyFormat(data)).to.beTruthy();
    expect(error).to.beNil();
  });

  it(@"should compress jpeg from jpeg", ^{
    UIImage *image = LTLoadImage([self class], @"Gray.jpg");

    NSError *error;
    NSData *data = [compressor compressImage:image metadata:nil error:&error];

    expect(LTVerifyFormat(data)).to.beTruthy();
    expect(error).to.beNil();
  });

  it(@"should compress jpeg from png", ^{
    UIImage *image = LTLoadImage([self class], @"Lena.png");

    NSError *error;
    NSData *data = [compressor compressImage:image metadata:nil error:&error];

    expect(LTVerifyFormat(data)).to.beTruthy();
    expect(error).to.beNil();
  });

  it(@"should compress jpeg from tiff", ^{
    UIImage *image = LTLoadImage([self class], @"ImageCompressorInput.tiff");

    NSError *error;
    NSData *data = [compressor compressImage:image metadata:nil error:&error];

    expect(LTVerifyFormat(data)).to.beTruthy();
    expect(error).to.beNil();
  });

  it(@"should consider options argument", ^{
    UIImage *image = LTLoadImage([self class], @"Lena.png");
    LTImageIOCompressor *highCompressor = [[LTImageIOCompressor alloc] initWithOptions:@{
      (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @1
    } format:$(LTCompressionFormatJPEG)];

    NSError *error;
    NSData *highQualityData = [highCompressor compressImage:image metadata:nil error:&error];
    expect(error).to.beNil();

    LTImageIOCompressor *lowCompressor = [[LTImageIOCompressor alloc] initWithOptions:@{
      (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @0.5
    } format:$(LTCompressionFormatJPEG)];
    NSData *lowQualityData = [lowCompressor compressImage:image metadata:nil error:&error];

    expect(error).to.beNil();
    expect(highQualityData).notTo.equal(lowQualityData);
  });

  static const NSString * kUserComment = @"user comment";
  static const NSString * kLensModel = @"iPod touch front camera 2.18mm f/2.4";

  it(@"should add metadata to output image", ^{
    UIImage *image = LTLoadImage([self class], @"Lena.png");
    NSDictionary *metadata = @{(__bridge NSString *)kCGImagePropertyExifDictionary: @{
      (__bridge NSString *)kCGImagePropertyExifUserComment: kUserComment,
      (__bridge NSString *)kCGImagePropertyExifLensModel: kLensModel
    }};

    LTImageIOCompressor *compressor =
        [[LTImageIOCompressor alloc] initWithOptions:nil format:$(LTCompressionFormatJPEG)];
    NSError *error;
    NSData *imageData = [compressor compressImage:image metadata:metadata error:&error];
    NSDictionary *uncompressedMetadata = LTGetMetadata(imageData);
    NSDictionary *exifData =
        uncompressedMetadata[(__bridge NSString *)kCGImagePropertyExifDictionary];

    expect(error).to.beNil();
    expect(exifData[(__bridge NSString *)kCGImagePropertyExifUserComment]).to.equal(kUserComment);
    expect(exifData[(__bridge NSString *)kCGImagePropertyExifLensModel]).to.equal(kLensModel);
  });

  it(@"should merge options with metadata", ^{
    UIImage *image = LTLoadImage([self class], @"Lena.png");
    LTImageIOCompressor *compressor = [[LTImageIOCompressor alloc] initWithOptions:@{
      (__bridge NSString *)kCGImagePropertyExifDictionary: @{
        (__bridge NSString *)kCGImagePropertyExifUserComment: kUserComment,
      }
    } format:$(LTCompressionFormatJPEG)];

    NSDictionary *metadata = @{(__bridge NSString *)kCGImagePropertyExifDictionary: @{
      (__bridge NSString *)kCGImagePropertyExifLensModel: kLensModel
    }};
    NSError *error;
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

    UIImage *image = [UIImage lt_imageWithMat:nonContiguousImageMat];
    NSError *error;
    NSData *imageData = [compressor compressImage:image metadata:nil error:&error];
    LTImage *compressedImage = [[LTImage alloc] initWithImage:[UIImage imageWithData:imageData]];

    expect($(compressedImage.mat)).to.beCloseToMatWithin($(nonContiguousImageMat), 2);
    expect(error).to.beNil();
  });
});

context(@"compression to a file", ^{
  __block LTImageIOCompressor *compressor;
  __block NSURL *url;
  __block UIImage *image;

  beforeEach(^{
    LTCreateTemporaryDirectory();

    url = [NSURL fileURLWithPath:LTTemporaryPath(@"temp.jpg")];
    image = LTLoadImage([self class], @"Lena.png");

    compressor = [[LTImageIOCompressor alloc] initWithOptions:@{
      (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @1
    } format:$(LTCompressionFormatJPEG)];
  });

  afterEach(^{
    [[NSFileManager defaultManager] removeItemAtPath:LTTemporaryPath() error:nil];
  });

  it(@"should compress successfully to a file", ^{
    NSError *error;

    auto compressed = [compressor compressImage:image metadata:nil toURL:url error:&error];

    expect(error).to.beNil();
    expect(compressed).to.beTruthy();
  });

  it(@"should compress same data to file as to in memory data", ^{
    auto url = [NSURL fileURLWithPath:LTTemporaryPath(@"temp.jpg")];

    auto compressed = [compressor compressImage:image metadata:nil toURL:url error:nil];
    auto expectedData = [compressor compressImage:image metadata:nil error:nil];
    auto actualData = [NSData dataWithContentsOfURL:url];

    expect(compressed).to.beTruthy();
    expect(expectedData).notTo.beNil();
    expect(expectedData).to.equal(actualData);
  });
});

SpecEnd
