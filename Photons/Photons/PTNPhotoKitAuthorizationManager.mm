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

@end

@implementation PTNPhotoKitAuthorizationManager

- (instancetype)initWithPhotoKitAuthorizer:(PTNPhotoKitAuthorizer *)authorizer {
  if (self = [super init]) {
    _authorizer = authorizer;
  }
  return self;
}

#pragma mark -
#pragma mark PTNAuthorizationManager
#pragma mark -

- (RACSignal *)requestAuthorizationFromViewController:(UIViewController __unused *)viewController {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [self.authorizer requestAuthorization:^(PHAuthorizationStatus status) {
      [subscriber sendNext:[PTNAuthorizationStatus enumWithPhotoKitStatus:status]];
      [subscriber sendCompleted];
    }];

    return nil;
  }];
}

- (PTNAuthorizationStatus *)authorizationStatus {
  return [PTNAuthorizationStatus enumWithPhotoKitStatus:self.authorizer.authorizationStatus];
}

@end

NS_ASSUME_NONNULL_END
