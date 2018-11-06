// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNMultiplexerAuthorizationManager.h"

#import "NSErrorCodes+Photons.h"
#import "PTNAuthorizationStatus.h"
#import "PTNNSURLTestUtils.h"

/// Fake \c PTNAuthorizationManager used for testing.
@interface PTNFakeAuthorizationManager : NSObject <PTNAuthorizationManager>

/// Signal returned for all \c requestAuthorizationFromViewController: requests.
@property (strong, nonatomic) RACSignal<PTNAuthorizationStatus *> *authorizationSignal;

/// Signal returned for all \c revokeAuthorization requests.
@property (strong, nonatomic) RACSignal *revocationSignal;

/// Current authorization status.
@property (strong, nonatomic) PTNAuthorizationStatus *authorizationStatus;

@end

@implementation PTNFakeAuthorizationManager

- (RACSignal<PTNAuthorizationStatus *> *)
    requestAuthorizationFromViewController:(UIViewController __unused *)viewController {
  return self.authorizationSignal;
}

- (RACSignal *)revokeAuthorization {
  return self.revocationSignal;
}

@end

SpecBegin(PTNMultiplexerAuthorizationManager)

// Valid scheme.
static NSString * const kScheme = @"com.lightricks.Photons.valid";

// Valid scheme.
static NSString * const kOtherScheme = @"com.lightricks.Photons.otherValid";

// Valid scheme being rejected.
static NSString * const kRejectedScheme = @"com.lightricks.Photons.rejected";

// Unconfigured scheme.
static NSString * const kUnconfiguredScheme = @"com.lightricks.Photons.unconfigured";

__block PTNMultiplexerAuthorizationManager *multiplexerManager;
__block PTNFakeAuthorizationManager *manager;
__block PTNFakeAuthorizationManager *otherManager;
__block id rejectingManager;

__block RACSignal *returnSignal;
__block NSURL *url;
__block UIViewController *viewController;

beforeEach(^{
  returnSignal = [[RACSignal alloc] init];
  
  manager = [[PTNFakeAuthorizationManager alloc] init];
  manager.authorizationSignal = returnSignal;
  manager.revocationSignal = returnSignal;
  manager.authorizationStatus = $(PTNAuthorizationStatusNotDetermined);
  otherManager = [[PTNFakeAuthorizationManager alloc] init];
  rejectingManager = OCMProtocolMock(@protocol(PTNAuthorizationManager));
  [[rejectingManager reject] requestAuthorizationFromViewController:OCMOCK_ANY];
  [[rejectingManager reject] revokeAuthorization];
  [[rejectingManager reject] authorizationStatus];
  
  multiplexerManager = [[PTNMultiplexerAuthorizationManager alloc] initWithSourceMapping:@{
    kScheme: manager,
    kOtherScheme: otherManager,
    kRejectedScheme: rejectingManager
  }];
  
  url = PTNCreateURL(kScheme, nil, nil);
  
  viewController = OCMClassMock(UIViewController.class);
});

context(@"authorization request", ^{
  it(@"should correctly forward authorization requests", ^{
    expect([multiplexerManager requestAuthorizationForScheme:kScheme
        fromViewController:viewController]).to.equal(returnSignal);
  });
  
  it(@"should error on authorization requests of unconfigured scheme", ^{
    expect([multiplexerManager requestAuthorizationForScheme:kUnconfiguredScheme
                                          fromViewController:viewController])
        .to.matchError(^BOOL(NSError *error) {
          return error.code == PTNErrorCodeUnrecognizedURLScheme;
        });
  });
});

context(@"revoke request", ^{
  it(@"should correctly forward revoke requests", ^{
    expect([multiplexerManager revokeAuthorizationForScheme:kScheme]).to.equal(returnSignal);
  });
  
  it(@"should error on revoke requests of unconfigured scheme", ^{
    expect([multiplexerManager revokeAuthorizationForScheme:kUnconfiguredScheme])
        .to.matchError(^BOOL(NSError *error) {
          return error.code == PTNErrorCodeUnrecognizedURLScheme;
        });
  });
});

context(@"authorization status", ^{
  it(@"should correctly forward current authorization status", ^{
    expect([multiplexerManager authorizationStatusForScheme:kScheme])
        .to.sendValues(@[$(PTNAuthorizationStatusNotDetermined)]);
  });

  it(@"should send updates when authorization status changes", ^{
    LLSignalTestRecorder *recorder = [[multiplexerManager authorizationStatusForScheme:kScheme]
                                      testRecorder];

    manager.authorizationStatus = $(PTNAuthorizationStatusAuthorized);
    manager.authorizationStatus = $(PTNAuthorizationStatusNotDetermined);
    manager.authorizationStatus = $(PTNAuthorizationStatusRestricted);

    expect(recorder).to.sendValues(@[
      $(PTNAuthorizationStatusNotDetermined),
      $(PTNAuthorizationStatusAuthorized),
      $(PTNAuthorizationStatusNotDetermined),
      $(PTNAuthorizationStatusRestricted)
    ]);
  });

  it(@"should error on status request of an unconfigured scheme", ^{
    expect([multiplexerManager authorizationStatusForScheme:kUnconfiguredScheme])
        .to.matchError(^BOOL(NSError *error) {
          return error.code == PTNErrorCodeUnrecognizedURLScheme;
        });
  });
});

context(@"authorized schemes", ^{
  __block PTNMultiplexerAuthorizationManager *authorizingManager;
  
  beforeEach(^{
    authorizingManager = [[PTNMultiplexerAuthorizationManager alloc] initWithSourceMapping:@{}
        authorizedSchemes:@[kScheme]];
  });
  
  it(@"should immediately authorize authorization requests", ^{
    expect([authorizingManager requestAuthorizationForScheme:kScheme
        fromViewController:viewController]).to.sendValues(@[$(PTNAuthorizationStatusAuthorized)]);
  });

  it(@"should immediately fail revocation requests", ^{
    expect([authorizingManager revokeAuthorizationForScheme:kScheme])
        .to.matchError(^BOOL(NSError *error){
      return error.code == PTNErrorCodeUnrecognizedURLScheme;
    });
  });

  it(@"should have a constant authorized authorization status", ^{
    expect([authorizingManager authorizationStatusForScheme:kScheme])
        .to.sendValues(@[$(PTNAuthorizationStatusAuthorized)]);
  });
});

SpecEnd
