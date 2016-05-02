// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "Camera.h"

SpecBegin(Camera)

it(@"should work", ^{
  Camera *camera = [[Camera alloc] init];
  expect(camera.helloString).to.equal(@"Hello World!");
});

SpecEnd
