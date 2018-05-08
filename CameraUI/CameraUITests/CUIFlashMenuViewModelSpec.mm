// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIFlashMenuViewModel.h"

#import "CUIFlashModeViewModel.h"

static const AVCaptureFlashMode kInvalidFlashMode = AVCaptureFlashModeOn;

SpecBegin(CUIFlashMenuViewModel)

__block CUIFlashMenuViewModel *flashViewModel;
__block NSArray<CUIFlashModeViewModel *> *flashModes;
__block CAMDeviceStub *device;

beforeEach(^{
  flashModes = @[
    OCMClassMock([CUIFlashModeViewModel class)],
    OCMClassMock([CUIFlashModeViewModel class])
  ];
  OCMStub([flashModes[0] title]).andReturn(@"Auto");
  OCMStub([flashModes[0] iconURL]).andReturn([NSURL URLWithString:@"http://lightricks.owl/Auto"]);
  OCMStub([flashModes[0] flashMode]).andReturn(AVCaptureFlashModeAuto);
  OCMStub([flashModes[1] title]).andReturn(@"Off");
  OCMStub([flashModes[1] iconURL]).andReturn([NSURL URLWithString:@"http://lightricks.owl/Off"]);
  OCMStub([flashModes[1] flashMode]).andReturn(AVCaptureFlashModeOff);

  device = [[CAMDeviceStub alloc] init];
  device.currentFlashMode = AVCaptureFlashModeAuto;
  device.hasFlash = YES;
  flashViewModel = [[CUIFlashMenuViewModel alloc] initWithFlashDevice:device flashModes:flashModes];
});

context(@"initialization", ^{
  it(@"should set the selected property to NO", ^{
    expect(flashViewModel.selected).to.beFalsy();
  });

  it(@"should set the hidden property to NO", ^{
    expect(flashViewModel.hidden).to.beFalsy();
  });

  it(@"should set the subitems with the given flash modes", ^{
    expect(flashViewModel.subitems).to.equal(flashModes);
  });

  context(@"enabled", ^{
    it(@"should match the device's hasFlash property", ^{
      device.hasFlash = NO;
      expect(flashViewModel.enabled).to.beFalsy();

      device.hasFlash = YES;
      expect(flashViewModel.enabled).to.beTruthy();
    });
  });
});

context(@"enabledSignal", ^{
  it(@"should update the enabled property", ^{
    RACSubject *enabledSignal = [[RACSubject alloc] init];
    flashViewModel.enabledSignal = enabledSignal;
    expect(flashViewModel.enabled).to.beTruthy();

    [enabledSignal sendNext:@NO];
    expect(flashViewModel.enabled).will.beFalsy();

    [enabledSignal sendNext:@YES];
    expect(flashViewModel.enabled).will.beTruthy();
  });
});

context(@"title", ^{
  it(@"should match the device's currentFlashMode", ^{
    expect(flashViewModel.title).to.equal(flashModes[0].title);

    device.currentFlashMode = flashModes[1].flashMode;
    expect(flashViewModel.title).will.equal(flashModes[1].title);

    device.currentFlashMode = flashModes[0].flashMode;
    expect(flashViewModel.title).will.equal(flashModes[0].title);
  });

  it(@"should be nil if currentFlashMode doesn't match the given modes", ^{
    expect(flashViewModel.title).to.equal(flashModes[0].title);

    device.currentFlashMode = kInvalidFlashMode;
    expect(flashViewModel.title).will.beNil();
  });
});

context(@"iconURL", ^{
  it(@"should match the device's currentFlashMode", ^{
    expect(flashViewModel.iconURL).to.equal(flashModes[0].iconURL);

    device.currentFlashMode = flashModes[1].flashMode;
    expect(flashViewModel.iconURL).will.equal(flashModes[1].iconURL);

    device.currentFlashMode = flashModes[0].flashMode;
    expect(flashViewModel.iconURL).will.equal(flashModes[0].iconURL);
  });

  it(@"should be nil if currentFlashMode doesn't match the given modes", ^{
    expect(flashViewModel.iconURL).to.equal(flashModes[0].iconURL);

    device.currentFlashMode = kInvalidFlashMode;
    expect(flashViewModel.iconURL).will.beNil();
  });
});

SpecEnd
