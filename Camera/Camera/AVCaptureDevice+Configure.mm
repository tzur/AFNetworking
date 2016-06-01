// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "AVCaptureDevice+Configure.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AVCaptureDevice (Configure)

- (BOOL)cam_performWhileLocked:(CAMErrorReturnBlock)action
                         error:(NSError *__autoreleasing *)errorPtr {
  LTParameterAssert(action, @"action block must be non-nil");
  BOOL success;

  success = [self lockForConfiguration:errorPtr];
  if (success) {
    success = action(errorPtr);
  }
  [self unlockForConfiguration];

  return success;
}

@end

NS_ASSUME_NONNULL_END
