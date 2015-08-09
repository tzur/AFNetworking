// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageFetchOptions+PhotoKit.h"

SpecBegin(PTNImageFetchOptions_PhotoKit)

it(@"should create photokit options from photons options", ^{
  PTNImageFetchOptions *options = [PTNImageFetchOptions
                                   optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                   resizeMode:PTNImageResizeModeFast];
  PHImageRequestOptions *photoKitOptions = [options photoKitOptions];

  expect(photoKitOptions.version).to.equal(PHImageRequestOptionsVersionCurrent);
  expect(photoKitOptions.deliveryMode).to.equal(PHImageRequestOptionsDeliveryModeFastFormat);
  expect(photoKitOptions.resizeMode).to.equal(PHImageRequestOptionsResizeModeFast);
  expect(photoKitOptions.networkAccessAllowed).to.beFalsy();
  expect(photoKitOptions.synchronous).to.beFalsy();
  expect(photoKitOptions.progressHandler).to.beNil();
});

SpecEnd
