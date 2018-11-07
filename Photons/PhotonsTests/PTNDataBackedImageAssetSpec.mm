// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataBackedImageAsset.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"
#import "PTNImageResizer.h"
#import "PTNResizingStrategy.h"
#import "PTNTestResources.h"

SpecBegin(PTNDataBackedImageAsset)

__block id<PTNDataAsset, PTNImageAsset> asset;
__block NSFileManager *fileManager;
__block NSData *imageData;
__block UIImage *image;
__block LTPath *path;
__block PTNImageResizer *resizer;
__block id<PTNResizingStrategy> resizingStrategy;

beforeEach(^{
  path = [LTPath pathWithFileURL:PTNSmallImageURL()];
  imageData = [NSData dataWithContentsOfFile:path.path];
  image = [[UIImage alloc] init];
  fileManager = OCMClassMock([NSFileManager class]);
  resizingStrategy = [PTNResizingStrategy identity];
  resizer = OCMClassMock([PTNImageResizer class]);
  OCMStub([resizer resizeImageFromData:imageData resizingStrategy:resizingStrategy])
      .andReturn([RACSignal return:image]);
  asset = [[PTNDataBackedImageAsset alloc] initWithData:imageData resizer:resizer
                                       resizingStrategy:resizingStrategy];
});

it(@"should return underlying image using resizer and resizing strategy", ^{
  RACSignal *values = [asset fetchImage];

  expect(values).will.sendValues(@[image]);
  expect(values).will.complete();
});

it(@"should use resizing strategy to resize image", ^{
  UIImage *otherImage = [[UIImage alloc] init];
  id<PTNResizingStrategy> otherResizingStrategy = [PTNResizingStrategy maxPixels:1337];
  OCMStub([resizer resizeImageFromData:imageData resizingStrategy:otherResizingStrategy])
      .andReturn([RACSignal return:otherImage]);
  asset = [[PTNDataBackedImageAsset alloc] initWithData:imageData resizer:resizer
                                       resizingStrategy:otherResizingStrategy];

  RACSignal *values = [asset fetchImage];

  expect(values).will.sendValues(@[otherImage]);
  expect(values).will.complete();
});

it(@"should return image metadata", ^{
  PTNImageMetadata *metadata = [[PTNImageMetadata alloc] initWithImageURL:path.url error:nil];

  RACSignal *values = [asset fetchImageMetadata];

  expect(values).will.sendValues(@[metadata]);
  expect(values).will.complete();
});

it(@"should return underlying data", ^{
  RACSignal *values = [asset fetchData];

  expect(values).will.sendValues(@[imageData]);
  expect(values).will.complete();
});

it(@"should write data to disk", ^{
  LTPath *writePath = [LTPath pathWithPath:@"foo"];
  OCMExpect([fileManager lt_writeData:imageData toFile:writePath.path options:NSDataWritingAtomic
                                error:[OCMArg setTo:nil]]);

  expect([asset writeToFileAtPath:writePath usingFileManager:fileManager]).will.complete();
  OCMVerifyAll(fileManager);
});

context(@"unsupported data", ^{
  beforeEach(^{
    char data[] = "foo";
    imageData = [[NSData alloc] initWithBytes:data length:sizeof(data)];
    OCMStub([resizer resizeImageFromData:imageData resizingStrategy:OCMOCK_ANY])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
    asset = [[PTNDataBackedImageAsset alloc] initWithData:imageData resizer:resizer
                                         resizingStrategy:resizingStrategy];
  });

  it(@"should err when fetching image of unsupported image data", ^{
    expect([asset fetchImage]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed;
    });
  });

  it(@"should err when fetching metadata", ^{
    expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetMetadataLoadingFailed;
    });
  });
});

it(@"should err when writing data to disk fails", ^{
  LTPath *path = [LTPath pathWithPath:@"foo"];
  OCMStub([fileManager lt_writeData:imageData toFile:path.path options:NSDataWritingAtomic
                              error:[OCMArg setTo:[NSError lt_errorWithCode:1337]]]);

  expect([asset writeToFileAtPath:path usingFileManager:fileManager])
      .will.matchError(^BOOL(NSError *error) {
    return error.code == LTErrorCodeFileWriteFailed;
  });
});

context(@"thread transitions", ^{
  it(@"should not operate on the main thread when fetching an image", ^{
    RACSignal *values = [asset fetchImage];

    expect(values).will.sendValuesWithCount(1);
    expect(values).willNot.deliverValuesOnMainThread();
  });

  it(@"should not operate on the main thread when fetching image metadata", ^{
    RACSignal *values = [asset fetchImageMetadata];

    expect(values).will.sendValuesWithCount(1);
    expect(values).willNot.deliverValuesOnMainThread();
  });
});

context(@"equality", ^{
  __block PTNDataBackedImageAsset *firstImage;
  __block PTNDataBackedImageAsset *secondImage;
  __block PTNDataBackedImageAsset *otherImage;

  beforeEach(^{
    firstImage = [[PTNDataBackedImageAsset alloc] initWithData:imageData];
    secondImage = [[PTNDataBackedImageAsset alloc] initWithData:imageData];
    otherImage = [[PTNDataBackedImageAsset alloc] initWithData:[[NSData alloc] init]];
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
