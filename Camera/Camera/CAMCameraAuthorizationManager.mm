// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMCameraAuthorizationManager.h"

#import "CAMCameraAuthorizer.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAMCameraAuthorizationManager ()

/// Authorization handler.
@property (readonly, nonatomic) CAMCameraAuthorizer *authorizer;

/// Current Camera authorization status. This property is KVO compliant, but will only update
/// according to authorization requests made by the receiver.
@property (readwrite, nonatomic) AVAuthorizationStatus authorizationStatus;

@end

@implementation CAMCameraAuthorizationManager

+ (instancetype)videoAuthorizationManager {
  auto authorizer = [[CAMCameraAuthorizer alloc] initWithMediaType:AVMediaTypeVideo];
  return [[CAMCameraAuthorizationManager alloc] initWithCameraAuthorizer:authorizer];
}

+ (instancetype)audioAuthorizationManager {
  auto authorizer = [[CAMCameraAuthorizer alloc] initWithMediaType:AVMediaTypeAudio];
  return [[CAMCameraAuthorizationManager alloc] initWithCameraAuthorizer:authorizer];
}

- (instancetype)initWithCameraAuthorizer:(CAMCameraAuthorizer *)authorizer {
  if (self = [super init]) {
    _authorizer = authorizer;
    _authorizationStatus = authorizer.authorizationStatus;
  }
  return self;
}

- (RACSignal *)requestAuthorization {
  return [RACSignal defer:^RACSignal *{
    RACSignal *statusSignal = [[[RACObserve(self, authorizationStatus)
        skip:1]
        take:1]
        replayLast];

    [self.authorizer requestAuthorization:^(BOOL) {
      self.authorizationStatus = self.authorizer.authorizationStatus;
    }];

    return statusSignal;
  }];
}

@end

NS_ASSUME_NONNULL_END
