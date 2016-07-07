// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIFlashModeViewModel.h"

SpecBegin(CUIFlashModeViewModel)

__block CUIFlashModeViewModel *flashModeViewModel;
__block AVCaptureFlashMode flashMode;
__block AVCaptureFlashMode otherFlashMode;
__block NSString *title;
__block NSURL *iconURL;
__block CAMDeviceStub *device;

beforeEach(^{
  flashMode = AVCaptureFlashModeAuto;
  otherFlashMode = AVCaptureFlashModeOff;
  device = [[CAMDeviceStub alloc] init];
  device.currentFlashMode = flashMode;
  title = @"Auto";
  iconURL = [NSURL URLWithString:@"http://lightricks.owl"];
  flashModeViewModel = [[CUIFlashModeViewModel alloc] initWithFlashDevice:device
                                                                flashMode:flashMode title:title
                                                                  iconURL:iconURL];
});

context(@"initialization", ^{
  it(@"should raise an exception when initialized with nil camera device", ^{
    id<CAMDevice> device = nil;
    expect(^{
      CUIFlashModeViewModel * __unused flashModeViewModel =
          [[CUIFlashModeViewModel alloc] initWithFlashDevice:device flashMode:flashMode
                                                       title:title iconURL:iconURL];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should set the object's flashMode to the given flash mode", ^{
    expect(flashModeViewModel.flashMode).to.equal(flashMode);
  });

  it(@"should set the title to the given title", ^{
    expect(flashModeViewModel.title).to.equal(title);
  });
  
  it(@"should set the iconURL to the given icon URL", ^{
    expect(flashModeViewModel.iconURL).to.equal(iconURL);
  });

  it(@"should set the hidden property to NO", ^{
    expect(flashModeViewModel.hidden).to.beFalsy();
  });

  it(@"should set the subitems to nil", ^{
    expect(flashModeViewModel.subitems).to.beNil();
  });
});

context(@"selected", ^{
  it(@"should match the device's currentFlashMode", ^{
    expect(flashModeViewModel.selected).will.beTruthy();

    device.currentFlashMode = otherFlashMode;
    expect(flashModeViewModel.selected).will.beFalsy();

    device.currentFlashMode = flashMode;
    expect(flashModeViewModel.selected).will.beTruthy();
  });
});

context(@"didTap", ^{
  it(@"should subscribe to the signal returned from the device's setFlashMode", ^{
    device.currentFlashMode = otherFlashMode;
    LLSignalTestRecorder *recorder = [[RACSignal return:[RACUnit defaultUnit]] testRecorder];
    device.setFlashModeSignal = recorder;
    [recorder startCountingSubscriptions];
    
    expect(recorder.subscriptionCount).to.equal(0);
    [flashModeViewModel didTap];
    expect(recorder.subscriptionCount).will.equal(1);
    
    [recorder stopCountingSubscriptions];
  });
});

SpecEnd
