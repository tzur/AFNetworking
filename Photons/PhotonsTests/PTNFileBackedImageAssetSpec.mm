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
#import "PTNTestResources.h"

SpecBegin(PTNFileBackedImageAsset)

__block PTNFileBackedImageAsset *asset;
__block NSFileManager *fileManager;
__block PTNImageResizer *resizer;
__block id<PTNResizingStrategy> resizingStrategy;
__block NSData *imageData;
__block LTPath *path;

beforeEach(^{
  path = [LTPath pathWithFileURL:PTNSmallImageURL()];
  imageData = [NSData dataWithContentsOfFile:path.path];
  fileManager = [NSFileManager defaultManager];
  resizer = OCMClassMock([PTNImageResizer class]);
  resizingStrategy = [PTNResizingStrategy identity];
  asset = [[PTNFileBackedImageAsset alloc] initWithFilePath:path
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
  auto data = nn([NSData dataWithContentsOfFile:path.path]);
  RACSignal *values = [asset fetchData];

  expect(values).will.sendValues(@[data]);
  expect(values).will.complete();
});

it(@"should write data to disk", ^{
  LTPath *writePath = [LTPath
                       pathWithPath:[LTTemporaryPath() stringByAppendingPathComponent:@"foo"]];
  auto data = nn([NSData dataWithContentsOfFile:path.path]);
  expect([asset writeToFileAtPath:writePath usingFileManager:fileManager]).will.complete();
  expect([NSData dataWithContentsOfFile:writePath.path]).to.equal(data);
});

context(@"path of unsupported data", ^{
  beforeEach(^{
    path = [LTPath pathWithFileURL:PTNTextFileURL()];
    asset = [[PTNFileBackedImageAsset alloc] initWithFilePath:path imageResizer:resizer
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
    asset = [[PTNFileBackedImageAsset alloc] initWithFilePath:path imageResizer:resizer
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
    expect([asset fetchData]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_isLTDomain;
    });
  });
});

it(@"should err when writing data to disk fails", ^{
  LTPath *writePath = [LTPath pathWithPath:@"f:a*/\f\\"];

  expect([asset writeToFileAtPath:writePath usingFileManager:fileManager])
      .will.matchError(^BOOL(NSError *error) {
    return error.code == LTErrorCodeFileWriteFailed && error.lt_isLTDomain;
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
    firstImage = [[PTNFileBackedImageAsset alloc] initWithFilePath:path imageResizer:resizer
                                                  resizingStrategy:resizingStrategy];
    secondImage = [[PTNFileBackedImageAsset alloc] initWithFilePath:path imageResizer:resizer
                                                   resizingStrategy:resizingStrategy];
    otherImage = [[PTNFileBackedImageAsset alloc] initWithFilePath:[LTPath pathWithPath:@"foo"]
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
