// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataBackedImageAsset.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "NSError+Photons.h"

SpecBegin(PTNDataBackedImageAsset)

__block id<PTNDataAsset, PTNImageAsset> asset;
__block NSFileManager *fileManager;
__block NSData *imageData;
__block LTPath *path;

beforeEach(^{
  NSString *pathString = [[NSBundle bundleForClass:[self class]] pathForResource:@"PTNImageAsset"
                                                                          ofType:@"jpg"];
  path = [LTPath pathWithPath:pathString];
  imageData = [NSData dataWithContentsOfFile:path.path];
  fileManager = OCMClassMock([NSFileManager class]);
  asset = [[PTNDataBackedImageAsset alloc] initWithData:imageData];
});

it(@"should return underlying image", ^{
  UIImage *image = [[UIImage alloc] initWithContentsOfFile:path.path];

  RACSignal *values = [asset fetchImage];

  expect(values).will.matchValue(0, ^(UIImage *fetchedImage) {
    return [UIImagePNGRepresentation(fetchedImage) isEqual:UIImagePNGRepresentation(image)];
  });
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
  OCMVerifyAll((id)fileManager);
});

context(@"unsupported data", ^{
  beforeEach(^{
    char data[] = "foo";
    imageData = [[NSData alloc] initWithBytes:data length:sizeof(data)];
    asset = [[PTNDataBackedImageAsset alloc] initWithData:imageData];
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

SpecEnd
