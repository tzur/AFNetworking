// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "PTNImageDataAsset.h"

#import <LTKit/LTPath.h>

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"

SpecBegin(PTNImageDataAsset)

__block NSData *data;
__block PTNImageDataAsset *asset;

beforeEach(^{
  char buffer[] = { 0x1, 0x2, 0x3, 0x4 };
  data = [[NSData alloc] initWithBytes:buffer length:sizeof(buffer)];
  asset = [[PTNImageDataAsset alloc] initWithData:data
                                   uniformTypeIdentifier:@"public.type"];
});

it(@"should fetch data", ^{
  expect([asset fetchData]).to.sendValues(@[data]);
});

context(@"image fetch", ^{
  it(@"should fetch image from data", ^{
    auto *path = [NSBundle.lt_testBundle pathForResource:@"PTNImageAsset" ofType:@"jpg"];
    auto data = [NSData dataWithContentsOfFile:path];
    auto image = [UIImage imageWithContentsOfFile:path];
    asset = [[PTNImageDataAsset alloc] initWithData:data];

    expect([asset fetchImage]).to.matchValue(0, ^BOOL(UIImage *sendImage) {
      return CGSizeEqualToSize(sendImage.size, image.size);
    });
  });

  it(@"should err when data is corrupted", ^{
    expect([asset fetchImage]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed;
    });
  });
});

context(@"metadata fetching", ^{
  it(@"should fetch metadata", ^{
    NSURL *url = [NSBundle.lt_testBundle URLForResource:@"PTNImageMetadataImage"
                                          withExtension:@"jpg"];

    NSData *imageData = [NSData dataWithContentsOfURL:url];
    asset = [[PTNImageDataAsset alloc] initWithData:imageData];
    expect([asset fetchImageMetadata]).will.matchValue(0, ^BOOL(PTNImageMetadata *metadata) {
      return metadata != nil;
    });
  });

  it(@"should err when data is corrupted", ^{
    expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetMetadataLoadingFailed && error.lt_underlyingError;
    });
  });
});

context(@"write to file", ^{
  __block NSFileManager *fileManager;

  beforeEach(^{
    fileManager = [NSFileManager defaultManager];
  });

  it(@"should write data to disk and complete", ^{
    LTPath *writePath = [LTPath
                         pathWithPath:[LTTemporaryPath() stringByAppendingPathComponent:@"foo"]];

    expect([asset writeToFileAtPath:writePath usingFileManager:fileManager]).will.complete();
    expect([NSData dataWithContentsOfFile:writePath.path]).to.equal(data);
  });

  it(@"should err when writing data to disk fails", ^{
    LTPath *writePath = [LTPath pathWithPath:@"f:a*/\f\\"];

    expect([asset writeToFileAtPath:writePath usingFileManager:fileManager])
        .will.matchError(^BOOL(NSError *error) {
      return error.code == LTErrorCodeFileWriteFailed && error.lt_isLTDomain;
    });
  });
});

SpecEnd
