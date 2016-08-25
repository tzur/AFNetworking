// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNMultiplexerAuthorizationManager.h"

#import "NSErrorCodes+Photons.h"
#import "PTNAuthorizationStatus.h"
#import "PTNNSURLTestUtils.h"

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
__block id<PTNAuthorizationManager> manager;
__block id<PTNAuthorizationManager> otherManager;
__block id rejectingManager;

__block RACSignal *returnSignal;
__block NSURL *url;
__block UIViewController *viewController;

beforeEach(^{
  returnSignal = [[RACSignal alloc] init];
  
  manager = OCMProtocolMock(@protocol(PTNAuthorizationManager));
  OCMStub([manager requestAuthorizationFromViewController:OCMOCK_ANY]).andReturn(returnSignal);
  OCMStub([manager revokeAuthorization]).andReturn(returnSignal);
  OCMStub([manager authorizationStatus]).andReturn($(PTNAuthorizationStatusNotDetermined));
  otherManager = OCMProtocolMock(@protocol(PTNAuthorizationManager));
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
    OCMVerify([manager requestAuthorizationFromViewController:viewController]);
  });
  
  it(@"should error on authorization requests of unconfigured scheme", ^{
    expect([multiplexerManager requestAuthorizationForScheme:kUnconfiguredScheme
                                          fromViewController:viewController])
        .to.matchError(^BOOL(NSError *error){
          return error.code == PTNErrorCodeUnrecognizedURLScheme;
        });
  });
});

context(@"revoke request", ^{
  it(@"should correctly forward revoke requests", ^{
    expect([multiplexerManager revokeAuthorizationForScheme:kScheme]).to.equal(returnSignal);
    OCMVerify([manager revokeAuthorization]);
  });
  
  it(@"should error on revoke requests of unconfigured scheme", ^{
    expect([multiplexerManager revokeAuthorizationForScheme:kUnconfiguredScheme])
        .to.matchError(^BOOL(NSError *error){
          return error.code == PTNErrorCodeUnrecognizedURLScheme;
        });
  });
});

context(@"authorization status", ^{
  it(@"should correctly forward authorization status", ^{
    expect([multiplexerManager authorizationStatusForScheme:kScheme])
        .to.equal($(PTNAuthorizationStatusNotDetermined));
    OCMVerify([manager authorizationStatus]);
  });
  
  it(@"should return nil status for unconfigured scheme", ^{
    expect([multiplexerManager authorizationStatusForScheme:kUnconfiguredScheme]).to.beNil();
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
        .to.equal($(PTNAuthorizationStatusAuthorized));
  });
});

SpecEnd
