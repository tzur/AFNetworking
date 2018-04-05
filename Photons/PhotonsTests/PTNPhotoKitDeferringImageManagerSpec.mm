// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitDeferringImageManager.h"

#import "NSErrorCodes+Photons.h"
#import "PTNAuthorizationManager.h"
#import "PTNAuthorizationStatus.h"

SpecBegin(PTNPhotoKitDeferringImageManager)

__block PTNPhotoKitDeferringImageManager *imageManager;
__block id<PTNPhotoKitImageManager> underlyingImageManger;
__block id<PTNAuthorizationManager> authorizationManager;

__block PHAsset *asset;

beforeEach(^{
  underlyingImageManger = OCMProtocolMock(@protocol(PTNPhotoKitImageManager));
  authorizationManager = OCMProtocolMock(@protocol(PTNAuthorizationManager));
  imageManager =
      [[PTNPhotoKitDeferringImageManager alloc] initWithAuthorizationManager:authorizationManager
      deferredImageManager:^id<PTNPhotoKitImageManager>{
        return underlyingImageManger;
      }];

  asset = OCMClassMock([PHAsset class]);
});

it(@"should ignore image cancellation when used before authorized", ^{
  OCMStub([authorizationManager authorizationStatus]).andReturn($(PTNAuthorizationStatusDenied));
  OCMReject([underlyingImageManger cancelImageRequest:1337]);

  [imageManager cancelImageRequest:1337];
});

it(@"should forward image cancellation when used after authorized", ^{
  OCMStub([authorizationManager authorizationStatus])
      .andReturn($(PTNAuthorizationStatusAuthorized));

  [imageManager cancelImageRequest:1337];

  OCMVerify([underlyingImageManger cancelImageRequest:1337]);
});

context(@"image request", ^{
  __block PHImageRequestOptions *options;

  beforeEach(^{
    options = OCMClassMock([PHImageRequestOptions class]);
  });

  it(@"should return error for image requests when used before authorized", ^{
    OCMStub([authorizationManager authorizationStatus]).andReturn($(PTNAuthorizationStatusDenied));
    OCMReject([underlyingImageManger requestImageForAsset:OCMOCK_ANY targetSize:CGSizeZero
                                              contentMode:PHImageContentModeDefault
                                                  options:OCMOCK_ANY resultHandler:OCMOCK_ANY]);

    __block NSError *error;
    [imageManager requestImageForAsset:asset targetSize:CGSizeZero
                           contentMode:PHImageContentModeDefault options:options
                         resultHandler:^(UIImage * _Nullable result,
                                         NSDictionary * _Nullable info) {
      expect(result).to.beNil();
      error = info[PHImageErrorKey];
    }];

    expect(error).toNot.beNil();
    expect(error.code).to.equal(PTNErrorCodeNotAuthorized);
  });

  it(@"should forward image requests when used after authorization", ^{
    UIImage *image = [[UIImage alloc] init];
    OCMStub([authorizationManager authorizationStatus])
        .andReturn($(PTNAuthorizationStatusAuthorized));

    OCMStub([underlyingImageManger requestImageForAsset:asset targetSize:CGSizeZero
        contentMode:PHImageContentModeDefault options:options
        resultHandler:([OCMArg invokeBlockWithArgs:image, @{}, nil])]).andReturn(1337);

    PHImageRequestID requestID = [imageManager requestImageForAsset:asset targetSize:CGSizeZero
                           contentMode:PHImageContentModeDefault options:options
                         resultHandler:^(UIImage * _Nullable result,
                                         NSDictionary * _Nullable info) {
      expect(result).to.equal(image);
      expect(info).to.equal(@{});
    }];

    expect(requestID).to.equal(1337);
  });

  it(@"should not call image manager block before authorized", ^{
    __block BOOL calledBlock = NO;
    imageManager =
        [[PTNPhotoKitDeferringImageManager alloc] initWithAuthorizationManager:authorizationManager
        deferredImageManager:^id<PTNPhotoKitImageManager> {
          calledBlock = YES;
          return underlyingImageManger;
        }];

    OCMStub([authorizationManager authorizationStatus])
        .andReturn($(PTNAuthorizationStatusRestricted));
    [imageManager requestImageForAsset:asset targetSize:CGSizeZero
        contentMode:PHImageContentModeDefault options:options
        resultHandler:^(UIImage *, NSDictionary *) {}];
    [imageManager cancelImageRequest:1337];

    expect(calledBlock).to.beFalsy();
  });

  it(@"should call image manager block only once authorized", ^{
    __block NSUInteger managersRequested = 0;
    imageManager =
        [[PTNPhotoKitDeferringImageManager alloc] initWithAuthorizationManager:authorizationManager
        deferredImageManager:^id<PTNPhotoKitImageManager> {
          ++managersRequested;
          return underlyingImageManger;
        }];

    OCMStub([authorizationManager authorizationStatus])
        .andReturn($(PTNAuthorizationStatusAuthorized));
    [imageManager requestImageForAsset:asset targetSize:CGSizeZero
        contentMode:PHImageContentModeDefault options:options
        resultHandler:^(UIImage *, NSDictionary *) {}];
    [imageManager cancelImageRequest:1337];

    [imageManager requestImageForAsset:asset targetSize:CGSizeZero
        contentMode:PHImageContentModeDefault options:options
        resultHandler:^(UIImage *, NSDictionary *) {}];
    [imageManager cancelImageRequest:1337];

    [imageManager requestImageForAsset:asset targetSize:CGSizeZero
        contentMode:PHImageContentModeDefault options:options
        resultHandler:^(UIImage *, NSDictionary *) {}];
    [imageManager cancelImageRequest:1337];

    expect(managersRequested).to.equal(1);
  });
});

