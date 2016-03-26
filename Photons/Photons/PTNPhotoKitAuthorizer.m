// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitAuthorizer.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNPhotoKitAuthorizer

- (void)requestAuthorization:(PTNAuthorizationStatusHandler)handler {
  [PHPhotoLibrary requestAuthorization:handler];
}

- (PHAuthorizationStatus)authorizationStatus {
  return [PHPhotoLibrary authorizationStatus];
}

@end

NS_ASSUME_NONNULL_END
