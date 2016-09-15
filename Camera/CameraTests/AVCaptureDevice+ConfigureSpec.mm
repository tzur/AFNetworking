// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "AVCaptureDevice+Configure.h"

#import "CAMFakeAVCaptureDevice.h"

SpecBegin(AVCaptureDevice_Configure)

__block CAMFakeAVCaptureDevice *device;

beforeEach(^{
  device = [[CAMFakeAVCaptureDevice alloc] init];
});

context(@"positive flows", ^{
  it(@"should lock and unlock", ^{
    NSError *error;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **) {
      return YES;
    } error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
    expect(device.didLock).to.beTruthy();
    expect(device.didUnlock).to.beTruthy();
    expect(device.didUnlockWhileLocked).to.beTruthy();
  });

  it(@"should perform while locked", ^{
    NSError *error;
    [device cam_performWhileLocked:^BOOL(NSError **) {
      expect(device.didLock).to.beTruthy();
      expect(device.didUnlock).to.beFalsy();
      return YES;
    } error:&error];
  });
});

context(@"negative flows", ^{
  static NSError * const kError = [NSError lt_errorWithCode:123];

  it(@"should propagate error and unlock after failing to lock", ^{
    NSError *error;

    device.lockError = kError;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **) {
      return YES;
    } error:&error];

    expect(success).to.beFalsy();
    expect(error).to.equal(kError);
    expect(device.didLock).to.beTruthy();
    expect(device.didUnlock).to.beTruthy();
    expect(device.didUnlockWhileLocked).to.beTruthy();
  });

  it(@"should propagate error and unlock after failing block", ^{
    NSError *error;

    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
      if (errorPtr) {
        *errorPtr = kError;
      }
      return NO;
    } error:&error];

    expect(success).to.beFalsy();
    expect(error).to.equal(kError);
    expect(device.didLock).to.beTruthy();
    expect(device.didUnlock).to.beTruthy();
    expect(device.didUnlockWhileLocked).to.beTruthy();
  });
});

SpecEnd
