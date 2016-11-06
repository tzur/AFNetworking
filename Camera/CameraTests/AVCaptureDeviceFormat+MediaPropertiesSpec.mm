// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "AVCaptureDeviceFormat+MediaProperties.h"

#import "CAMFakeAVCaptureDeviceFormat.h"

SpecBegin(AVCaptureDeviceFormat_MediaProperties)

__block CAMFakeAVCaptureDeviceFormat *format;

beforeEach(^{
  format = [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'abcd' width:350 height:123
                                                stillWidth:460 stillHeight:256];
});

it(@"should return width", ^{
  expect(format.cam_width).to.equal(350);
});

it(@"should return height", ^{
  expect(format.cam_height).to.equal(123);
});

it(@"should return pixel count", ^{
  expect(format.cam_pixelCount).to.equal(43050);
});

it(@"should return High Resolution Still Image pixel count", ^{
  expect(format.cam_stillPixelCount).to.equal(117760);
});

it(@"should return media subtype", ^{
  expect(format.cam_mediaSubType).to.equal('abcd');
});

SpecEnd
