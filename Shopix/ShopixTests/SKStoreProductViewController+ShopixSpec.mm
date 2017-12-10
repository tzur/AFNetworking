// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "SKStoreProductViewController+Shopix.h"

SpecBegin(SKStoreProductViewController_Shopix)

static const auto kProductID = @1337;
static const auto kCampaign = @"foo";

context(@"product loading", ^{
  __block SKStoreProductViewController *viewController;

  beforeEach(^{
    viewController = OCMPartialMock([[SKStoreProductViewController alloc] init]);
  });

  afterEach(^{
    [(id)viewController stopMocking];
  });

  it(@"should load product with campaign", ^{
    const auto bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;

    OCMExpect([viewController
               loadProductWithParameters:[OCMArg checkWithBlock:^BOOL(NSDictionary *parameters) {
      if (![parameters[SKStoreProductParameterITunesItemIdentifier] isEqual:kProductID]) {
        return NO;
      } else if (!parameters[SKStoreProductParameterAffiliateToken]) {
        return NO;
      } else if (![((NSString *)parameters[SKStoreProductParameterCampaignToken])
            containsString:kCampaign]) {
        return NO;
      } else if (![bundleIdentifier
                   containsString:parameters[SKStoreProductParameterProviderToken]]) {
        return NO;
      }
      return YES;
    }] completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
      __unsafe_unretained void(^completion)(BOOL result, NSError * __nullable error);
      [invocation getArgument:&completion atIndex:3];
      completion(YES, nil);
    });

    waitUntil(^(DoneCallback done) {
      [viewController spx_loadProductWithProductID:kProductID campaign:kCampaign
                                        completion:^(BOOL success, NSError * _Nullable error) {
                                          expect(success).to.beTruthy();
                                          expect(error).to.beNil();

                                          done();
                                        }];
    });
  });

  it(@"should report loading failure", ^{
    OCMExpect(([viewController loadProductWithParameters:OCMOCK_ANY
                                         completionBlock:[OCMArg invokeBlockWithArgs:@NO,
                                                          [NSError lt_errorWithCode:1337], nil]]));

    waitUntil(^(DoneCallback done) {
      [viewController spx_loadProductWithProductID:kProductID campaign:kCampaign
                                        completion:^(BOOL success, NSError * _Nullable error) {
                                          expect(success).to.beFalsy();
                                          expect(error.lt_isLTDomain).to.beTruthy();
                                          expect(error.code).to.equal(1337);

                                          done();
                                        }];
    });
  });
});

typedef void (^SPXURLSessionCompletion)(NSData * _Nullable data,
                                        NSURLResponse * _Nullable response,
                                        NSError * _Nullable error);

context(@"tracking", ^{
  __block id<SPXCrossPromotionTracker> tracker;

  __block NSURLSession *session;
  __block NSURLSessionDataTask *dataTask;
  __block NSURL *url;
  __block SPXURLSessionCompletion completion;

  beforeEach(^{
    tracker = OCMProtocolMock(@protocol(SPXCrossPromotionTracker));

    session = OCMClassMock([NSURLSession class]);
    dataTask = OCMClassMock([NSURLSessionDataTask class]);
    url = [NSURL URLWithString:@"http://www.lightricks.com"];

    OCMStub([session dataTaskWithURL:url completionHandler:[OCMArg checkWithBlock:^BOOL(id obj) {
      completion = obj;
      return YES;
    }]]).andReturn(dataTask);
  });

  it(@"should call tracking service", ^{
    SPXTrackProductDisplay(tracker, kProductID, kCampaign, nil);

    OCMVerify([tracker trackWithProductID:kProductID.stringValue
                                 campaign:[OCMArg checkWithBlock:^BOOL(NSString *campaign) {
      return [campaign containsString:kCampaign];
    }] completion:OCMOCK_ANY]);
  });

  it(@"should report error if failed to load click URL", ^{
    OCMStub([dataTask resume]).andDo(^(NSInvocation *) {
      completion(nil, nil, [NSError lt_errorWithCode:1337]);
    });

    OCMStub(([tracker trackWithProductID:OCMOCK_ANY campaign:OCMOCK_ANY
                              completion:[OCMArg invokeBlockWithArgs:session, url, nil]]));

    waitUntil(^(DoneCallback done) {
      SPXTrackProductDisplay(tracker, kProductID, kCampaign,
                             ^(BOOL success, NSError * _Nullable error) {
                               expect(success).to.beFalsy();
                               expect(error.lt_isLTDomain).to.beTruthy();
                               expect(error.code).to.equal(1337);

                               done();
                             });
    });
  });

  it(@"should report success if link loaded successfully", ^{
    OCMStub([dataTask resume]).andDo(^(NSInvocation *) {
      completion(nil, nil, nil);
    });

    OCMStub(([tracker trackWithProductID:OCMOCK_ANY campaign:OCMOCK_ANY
                              completion:[OCMArg invokeBlockWithArgs:session, url, nil]]));

    waitUntil(^(DoneCallback done) {
      SPXTrackProductDisplay(tracker, kProductID, kCampaign,
                             ^(BOOL success, NSError * _Nullable error) {
                               expect(success).to.beTruthy();
                               expect(error).to.beNil();

                               done();
                             });
    });
  });
});

SpecEnd
