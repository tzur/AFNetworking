// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNMediaLibraryAuthorizationManager.h"

#import <MediaPlayer/MediaPlayer.h>

#import "PTNAuthorizationStatus.h"
#import "PTNMediaLibraryAuthorizer.h"

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting \c PTNAuthorizationStatus by adding convenience mapping from Media Library
/// authorization statuses.
@interface PTNAuthorizationStatus (MediaPlayer)

/// Returns a new \c PTNAuthorizationStatus object corresponding to the given authorization
/// \c status.
+ (instancetype)statusWithMediaLibraryStatus:(MPMediaLibraryAuthorizationStatus)status;

@end

@implementation PTNAuthorizationStatus (MediaPlayer)

+ (instancetype)statusWithMediaLibraryStatus:(MPMediaLibraryAuthorizationStatus)status {
  switch (status) {
    case MPMediaLibraryAuthorizationStatusAuthorized:
      return $(PTNAuthorizationStatusAuthorized);
    case MPMediaLibraryAuthorizationStatusDenied:
      return $(PTNAuthorizationStatusDenied);
    case MPMediaLibraryAuthorizationStatusRestricted:
      return $(PTNAuthorizationStatusRestricted);
    case MPMediaLibraryAuthorizationStatusNotDetermined:
    default:
      return $(PTNAuthorizationStatusNotDetermined);
    }
}

@end

@interface PTNMediaLibraryAuthorizationManager ()

/// Authorization handler of the Media Library.
@property (readonly, nonatomic) PTNMediaLibraryAuthorizer *authorizer;

/// Current authorization status of this source. This property is KVO compliant, but will only
/// update according to authorization requests made by the receiver.
@property (strong, nonatomic) PTNAuthorizationStatus *authorizationStatus;

@end

@implementation PTNMediaLibraryAuthorizationManager

@synthesize authorizationStatus = _authorizationStatus;

#pragma mark -
#pragma mark Initialization
#pragma mark -

-(instancetype)init {
  return [self initWithAuthorizer:[[PTNMediaLibraryAuthorizer alloc] init]];
}

- (instancetype)initWithAuthorizer:(PTNMediaLibraryAuthorizer *)authorizer {
  if (self = [super init]) {
    _authorizer = authorizer;
    _authorizationStatus = [PTNAuthorizationStatus
                            statusWithMediaLibraryStatus:authorizer.authorizationStatus];
  }
  return self;
}

#pragma mark -
#pragma mark PTNAuthorizationManager
#pragma mark -

- (RACSignal *)requestAuthorizationFromViewController:(UIViewController __unused *)viewController {
  return [RACSignal defer:^RACSignal *{
    RACSignal *statusSignal = [[[RACObserve(self, authorizationStatus)
        skip:1]
        take:1]
        replayLast];

    [self.authorizer requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
      self.authorizationStatus = [PTNAuthorizationStatus statusWithMediaLibraryStatus:status];
    }];

    return statusSignal;
  }];
}

@end

NS_ASSUME_NONNULL_END
