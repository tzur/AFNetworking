// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitFakeAuthorizationManager.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNPhotoKitFakeAuthorizationManager

- (instancetype)init {
  if (self = [super init]) {
    self.authorizationStatus = PTNAuthorizationStatusAuthorized;
  }
  return self;
}

- (RACSignal *)requestAuthorizationFromViewController:(UIViewController __unused *)viewController {
  LTMethodNotImplemented();
}

@end

NS_ASSUME_NONNULL_END
