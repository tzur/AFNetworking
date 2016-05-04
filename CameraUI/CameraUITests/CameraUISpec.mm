// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CameraUI.h"

SpecBegin(CameraUI)

it(@"should work", ^{
  CameraUI *cameraUi = [[CameraUI alloc] init];
  expect(cameraUi.helloString).to.equal(@"Hello World!");
});

SpecEnd
