// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitAuthorizationManager.h"

#import "NSError+Photons.h"
#import "PTNPhotoKitAuthorizer.h"

NS_ASSUME_NONNULL_BEGIN

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
      if (status == PTNAuthorizationStatusAuthorized) {
        [subscriber sendCompleted];
      } else if (status == PTNAuthorizationStatusDenied ||
                 status == PTNAuthorizationStatusRestricted) {
        [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeAuthorizationFailed]];
      }
    }];

    return nil;
  }];
}

- (PTNAuthorizationStatus)authorizationStatus {
  return [self translatePhotoKitAuthorizationStatus:self.authorizer.authorizationStatus];
}

- (PTNAuthorizationStatus)translatePhotoKitAuthorizationStatus:(PHAuthorizationStatus)status {
  switch (status) {
    case PHAuthorizationStatusAuthorized:
      return PTNAuthorizationStatusAuthorized;
    case PHAuthorizationStatusDenied:
      return PTNAuthorizationStatusDenied;
    case PHAuthorizationStatusRestricted:
      return PTNAuthorizationStatusRestricted;
    case PHAuthorizationStatusNotDetermined:
      return PTNAuthorizationStatusNotDetermined;
  }
}

@end

NS_ASSUME_NONNULL_END
