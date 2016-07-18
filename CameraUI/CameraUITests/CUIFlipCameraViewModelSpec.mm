// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIFlipCameraViewModel.h"

#import <Camera/CAMDevicePreset.h>

#import "CAMDeviceStub.h"

SpecBegin(CUIFlipCameraViewModel)

__block CUIFlipCameraViewModel *flipViewModel;
__block CAMDeviceStub *device;
__block NSString *title;
__block NSURL *iconURL;

beforeEach(^{
  title = @"foo";
  iconURL = [NSURL URLWithString:@"http://any.url"];
  device = [[CAMDeviceStub alloc] init];
  flipViewModel =
      [[CUIFlipCameraViewModel alloc] initWithFlipDevice:device title:title iconURL:iconURL];
});

context(@"initialization", ^{
  it(@"should raise an exception when initialized with nil flip device", ^{
    CAMDeviceStub *nilDevice = nil;
    expect(^{
      CUIFlipCameraViewModel * __unused flipViewModel =
          [[CUIFlipCameraViewModel alloc] initWithFlipDevice:nilDevice title:title iconURL:iconURL];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should set the title to the given title", ^{
    expect(flipViewModel.title).to.equal(title);
  });

  it(@"should set the iconURL to the given icon URL", ^{
    expect(flipViewModel.iconURL).to.equal(iconURL);
  });

  it(@"should set the selected property to NO", ^{
    expect(flipViewModel.selected).to.beFalsy();
  });
  
  it(@"should set the hidden property to NO", ^{
    expect(flipViewModel.hidden).to.beFalsy();
  });

  it(@"should set the subitems to nil", ^{
    expect(flipViewModel.subitems).to.beNil();
  });
});

context(@"didTap", ^{
  it(@"should subscribe to the signal returned from the device's setCamera", ^{
    device.canChangeCamera = YES;
    device.activeCamera = $(CAMDeviceCameraBack);
    device.setCameraSignal = [RACSignal return:[RACUnit defaultUnit]];
    [device.setCameraSignal startCountingSubscriptions];
    
    expect(device.setCameraSignal.subscriptionCount).to.equal(0);
    [flipViewModel didTap];
    expect(device.setCameraSignal.subscriptionCount).will.equal(1);
    
    [device.setCameraSignal stopCountingSubscriptions];
  });

  it(@"should not call the device's setCamera when the device's canChangeCamera is NO", ^{
    device.canChangeCamera = NO;
    device.setCameraWasCalled = NO;
    device.activeCamera = $(CAMDeviceCameraBack);
    [flipViewModel didTap];

    expect(device.setCameraWasCalled).to.beFalsy;
  });
});

SpecEnd
