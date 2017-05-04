// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Zur Tene.

#import "PTNAVImageAsset.h"

#import <AVFoundation/AVFoundation.h>
#import <LTKit/NSBundle+Path.h>

#import "NSError+Photons.h"
#import "PTNAVImageGeneratorFactory.h"
#import "PTNFileSystemTestUtils.h"
#import "PTNImageMetadata.h"
#import "PTNResizingStrategy.h"

static UIImage *PTNImageWithColor(UIColor *color, CGRect rect) {
  UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
  [color setFill];
  UIRectFill(rect);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

SpecBegin(PTNAVImageAsset)

__block PTNAVImageAsset *imageAsset;
__block AVAssetImageGenerator *imageGenerator;
__block id<PTNResizingStrategy> resizingStrategy;
__block AVAsset *asset;
__block PTNAVImageGeneratorFactory *imageGeneratorFactory;

beforeEach(^{
  imageGeneratorFactory = OCMClassMock(PTNAVImageGeneratorFactory.class);
  imageGenerator = OCMClassMock(AVAssetImageGenerator.class);
  OCMStub([imageGeneratorFactory imageGeneratorForAsset:OCMOCK_ANY]).andReturn(imageGenerator);
  resizingStrategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
  OCMStub([resizingStrategy sizeForInputSize:CGSizeMake(16, 16)]).andReturn(CGSizeMake(10, 10));
  asset = [AVAsset assetWithURL:PTNOneSecondVideoPath()];
  imageAsset = [[PTNAVImageAsset alloc] initWithAsset:asset
                                imageGeneratorFactory:imageGeneratorFactory
                                     resizingStrategy:resizingStrategy];
});

it(@"should fetch image", ^{
  UIImage *image = PTNImageWithColor([UIColor redColor], CGRectMake(0, 0, 20, 20));
  CGImageRef cgImage = image.CGImage;
  OCMStub([imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:nil error:[OCMArg anyObjectRef]])
      .andReturn(cgImage);
  LLSignalTestRecorder *recorder = [[imageAsset fetchImage] testRecorder];
  expect(recorder).will.sendValuesWithCount(1);
  expect(((UIImage *)recorder.values.firstObject).CGImage).to.equal(image.CGImage);
});

it(@"should err when underlying generator errs", ^{
  OCMStub([imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:nil error:[OCMArg anyObjectRef]])
      .andReturn((CGImageRef)nil);
  RACSignal *values = [imageAsset fetchImage];
  expect(values).will.matchError(^BOOL(NSError *error) {
    return error.code == PTNErrorCodeAVImageAssetFetchImageFailed;
  });
});

it(@"should set underlying generator max size to the size from the resizing strategy", ^{
  OCMExpect([imageGenerator setMaximumSize:CGSizeMake(10, 10)]);
  [[imageAsset fetchImage] testRecorder];
  OCMVerifyAllWithDelay((OCMockObject *)imageGenerator, 1.0);
});

it(@"should fetch image metadata", ^{
  expect([imageAsset fetchImageMetadata]).will.sendValues(@[[[PTNImageMetadata alloc] init]]);
});

it(@"should be deallocated when fetch image completes", ^{
  __weak PTNAVImageAsset *weakImage;
  AVAsset *demoAsset = [AVAsset assetWithURL:PTNOneSecondVideoPath()];
  @autoreleasepool {
    PTNAVImageAsset *imageAsset =
        [[PTNAVImageAsset alloc] initWithAsset:demoAsset
                              resizingStrategy:[PTNResizingStrategy identity]];
    expect([imageAsset fetchImage]).will.complete();
  }
  // Will is beeing used since weakImage can still be retained due to the fact that the fetchImage
  // method retains itself using GCD.
  expect(weakImage).will.beNil();
});

SpecEnd
