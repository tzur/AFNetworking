// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Zur Tene.

#import "PTNAVImageAsset.h"

#import <AVFoundation/AVFoundation.h>
#import <LTKit/LTCGExtensions.h>
#import <LTKit/LTPath.h>
#import <LTKit/NSBundle+Path.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "NSError+Photons.h"
#import "PTNAVImageGeneratorFactory.h"
#import "PTNFileSystemTestUtils.h"
#import "PTNImageMetadata.h"
#import "PTNResizingStrategy.h"
#import "PTNTestResources.h"

static UIImage *PTNImageWithColor(UIColor *color, CGRect rect) {
  UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1);
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
  asset = [AVAsset assetWithURL:PTNOneSecondVideoURL()];
  imageAsset = [[PTNAVImageAsset alloc] initWithAsset:asset
                                imageGeneratorFactory:imageGeneratorFactory
                                     resizingStrategy:resizingStrategy];
});

it(@"should fetch image", ^{
  UIImage *image = PTNImageWithColor([UIColor redColor], CGRectMake(0, 0, 20, 20));
  CGImageRef cgImage = image.CGImage;

  OCMStub([imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:(CMTime *)[OCMArg anyPointer]
                                      error:[OCMArg anyObjectRef]])
      .andDo(^(NSInvocation *invocation) {
        CGImageRetain(cgImage);
        [invocation setReturnValue:(void *)&cgImage];
      });

  LLSignalTestRecorder *recorder = [[imageAsset fetchImage] testRecorder];
  expect(recorder).will.sendValuesWithCount(1);

  CGImageRef sentImage = ((UIImage *)recorder.values.firstObject).CGImage;
  expect(sentImage).to.equal(cgImage);
});

it(@"should transfer ownership of fetched image", ^{
  UIImage *image = PTNImageWithColor([UIColor redColor], CGRectMake(0, 0, 20, 20));
  CGImageRef cgImage = CGImageCreateCopy(image.CGImage);
  const CFIndex initialRetainCount = CFGetRetainCount(cgImage);

  OCMStub([imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:(CMTime *)[OCMArg anyPointer]
                                      error:[OCMArg anyObjectRef]])
      .andDo(^(NSInvocation *invocation) {
        CGImageRetain(cgImage);
        [invocation setReturnValue:(void *)&cgImage];
      });

  @autoreleasepool {
    LLSignalTestRecorder *recorder = [[imageAsset fetchImage] testRecorder];
    expect(recorder).will.sendValuesWithCount(1);
  }

  expect(CFGetRetainCount(cgImage)).to.equal(initialRetainCount);
  CGImageRelease(cgImage);
});

it(@"should err when underlying generator errs", ^{
  OCMStub([imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:(CMTime *)[OCMArg anyPointer]
                                      error:[OCMArg anyObjectRef]])
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

it(@"should fetch image data", ^{
  UIImage *image = PTNImageWithColor([UIColor redColor], CGRectMake(0, 0, 20, 20));
  CGImageRef cgImage = image.CGImage;

  OCMStub([imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:(CMTime *)[OCMArg anyPointer]
                                      error:[OCMArg anyObjectRef]])
      .andDo(^(NSInvocation *invocation) {
        CGImageRetain(cgImage);
        [invocation setReturnValue:(void *)&cgImage];
      });

  LLSignalTestRecorder *recorder = [[imageAsset fetchData] testRecorder];
  expect(recorder).will.sendValuesWithCount(1);
  NSData *data = recorder.values.firstObject;
  expect([data isKindOfClass:[NSData class]]).to.beTruthy();

  UIImage *newImage = [UIImage imageWithData:data];
  expect(newImage.size * newImage.scale).to.equal(CGSizeMake(20, 20));
});

it(@"should fetch image metadata", ^{
  expect([imageAsset fetchImageMetadata]).will.sendValues(@[[[PTNImageMetadata alloc] init]]);
});

it(@"should be deallocated when fetch image completes", ^{
  __weak PTNAVImageAsset *weakImage;
  AVAsset *demoAsset = [AVAsset assetWithURL:PTNOneSecondVideoURL()];
  @autoreleasepool {
    PTNAVImageAsset *imageAsset =
        [[PTNAVImageAsset alloc] initWithAsset:demoAsset
                              resizingStrategy:[PTNResizingStrategy identity]];
    expect([imageAsset fetchImage]).will.complete();
  }
  // Will is used since weakImage can still be retained due to the fact that the fetchImage method
  // retains itself using GCD.
  expect(weakImage).will.beNil();
});

context(@"write to file", ^{
  __block NSFileManager *fileManager;

  beforeEach(^{
    fileManager = OCMClassMock([NSFileManager class]);
    UIImage *image = PTNImageWithColor([UIColor redColor], CGRectMake(0, 0, 20, 20));
    CGImageRef cgImage = image.CGImage;

    OCMStub([imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:nil
                                        error:[OCMArg anyObjectRef]])
        .andDo(^(NSInvocation *invocation) {
          CGImageRetain(cgImage);
          [invocation setReturnValue:(void *)&cgImage];
        });
  });

  it(@"should write data to disk", ^{
    LTPath *writePath = [LTPath pathWithPath:@"foo"];
    OCMExpect([fileManager lt_writeData:[OCMArg checkWithBlock:^BOOL(NSData *data) {
      UIImage *newImage = [UIImage imageWithData:data];
      return newImage.size == CGSizeMake(20, 20);
    }] toFile:writePath.path options:NSDataWritingAtomic error:[OCMArg setTo:nil]]).andReturn(YES);

    expect([imageAsset writeToFileAtPath:writePath usingFileManager:fileManager]).will.complete();
    OCMVerifyAll((id)fileManager);
  });

  it(@"should err when writing data to disk fails", ^{
    LTPath *path = [LTPath pathWithPath:@"foo"];
    OCMStub([fileManager lt_writeData:OCMOCK_ANY toFile:path.path options:NSDataWritingAtomic
                                error:[OCMArg setTo:[NSError lt_errorWithCode:1337]]]);

    expect([imageAsset writeToFileAtPath:path usingFileManager:fileManager])
    .will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == LTErrorCodeFileWriteFailed;
    });
  });
});

SpecEnd
