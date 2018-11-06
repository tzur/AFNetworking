// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNMultiplexerAuthorizationManager.h"

#import "NSError+Photons.h"
#import "PTNAuthorizationStatus.h"

NS_ASSUME_NONNULL_BEGIN

/// A \c PTNAuthorizationManager implementation simulating an authorized source. The manager returns
/// a signal that immediately completes for every authorization or authorization revoking request
/// and has a constant authorization status of \c PTNAuthorizationStatusAuthorized.
@interface PTNAcceptingAuthorizationManager : NSObject <PTNAuthorizationManager>
@end

@implementation PTNAcceptingAuthorizationManager

@synthesize authorizationStatus = _authorizationStatus;

- (instancetype)init {
  if (self = [super init]) {
    _authorizationStatus = $(PTNAuthorizationStatusAuthorized);
  }
  return self;
}

- (RACSignal<PTNAuthorizationStatus *> *)
    requestAuthorizationFromViewController:(UIViewController __unused *)viewController {
  return [RACSignal return:$(PTNAuthorizationStatusAuthorized)];
}

@end

@implementation PTNMultiplexerAuthorizationManager

- (instancetype)initWithSourceMapping:(PTNSchemeToAuthorizerMap *)sourceMapping {
  if (self = [super init]) {
    _sourceMapping = sourceMapping;
  }
  return self;
}

- (instancetype)initWithSourceMapping:(PTNSchemeToAuthorizerMap *)sourceMapping
              authorizedSchemes:(NSArray<NSString *> *)authorizedSchemes {
  NSMutableDictionary<NSString *, id<PTNAuthorizationManager>> *map = [sourceMapping mutableCopy];

  id<PTNAuthorizationManager> acceptingManager = [[PTNAcceptingAuthorizationManager alloc] init];
  for (NSString *scheme in authorizedSchemes) {
    map[scheme] = acceptingManager;
  }

  return [self initWithSourceMapping:map];
}

- (RACSignal<PTNAuthorizationStatus *> *)
    requestAuthorizationForScheme:(NSString *)scheme
    fromViewController:(UIViewController *)viewController {
  _Nullable id<PTNAuthorizationManager> authorizationManager = self.sourceMapping[scheme];
  if (!authorizationManager) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                          description:@"Unsupported scheme: %@", scheme]];
  }

  return [authorizationManager requestAuthorizationFromViewController:viewController];
}

- (RACSignal *)revokeAuthorizationForScheme:(NSString *)scheme {
  _Nullable id<PTNAuthorizationManager> authorizationManager = self.sourceMapping[scheme];
  if (![authorizationManager respondsToSelector:@selector(revokeAuthorization)]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                          description:@"Unsupported scheme: %@", scheme]];
  }

  return [authorizationManager revokeAuthorization];
}

- (RACSignal<PTNAuthorizationStatus *> *)authorizationStatusForScheme:(NSString *)scheme {
  _Nullable id<PTNAuthorizationManager> authorizationManager = self.sourceMapping[scheme];
  if (!authorizationManager) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                          description:@"Unsupported scheme: %@", scheme]];
  }

  return RACObserve(authorizationManager, authorizationStatus);
}

@end

NS_ASSUME_NONNULL_END
