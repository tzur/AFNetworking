// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageFetchOptions+PhotoKit.h"

#import <Photos/Photos.h>

SpecBegin(PTNImageFetchOptions_PhotoKit)

it(@"should create photokit options from photons options", ^{
  PTNImageFetchOptions *options = [PTNImageFetchOptions
                                   optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                   resizeMode:PTNImageResizeModeExact
                                   includeMetadata:NO];
  PHImageRequestOptions *photoKitOptions = [options photoKitOptions];

  expect(photoKitOptions.version).to.equal(PHImageRequestOptionsVersionCurrent);
  expect(photoKitOptions.deliveryMode).to.equal(PHImageRequestOptionsDeliveryModeFastFormat);
  expect(photoKitOptions.resizeMode).to.equal(PHImageRequestOptionsResizeModeExact);
  expect(photoKitOptions.networkAccessAllowed).to.beTruthy();
  expect(photoKitOptions.synchronous).to.beFalsy();
  expect(photoKitOptions.progressHandler).to.beNil();
});

it(@"should map fast resize mode to none resize mode", ^{
  PTNImageFetchOptions *options = [PTNImageFetchOptions
                                   optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                   resizeMode:PTNImageResizeModeFast
                                   includeMetadata:NO];
  PHImageRequestOptions *photoKitOptions = [options photoKitOptions];

  expect(photoKitOptions.resizeMode).to.equal(PHImageRequestOptionsResizeModeNone);
});

SpecEnd
