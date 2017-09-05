// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTPhotoLibraryImageCompressor.h"

#import "LTCompressionFormat.h"
#import "LTImageHEICCompressor.h"
#import "LTImageJPEGCompressor.h"
#import "LTOpenCVExtensions.h"

SpecBegin(LTPhotoLibraryImageCompressor)

it(@"should initialize correctly", ^{
  auto compressor = [[LTPhotoLibraryImageCompressor alloc] init];
  expect(compressor.format).notTo.beNil();
});

it(@"should compress correcly", ^{
  id<LTImageCompressor> referenceCompressor = $(LTCompressionFormatHEIC).isSupported ?
      [[LTImageHEICCompressor alloc] init] : [[LTImageJPEGCompressor alloc] init];

  auto image = LTLoadImage([self class], @"Lena.png");
  auto expectedData = [referenceCompressor compressImage:image metadata:nil error:nil];

  auto compressor = [[LTPhotoLibraryImageCompressor alloc] init];
  auto data = [compressor compressImage:image metadata:nil error:NULL];

  expect(data).to.equal(expectedData);
});

SpecEnd
