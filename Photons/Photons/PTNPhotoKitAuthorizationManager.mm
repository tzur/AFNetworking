// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitAuthorizationManager.h"

#import "NSError+Photons.h"
#import "PTNAuthorizationStatus.h"
#import "PTNPhotoKitAuthorizer.h"

NS_ASSUME_NONNULL_BEGIN

/// Category over \c PTNAuthorizationStatus providing convenience mapping from PhotoKit
/// authorization statuses.
@interface PTNAuthorizationStatus (PhotoKit)

/// Returns a new enum object corresponding to the given \c status.
+ (instancetype)enumWithPhotoKitStatus:(PHAuthorizationStatus)status;

@end

@implementation PTNAuthorizationStatus (PhotoKit)

+ (instancetype)enumWithPhotoKitStatus:(PHAuthorizationStatus)status {
  switch (status) {
    case PHAuthorizationStatusAuthorized:
      return $(PTNAuthorizationStatusAuthorized);
    case PHAuthorizationStatusDenied:
      return $(PTNAuthorizationStatusDenied);
    case PHAuthorizationStatusRestricted:
      return $(PTNAuthorizationStatusRestricted);
    case PHAuthorizationStatusNotDetermined:
      return $(PTNAuthorizationStatusNotDetermined);
  }
}

@end

@interface PTNPhotoKitAuthorizationManager ()

/// Authorization handler of the PhotoKit photo library.
@property (readonly, nonatomic) PTNPhotoKitAuthorizer *authorizer;

/// Current authorization status of this source. This property is KVO compliant, but will only
/// update according to authorization requests made by the receiver.
@property (strong, nonatomic) PTNAuthorizationStatus *authorizationStatus;

@end

@implementation PTNPhotoKitAuthorizationManager

@synthesize authorizationStatus = _authorizationStatus;

- (instancetype)initWithPhotoKitAuthorizer:(PTNPhotoKitAuthorizer *)authorizer {
  if (self = [super init]) {
    _authorizer = authorizer;
    _authorizationStatus = [PTNAuthorizationStatus
                            enumWithPhotoKitStatus:authorizer.authorizationStatus];
  }
  return self;
}

#pragma mark -
#pragma mark PTNAuthorizationManager
#pragma mark -

- (RACSignal<PTNAuthorizationStatus *> *)
    requestAuthorizationFromViewController:(UIViewController __unused *)viewController {
  return [RACSignal defer:^RACSignal *{
    RACSignal *statusSignal = [[[RACObserve(self, authorizationStatus)
        skip:1]
        take:1]
        replayLast];

    [self.authorizer requestAuthorization:^(PHAuthorizationStatus status) {
      self.authorizationStatus = [PTNAuthorizationStatus enumWithPhotoKitStatus:status];
    }];

    return statusSignal;
  }];
}

@end

NS_ASSUME_NONNULL_END
