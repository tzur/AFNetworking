// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "PTNFileBackedAVAsset.h"

#import <AVFoundation/AVAsset.h>
#import <LTKit/LTPath.h>
#import <LTKit/NSFileManager+LTKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "NSErrorCodes+Photons.h"
#import "PTNTestResources.h"

SpecBegin(PTNFileBackedAVAsset)

__block PTNFileBackedAVAsset *asset;
__block LTPath *path;
__block NSFileManager *fileManager;
__block NSData *data;

beforeEach(^{
  fileManager = [NSFileManager defaultManager];
  auto url = PTNOneSecondVideoURL();
  path = [LTPath pathWithFileURL:url];
  data = [NSData dataWithContentsOfURL:url];
  asset = [[PTNFileBackedAVAsset alloc] initWithFilePath:path];
});

it(@"should have UTI to match the file", ^{
  expect(asset.uniformTypeIdentifier).to.equal((__bridge_transfer NSString *)kUTTypeMPEG4);
});

it(@"should have nil UTI when path has no extension", ^{
  auto pathWithNoExtension = [LTPath pathWithPath:@"foo://bar/flop"];
  auto noExtensionAsset = [[PTNFileBackedAVAsset alloc] initWithFilePath:pathWithNoExtension];
  expect(noExtensionAsset.uniformTypeIdentifier).to.beNil();
});

it(@"should return underlying data", ^{
  auto *values = [asset fetchData];

  expect(values).will.sendValues(@[data]);
  expect(values).will.complete();
});

it(@"should return AVAsset from the underlying path", ^{
  auto *values = [asset fetchAVAsset];

  expect(values).will.matchValue(0, ^BOOL(AVAsset *value) {
    return [((AVURLAsset *)value).URL isEqual:path.url];
  });
  expect(values).will.complete();
});

it(@"should copy data to disk", ^{
  auto temporaryFile = [LTTemporaryPath() stringByAppendingPathComponent:@"write"];
  auto *writePath = [LTPath pathWithPath:temporaryFile];
  expect([asset writeToFileAtPath:writePath usingFileManager:fileManager]).will.complete();
  expect([NSData dataWithContentsOfFile:temporaryFile]).equal(data);
  expect([NSData dataWithContentsOfFile:path.path]).equal(data);
});

it(@"should err when fetching file read fails", ^{
  auto invalidPath = [LTPath pathWithPath:@"foo"];
  auto invalidAsset = [[PTNFileBackedAVAsset alloc] initWithFilePath:invalidPath];
  expect([invalidAsset fetchData]).will.matchError(^BOOL(NSError *error) {
    return error.code == LTErrorCodeFileReadFailed;
  });
});

it(@"should err when writing data to disk fails", ^{
  auto writePath = [LTPath pathWithPath:@"f::/o*/o"];
  expect([asset writeToFileAtPath:writePath usingFileManager:fileManager])
      .will.matchError(^BOOL(NSError *error) {
    return error.code == LTErrorCodeFileWriteFailed;
  });
});

context(@"thread transitions", ^{
  it(@"should not operate on the main thread when fetching data", ^{
    auto *values = [asset fetchData];

    expect(values).will.sendValuesWithCount(1);
    expect(values).willNot.deliverValuesOnMainThread();
  });
});

SpecEnd
