// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTPhotoLibraryImageCompressor.h"

#import "LTCompressionFormat.h"
#import "LTImageHEICCompressor.h"
#import "LTImageJPEGCompressor.h"
#import "LTOpenCVExtensions.h"

SpecBegin(LTPhotoLibraryImageCompressor)

it(@"should initialize with quality", ^{
  auto compressor = [[LTPhotoLibraryImageCompressor alloc] initWithQuality:0.5];
  expect(compressor.quality).to.equal(0.5);
});

it(@"should clamp quality value", ^{
  auto qualityBelowCompressor = [[LTPhotoLibraryImageCompressor alloc] initWithQuality:-1];
  auto qualityAboveCompressor = [[LTPhotoLibraryImageCompressor alloc] initWithQuality:2];

  expect(qualityBelowCompressor.quality).to.equal(0);
  expect(qualityAboveCompressor.quality).to.equal(1);
});

it(@"should compress correcly", ^{
  id<LTImageCompressor> referenceCompressor;

  if (@available(iOS 11.0, *)) {
    referenceCompressor = $(LTCompressionFormatHEIC).isSupported ?
        [[LTImageHEICCompressor alloc] initWithQuality:1] :
        [[LTImageJPEGCompressor alloc] initWithQuality:1];
  } else {
    referenceCompressor = [[LTImageJPEGCompressor alloc] initWithQuality:1];
  }

  auto image = LTLoadImage([self class], @"Lena.png");
  auto expectedData = [referenceCompressor compressImage:image metadata:nil error:nil];

  auto compressor = [[LTPhotoLibraryImageCompressor alloc] initWithQuality:1];
  auto data = [compressor compressImage:image metadata:nil error:nil];

  expect(data).to.equal(expectedData);
});

it(@"should be affected by compression quality", ^{
  auto compressor = [[LTPhotoLibraryImageCompressor alloc] initWithQuality:0.5];
  auto compressor2 = [[LTPhotoLibraryImageCompressor alloc] initWithQuality:0.25];

  auto image = LTLoadImage([self class], @"Lena.png");
  auto data = [compressor compressImage:image metadata:nil error:nil];
  auto data2 = [compressor2 compressImage:image metadata:nil error:nil];

  expect(data).notTo.equal(data2);
});

it(@"should raise when initalized with illegal quality", ^{
  expect(^{
    __unused auto compressor = [[LTPhotoLibraryImageCompressor alloc] initWithQuality:1.1];
  });
  expect(^{
    __unused auto compressor = [[LTPhotoLibraryImageCompressor alloc] initWithQuality:-0.1];
  });
});

it(@"should compress same data to file as to in memory data", ^{
  UIImage *image = LTLoadImage([self class], @"Lena.png");
  auto url = [NSURL fileURLWithPath:LTTemporaryPath(@"temp.bin")];

  NSError *error;
  auto compressor = [[LTPhotoLibraryImageCompressor alloc] initWithQuality:0.5];
  auto compressed = [compressor compressImage:image metadata:nil toURL:url error:&error];
  auto expectedData = [compressor compressImage:image metadata:nil error:nil];
  auto actualData = [NSData dataWithContentsOfURL:url];

  expect(compressed).to.beTruthy();
  expect(error).to.beNil();
  expect(expectedData).notTo.beNil();
  expect(expectedData).to.equal(actualData);
});

it(@"should return correct format", ^{
  id<LTImageCompressor> referenceCompressor;

  if (@available(iOS 11.0, *)) {
    referenceCompressor = $(LTCompressionFormatHEIC).isSupported ?
    [[LTImageHEICCompressor alloc] initWithQuality:1] :
    [[LTImageJPEGCompressor alloc] initWithQuality:1];
  } else {
    referenceCompressor = [[LTImageJPEGCompressor alloc] initWithQuality:1];
  }

  auto compressor = [[LTPhotoLibraryImageCompressor alloc] initWithQuality:1];

  expect(compressor.format).to.equal(referenceCompressor.format);
});

SpecEnd
