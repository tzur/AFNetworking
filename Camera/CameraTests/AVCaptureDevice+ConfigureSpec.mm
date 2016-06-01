// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "AVCaptureDevice+Configure.h"

/// Fake \c AVCaptureDevice for testing purposes. Records whether \c lockForConfiguration: and
/// \c unlockForConfiguration were called, and in what order they were called. Can be configured to
/// err in \c lockForConfiguration:.
@interface CAMFakeAVCaptureDevice : AVCaptureDevice
@property (strong, nonatomic) NSError *lockError;
@property (nonatomic) BOOL didLock;
@property (nonatomic) BOOL didUnlock;
@property (nonatomic) BOOL didUnlockWhileLocked;
@end

@implementation CAMFakeAVCaptureDevice

- (BOOL)lockForConfiguration:(NSError *__autoreleasing *)errorPtr {
  self.didLock = YES;

  if (self.lockError) {
    *errorPtr = self.lockError;
    return NO;
  } else {
    return YES;
  }
}

- (void)unlockForConfiguration {
  if (self.didLock) {
    self.didUnlockWhileLocked = YES;
  }

  self.didUnlock = YES;
}

@end

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
      *errorPtr = kError;
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
