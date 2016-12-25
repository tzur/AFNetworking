// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMCameraAuthorizer.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMCameraAuthorizer

- (void)requestAuthorization:(CAMAuthorizationStatusHandler)handler {
  [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:handler];
}

- (AVAuthorizationStatus)authorizationStatus {
  return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
}

@end

NS_ASSUME_NONNULL_END