context(@"avasset request", ^{
  __block PHVideoRequestOptions *options;
  __block AVAudioMix *audioMix;

  beforeEach(^{
    options = OCMClassMock([PHVideoRequestOptions class]);
    audioMix = OCMClassMock([AVAudioMix class]);
  });

  it(@"should return error for avasset requests when used before authorized", ^{
    OCMStub([authorizationManager authorizationStatus]).andReturn($(PTNAuthorizationStatusDenied));
    OCMReject([underlyingImageManger requestImageForAsset:OCMOCK_ANY targetSize:CGSizeZero
                                              contentMode:PHImageContentModeDefault
                                                  options:OCMOCK_ANY resultHandler:OCMOCK_ANY]);

    __block NSError *error;
    [imageManager requestAVAssetForVideo:asset options:options
                           resultHandler:^(AVAsset * __nullable asset,
                                           AVAudioMix * __nullable audioMix,
                                           NSDictionary * __nullable info) {
      expect(asset).to.beNil();
      expect(audioMix).to.beNil();
      error = info[PHImageErrorKey];
    }];

    expect(error).toNot.beNil();
    expect(error.code).to.equal(PTNErrorCodeNotAuthorized);
  });

  it(@"should forward avasset requests when used after authorization", ^{
    id avasset = OCMClassMock([AVAsset class]);
    OCMStub([authorizationManager authorizationStatus])
        .andReturn($(PTNAuthorizationStatusAuthorized));

    OCMStub([underlyingImageManger requestAVAssetForVideo:asset options:options
        resultHandler:([OCMArg invokeBlockWithArgs:avasset, audioMix, @{}, nil])]).andReturn(1337);

    PHImageRequestID requestID =
        [imageManager requestAVAssetForVideo:asset options:options
                               resultHandler:^(AVAsset * __nullable asset,
                                               AVAudioMix * __nullable audioMix,
                                               NSDictionary * __nullable info) {
      expect(asset).to.equal(avasset);
      expect(audioMix).to.equal(audioMix);
      expect(info).to.equal(@{});
    }];

    expect(requestID).to.equal(1337);
  });

  it(@"should not call image manager block before authorized", ^{
    __block BOOL calledBlock = NO;
    imageManager =
        [[PTNPhotoKitDeferringImageManager alloc] initWithAuthorizationManager:authorizationManager
        deferredImageManager:^id<PTNPhotoKitImageManager> {
          calledBlock = YES;
          return underlyingImageManger;
        }];

    OCMStub([authorizationManager authorizationStatus])
        .andReturn($(PTNAuthorizationStatusRestricted));
    [imageManager requestAVAssetForVideo:asset options:options
                           resultHandler:^(AVAsset *, AVAudioMix *,  NSDictionary *) {}];
    [imageManager cancelImageRequest:1337];

    expect(calledBlock).to.beFalsy();
  });

  it(@"should call image manager block only once authorized", ^{
    __block NSUInteger managersRequested = 0;
    imageManager =
        [[PTNPhotoKitDeferringImageManager alloc] initWithAuthorizationManager:authorizationManager
        deferredImageManager:^id<PTNPhotoKitImageManager> {
          ++managersRequested;
          return underlyingImageManger;
        }];

    OCMStub([authorizationManager authorizationStatus])
        .andReturn($(PTNAuthorizationStatusAuthorized));
    [imageManager requestAVAssetForVideo:asset options:options
                           resultHandler:^(AVAsset *, AVAudioMix *,  NSDictionary *) {}];
    [imageManager cancelImageRequest:1337];

    [imageManager requestAVAssetForVideo:asset options:options
                           resultHandler:^(AVAsset *, AVAudioMix *,  NSDictionary *) {}];
    [imageManager cancelImageRequest:1337];

    [imageManager requestAVAssetForVideo:asset options:options
                           resultHandler:^(AVAsset *, AVAudioMix *,  NSDictionary *) {}];
    [imageManager cancelImageRequest:1337];

    expect(managersRequested).to.equal(1);
  });
});

