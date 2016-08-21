// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxAuthorizationManager.h"

#import <DropboxSDK/DropboxSDK.h>

#import "NSError+Photons.h"
#import "PTNAuthorizationStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDropboxAuthorizationManager () <DBSessionDelegate>

/// Current authorization status, as a readwrite KVO compliant variable.
@property (readwrite, nonatomic) PTNAuthorizationStatus *authorizationStatus;

@end

@implementation PTNDropboxAuthorizationManager

- (instancetype)initWithDropboxSession:(DBSession *)dropboxSession {
  if (self = [super init]) {
    _dropboxSession = dropboxSession;
    self.dropboxSession.delegate = self;
    [self updateAuthorizationStatus];
  }
  return self;
}

#pragma mark -
#pragma mark PTNAuthorizationManager
#pragma mark -

- (RACSignal *)requestAuthorizationFromViewController:(UIViewController *)viewController {
  @weakify(self)
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self)
    [self updateAuthorizationStatus];
    if ([self.authorizationStatus isEqual:$(PTNAuthorizationStatusAuthorized)]) {
      [subscriber sendNext:self.authorizationStatus];
      [subscriber sendCompleted];

      return nil;
    }

    [[[RACObserve(self, authorizationStatus)
        skip:1]
        take:1]
        subscribe:subscriber];

    [self.dropboxSession linkFromController:viewController];

    return nil;
  }];
}

- (RACSignal *)revokeAuthorization {
  @weakify(self)
  return [RACSignal defer:^{
    @strongify(self)
    [self.dropboxSession unlinkAll];
    [self updateAuthorizationStatus];

    return [RACSignal empty];
  }];
}

#pragma mark -
#pragma mark PTNOpenURLHandler
#pragma mark -

- (BOOL)application:(UIApplication __unused *)app openURL:(NSURL *)url
            options:(nullable NSDictionary<NSString *, id> __unused *)options {
  if ([self.dropboxSession handleOpenURL:url]) {
    [self updateAuthorizationStatus];
    return YES;
  }

  return NO;
}

#pragma mark -
#pragma mark DBSessionDelegate
#pragma mark -

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session
                                       userId:(NSString * __unused)userId {
  if (self.dropboxSession != session) {
    return;
  }
  
  [self updateAuthorizationStatus];
}

- (void)updateAuthorizationStatus {
  self.authorizationStatus = self.dropboxSession.isLinked ?
      $(PTNAuthorizationStatusAuthorized) : $(PTNAuthorizationStatusNotDetermined);
}

@end

NS_ASSUME_NONNULL_END
