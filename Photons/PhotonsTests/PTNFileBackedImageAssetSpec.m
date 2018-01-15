// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFileBackedImageAsset.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSFileManager+LTKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"
#import "PTNImageResizer.h"
#import "PTNResizingStrategy.h"

SpecBegin(PTNFileBackedImageAsset)

__block PTNFileBackedImageAsset *asset;
__block NSFileManager *fileManager;
__block PTNImageResizer *resizer;
__block id<PTNResizingStrategy> resizingStrategy;
__block NSData *imageData;
__block LTPath *path;

beforeEach(^{
  NSString *pathString = [NSBundle.lt_testBundle pathForResource:@"PTNImageAsset" ofType:@"jpg"];
  path = [LTPath pathWithPath:pathString];
  imageData = [NSData dataWithContentsOfFile:path.path];
  fileManager = OCMClassMock([NSFileManager class]);
  resizer = OCMClassMock([PTNImageResizer class]);
  resizingStrategy = [PTNResizingStrategy identity];
  asset = [[PTNFileBackedImageAsset alloc] initWithFilePath:path fileManager:fileManager
                                               imageResizer:resizer
                                           resizingStrategy:resizingStrategy];
});

it(@"should have UTI to match the file", ^{
  expect(asset.uniformTypeIdentifier).to.equal((__bridge_transfer NSString *)kUTTypeJPEG);
});

it(@"should return underlying image", ^{
  UIImage *image = [[UIImage alloc] init];
  OCMStub([resizer resizeImageAtURL:path.url resizingStrategy:resizingStrategy])
      .andReturn([RACSignal return:image]);

  RACSignal *values = [asset fetchImage];

  expect(values).will.sendValues(@[image]);
  expect(values).will.complete();
});

it(@"should return image metadata", ^{
  PTNImageMetadata *metadata = [[PTNImageMetadata alloc] initWithImageURL:path.url error:nil];

  RACSignal *values = [asset fetchImageMetadata];

  expect(values).will.sendValues(@[metadata]);
  expect(values).will.complete();
});

it(@"should return underlying data", ^{
  OCMStub([fileManager lt_dataWithContentsOfFile:path.path options:NSDataReadingMappedIfSafe
                                           error:[OCMArg setTo:nil]]).andReturn(imageData);

  RACSignal *values = [asset fetchData];

  expect(values).will.sendValues(@[imageData]);
  expect(values).will.complete();
});

it(@"should write data to disk", ^{
  LTPath *writePath = [LTPath pathWithPath:@"foo"];
  OCMExpect([fileManager copyItemAtURL:path.url toURL:writePath.url error:[OCMArg setTo:nil]])
      .andReturn(YES);

  expect([asset writeToFileAtPath:writePath usingFileManager:fileManager]).will.complete();
  OCMVerifyAll((id)fileManager);
});

context(@"path of unsupported data", ^{
  beforeEach(^{
    NSString *pathString = [NSBundle.lt_testBundle pathForResource:@"PTNImageAsset" ofType:@"txt"];
    path = [LTPath pathWithPath:pathString];
    asset = [[PTNFileBackedImageAsset alloc] initWithFilePath:path fileManager:fileManager
                                                 imageResizer:resizer
                                             resizingStrategy:resizingStrategy];
  });

  it(@"should err when fetching metadata", ^{
    expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetMetadataLoadingFailed;
    });
  });
});

context(@"invalid path", ^{
  beforeEach(^{
    path = [LTPath pathWithPath:@"foo"];
    asset = [[PTNFileBackedImageAsset alloc] initWithFilePath:path fileManager:fileManager
                                                 imageResizer:resizer
                                             resizingStrategy:resizingStrategy];
  });

  it(@"should err when fetching image", ^{
    NSError *resizeError = [NSError lt_errorWithCode:1337];
    OCMStub([resizer resizeImageAtURL:path.url resizingStrategy:resizingStrategy])
        .andReturn([RACSignal error:resizeError]);

    expect([asset fetchImage]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed;
    });
  });

  it(@"should err when fetching data", ^{
    NSError *dataError = [NSError lt_errorWithCode:1337];
    OCMStub([fileManager lt_dataWithContentsOfFile:path.path options:NSDataReadingMappedIfSafe
                                             error:[OCMArg setTo:dataError]]);

    expect([asset fetchData]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed;
    });
  });
});

it(@"should err when writing data to disk fails", ^{
  NSError *writeError = [NSError lt_errorWithCode:1337];
  LTPath *writePath = [LTPath pathWithPath:@"foo"];
  OCMStub([fileManager copyItemAtURL:path.url toURL:writePath.url error:[OCMArg setTo:writeError]]);

  expect([asset writeToFileAtPath:writePath usingFileManager:fileManager])
      .will.matchError(^BOOL(NSError *error) {
    return error.code == LTErrorCodeFileWriteFailed;
  });
});

context(@"thread transitions", ^{
  it(@"should not operate on the main thread when fetching an image", ^{
    UIImage *image = [[UIImage alloc] init];
    OCMStub([resizer resizeImageAtURL:[NSURL fileURLWithPath:path.path]
                     resizingStrategy:resizingStrategy]).andReturn([RACSignal return:image]);

    RACSignal *values = [asset fetchImage];

    expect(values).will.sendValuesWithCount(1);
    expect(values).willNot.deliverValuesOnMainThread();
  });

  it(@"should not operate on the main thread when fetching image metadata", ^{
    RACSignal *values = [asset fetchImageMetadata];

    expect(values).will.sendValuesWithCount(1);
    expect(values).willNot.deliverValuesOnMainThread();
  });

  it(@"should not operate on the main thread when fetching data", ^{
    OCMStub([fileManager lt_dataWithContentsOfFile:path.path options:NSDataReadingMappedIfSafe
                                             error:[OCMArg setTo:nil]]).andReturn(imageData);

    RACSignal *values = [asset fetchData];

    expect(values).will.sendValuesWithCount(1);
    expect(values).willNot.deliverValuesOnMainThread();
  });
});

context(@"equality", ^{
  __block PTNFileBackedImageAsset *firstImage;
  __block PTNFileBackedImageAsset *secondImage;
  __block PTNFileBackedImageAsset *otherImage;

  beforeEach(^{
    firstImage = [[PTNFileBackedImageAsset alloc] initWithFilePath:path fileManager:fileManager
                                                      imageResizer:resizer
                                                  resizingStrategy:resizingStrategy];
    secondImage = [[PTNFileBackedImageAsset alloc] initWithFilePath:path fileManager:fileManager
                                                       imageResizer:resizer
                                                   resizingStrategy:resizingStrategy];
    otherImage = [[PTNFileBackedImageAsset alloc] initWithFilePath:[LTPath pathWithPath:@"foo"]
                                                       fileManager:fileManager
                                                      imageResizer:resizer
                                                  resizingStrategy:resizingStrategy];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstImage).to.equal(secondImage);
    expect(secondImage).to.equal(firstImage);

    expect(firstImage).notTo.equal(otherImage);
    expect(secondImage).notTo.equal(otherImage);
  });

  it(@"should create proper hash", ^{
    expect(firstImage.hash).to.equal(secondImage.hash);
  });
});

SpecEnd