context(@"image data request", ^{
  __block PHImageRequestOptions *options;

  beforeEach(^{
    options = OCMClassMock([PHVideoRequestOptions class]);
  });

  it(@"should return error for image data requests when used before authorized", ^{
    OCMStub([authorizationManager authorizationStatus]).andReturn($(PTNAuthorizationStatusDenied));
    OCMReject([underlyingImageManger requestImageDataForAsset:OCMOCK_ANY options:OCMOCK_ANY
                                                resultHandler:OCMOCK_ANY]);
    __block NSError *error;
    [imageManager requestImageDataForAsset:asset options:options
                             resultHandler:^(NSData * _Nullable imageData,
                                             NSString * _Nullable dataUTI,
                                             UIImageOrientation, NSDictionary * _Nullable info) {
                               expect(imageData).to.beNil();
                               expect(dataUTI).to.beNil();
                               error = info[PHImageErrorKey];
                             }];

    expect(error).toNot.beNil();
    expect(error.code).to.equal(PTNErrorCodeNotAuthorized);
  });

  it(@"should forward image data requests when used after authorization", ^{
    char buffer[] = { 0x1, 0x2, 0x3, 0x4 };
    NSData *data = [NSData dataWithBytes:buffer length:sizeof(buffer)];
    OCMStub([authorizationManager authorizationStatus])
        .andReturn($(PTNAuthorizationStatusAuthorized));

    OCMStub([underlyingImageManger requestImageDataForAsset:asset options:options
        resultHandler:([OCMArg invokeBlockWithArgs:data, @"publc.type", @(UIImageOrientationUp),
                        @{}, nil])]).andReturn(3389);

    PHImageRequestID requestID =
        [imageManager requestImageDataForAsset:asset options:options
                                 resultHandler:^(NSData * _Nullable imageData,
                                                 NSString * _Nullable dataUTI,
                                                 UIImageOrientation orientation,
                                                 NSDictionary * _Nullable info) {
                                   expect(imageData).to.equal(data);
                                   expect(dataUTI).to.equal(@"publc.type");
                                   expect(orientation).to.equal(UIImageOrientationUp);
                                   expect(info).to.equal(@{});
                                 }];

    expect(requestID).to.equal(3389);
  });

  it(@"should not call image manager block before authorized", ^{
    __block BOOL calledBlock = NO;
    imageManager =
        [[PTNPhotoKitDeferringImageManager alloc] initWithAuthorizationManager:authorizationManager
        deferredImageManager:^id<PTNPhotoKitImageManager> {
          calledBlock = YES;
          return underlyingImageManger;
        }];

    OCMStub([authorizationManager authorizationStatus])
        .andReturn($(PTNAuthorizationStatusRestricted));
    [imageManager requestImageDataForAsset:asset options:options
                             resultHandler:^(NSData * _Nullable, NSString * _Nullable,
                                             UIImageOrientation, NSDictionary * _Nullable) {}];
    [imageManager cancelImageRequest:3389];

    expect(calledBlock).to.beFalsy();
  });

  it(@"should call image manager block only once authorized", ^{
    __block NSUInteger managersRequested = 0;
    imageManager =
        [[PTNPhotoKitDeferringImageManager alloc] initWithAuthorizationManager:authorizationManager
        deferredImageManager:^id<PTNPhotoKitImageManager> {
          ++managersRequested;
          return underlyingImageManger;
        }];

    OCMStub([authorizationManager authorizationStatus])
        .andReturn($(PTNAuthorizationStatusAuthorized));
    [imageManager requestImageDataForAsset:asset options:options
                             resultHandler:^(NSData * _Nullable, NSString * _Nullable,
                                             UIImageOrientation, NSDictionary * _Nullable) {}];
    [imageManager cancelImageRequest:3389];
    [imageManager requestImageDataForAsset:asset options:options
                             resultHandler:^(NSData * _Nullable, NSString * _Nullable,
                                             UIImageOrientation, NSDictionary * _Nullable) {}];
    [imageManager cancelImageRequest:3389];
    [imageManager requestImageDataForAsset:asset options:options
                             resultHandler:^(NSData * _Nullable, NSString * _Nullable,
                                             UIImageOrientation, NSDictionary * _Nullable) {}];
    [imageManager cancelImageRequest:3389];

    expect(managersRequested).to.equal(1);
  });
});

SpecEnd
