// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTPhotoLibraryImageCompressor.h"

#import "LTCompressionFormat.h"
#import "LTImageHEICCompressor.h"
#import "LTImageJPEGCompressor.h"
#import "LTOpenCVExtensions.h"

SpecBegin(LTPhotoLibraryImageCompressor)

it(@"should initialize with default initializer", ^{
  auto compressor = [[LTPhotoLibraryImageCompressor alloc] init];
  expect(compressor.format).notTo.beNil();
  expect(compressor.quality).to.equal(1);
});

it(@"should initialize with quality", ^{
  auto compressor = [[LTPhotoLibraryImageCompressor alloc] initWithQuality:0.5];
  expect(compressor.quality).to.equal(0.5);
});

it(@"should compress correcly", ^{
  id<LTImageCompressor> referenceCompressor = $(LTCompressionFormatHEIC).isSupported ?
      [[LTImageHEICCompressor alloc] init] : [[LTImageJPEGCompressor alloc] init];

  auto image = LTLoadImage([self class], @"Lena.png");
  auto expectedData = [referenceCompressor compressImage:image metadata:nil error:nil];

  auto compressor = [[LTPhotoLibraryImageCompressor alloc] init];
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

SpecEnd
