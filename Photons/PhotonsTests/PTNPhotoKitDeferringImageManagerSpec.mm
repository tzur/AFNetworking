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
__block PHImageRequestOptions *options;

beforeEach(^{
  underlyingImageManger = OCMProtocolMock(@protocol(PTNPhotoKitImageManager));
  authorizationManager = OCMProtocolMock(@protocol(PTNAuthorizationManager));
  imageManager =
      [[PTNPhotoKitDeferringImageManager alloc] initWithAuthorizationManager:authorizationManager
      deferredImageManager:^id<PTNPhotoKitImageManager>{
        return underlyingImageManger;
      }];
  
  asset = OCMClassMock([PHAsset class]);
  options = OCMClassMock([PHImageRequestOptions class]);
});

it(@"should return error for image requests when used before authorized", ^{
  OCMStub([authorizationManager authorizationStatus]).andReturn($(PTNAuthorizationStatusDenied));
  OCMReject([underlyingImageManger requestImageForAsset:OCMOCK_ANY targetSize:CGSizeZero
                                            contentMode:PHImageContentModeDefault options:OCMOCK_ANY
                                          resultHandler:OCMOCK_ANY]);
  
  __block NSError *error;
  [imageManager requestImageForAsset:asset targetSize:CGSizeZero
                         contentMode:PHImageContentModeDefault options:options
                       resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
    expect(result).to.beNil();
    error = info[PHImageErrorKey];
  }];
  
  expect(error).toNot.beNil();
  expect(error.code).to.equal(PTNErrorCodeNotAuthorized);
});

it(@"should ignore image cancellation when used before authorized", ^{
  OCMStub([authorizationManager authorizationStatus]).andReturn($(PTNAuthorizationStatusDenied));
  OCMReject([underlyingImageManger cancelImageRequest:1337]);
  
  [imageManager cancelImageRequest:1337];
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
                       resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
    expect(result).to.equal(image);
    expect(info).to.equal(@{});
  }];
  
  expect(requestID).to.equal(1337);
});

it(@"should forward image cancellation when used after authorized", ^{
  OCMStub([authorizationManager authorizationStatus])
      .andReturn($(PTNAuthorizationStatusAuthorized));
  
  [imageManager cancelImageRequest:1337];
  
  OCMVerify([underlyingImageManger cancelImageRequest:1337]);
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

SpecEnd
