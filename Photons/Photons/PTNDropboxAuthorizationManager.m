// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxAuthorizationManager.h"

#import <DropboxSDK/DropboxSDK.h>

#import "DBSession+RACSignalSupport.h"
#import "NSError+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDropboxAuthorizationManager ()

/// Current authorization status, as a readwrite KVO compliant variable.
@property (readwrite, nonatomic) PTNAuthorizationStatus authorizationStatus;

@end

@implementation PTNDropboxAuthorizationManager

- (instancetype)initWithDropboxSession:(DBSession *)dropboxSession {
  if (self = [super init]) {
    _dropboxSession = dropboxSession;
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
    if (self.dropboxSession.isLinked) {
      self.authorizationStatus = PTNAuthorizationStatusAuthorized;
      [subscriber sendCompleted];

      return nil;
    }

    [[[self.dropboxSession ptn_authorizationFailureSignal]
        flattenMap:^RACStream *(id __unused value) {
          return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAuthorizationFailed]];
        }]
        subscribe:subscriber];

    [[[[RACObserve(self, authorizationStatus)
        skip:1]
        take:1]
        ignoreValues]
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

- (void)updateAuthorizationStatus {
  self.authorizationStatus = self.dropboxSession.isLinked ?
      PTNAuthorizationStatusAuthorized : PTNAuthorizationStatusNotDetermined;
}

@end

NS_ASSUME_NONNULL_END
