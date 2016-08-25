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

- (RACSignal *)requestAuthorizationFromViewController:(UIViewController __unused *)viewController {
  return [RACSignal return:$(PTNAuthorizationStatusAuthorized)];
}

- (PTNAuthorizationStatus *)authorizationStatus {
  return $(PTNAuthorizationStatusAuthorized);
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

- (RACSignal *)requestAuthorizationForScheme:(NSString *)scheme
                          fromViewController:(UIViewController *)viewController {
  id<PTNAuthorizationManager> authorizationManager = self.sourceMapping[scheme];
  if (!authorizationManager) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
        description:[NSString stringWithFormat:@"Unsupported scheme: %@", scheme]]];
  }
  
  return [authorizationManager requestAuthorizationFromViewController:viewController];
}

- (RACSignal *)revokeAuthorizationForScheme:(NSString *)scheme {
  id<PTNAuthorizationManager> authorizationManager = self.sourceMapping[scheme];
  if (![authorizationManager respondsToSelector:@selector(revokeAuthorization)]) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
        description:[NSString stringWithFormat:@"Unsupported scheme: %@", scheme]]];
  }
  
  return [authorizationManager revokeAuthorization];
}

- (nullable PTNAuthorizationStatus *)authorizationStatusForScheme:(NSString *)scheme {
  return self.sourceMapping[scheme].authorizationStatus;
}

@end

NS_ASSUME_NONNULL_END
