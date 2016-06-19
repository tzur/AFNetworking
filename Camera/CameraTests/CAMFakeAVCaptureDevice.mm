// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMFakeAVCaptureDevice.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMFakeAVCaptureDevice

- (BOOL)lockForConfiguration:(NSError *__autoreleasing *)errorPtr {
  _didLock = YES;

  if (self.lockError) {
    *errorPtr = self.lockError;
    return NO;
  } else {
    return YES;
  }
}

- (void)unlockForConfiguration {
  if (self.didLock) {
    _didUnlockWhileLocked = YES;
  }

  _didUnlock = YES;
}

- (void)setActiveFormat:(AVCaptureDeviceFormat __unused *)activeFormat {
}

- (BOOL)hasMediaType:(NSString *)mediaType {
  return [self.mediaTypes containsObject:mediaType];
}

@end

NS_ASSUME_NONNULL_END
