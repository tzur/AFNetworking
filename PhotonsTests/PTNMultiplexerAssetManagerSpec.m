// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNMultiplexerAssetManager.h"

#import "NSError+Photons.h"
#import "PTNMultiplexingTestUtils.h"
#import "PTNNSURLTestUtils.h"

SpecBegin(PTNMultiplexerAssetManager)

static NSString * const schemeA = @"com.lightricks.Photons.A";
static NSString * const schemeB = @"com.lightricks.Photons.B";
static NSString * const schemeC = @"com.lightricks.Photons.C";

__block id<PTNAssetManager> multiplexerManager;
__block id<PTNAssetManager> managerA;
__block id<PTNAssetManager> managerB;
__block RACSignal *returnSignal;

beforeEach(^{
  returnSignal = OCMClassMock([RACSignal class]);
  managerA = PTNCreateAcceptingManager(returnSignal);
  managerB = PTNCreateRejectingManager();
  multiplexerManager = [[PTNMultiplexerAssetManager alloc] initWithSources:@{
    schemeA: managerA,
    schemeB: managerB,
  }];
});

context(@"album fetching", ^{
  it(@"should correctly forward album requests", ^{
    NSURL *url = PTNCreateURL(schemeA, nil, nil);
    expect([multiplexerManager fetchAlbumWithURL:url]).to.equal(returnSignal);
    OCMVerify([managerA fetchAlbumWithURL:url]);
  });

  it(@"should error on album requests with unconfigured scheme", ^{
    NSURL *url = PTNCreateURL(schemeC, nil, nil);
    expect([multiplexerManager fetchAlbumWithURL:url]).to.matchError(^BOOL(NSError *error){
      return error.code == PTNErrorCodeUnrecognizedURLScheme;
    });
  });
});

context(@"asset fetching", ^{
  it(@"should correctly forward asset requests", ^{
    NSURL *url = PTNCreateURL(schemeA, nil, nil);
    expect([multiplexerManager fetchAssetWithURL:url]).to.equal(returnSignal);
    OCMVerify([managerA fetchAssetWithURL:url]);
  });

  it(@"should error on asset requests with unconfigured scheme", ^{
    NSURL *url = PTNCreateURL(schemeC, nil, nil);
    expect([multiplexerManager fetchAssetWithURL:url]).to.matchError(^BOOL(NSError *error){
      return error.code == PTNErrorCodeUnrecognizedURLScheme;
    });
  });
});

context(@"image fetching", ^{
  __block id<PTNResizingStrategy> strategy;
  __block PTNImageFetchOptions *options;

  beforeEach(^{
    strategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
    options = OCMClassMock([PTNImageFetchOptions class]);
  });

  it(@"should correctly forward image requests", ^{
    NSURL *url = PTNCreateURL(schemeA, nil, nil);
    id<PTNDescriptor> descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    OCMStub([descriptor ptn_identifier]).andReturn(url);

    RACSignal *signal = [multiplexerManager fetchImageWithDescriptor:descriptor
                                                    resizingStrategy:strategy
                                                             options:options];
    expect(signal).to.equal(returnSignal);
    OCMVerify([managerA fetchImageWithDescriptor:descriptor resizingStrategy:strategy
                                         options:options]);
  });

  it(@"should error on image requests with unconfigured scheme", ^{
    NSURL *url = PTNCreateURL(schemeC, nil, nil);
    id<PTNDescriptor> descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    OCMStub([descriptor ptn_identifier]).andReturn(url);

    RACSignal *signal = [multiplexerManager fetchImageWithDescriptor:descriptor
                                                    resizingStrategy:strategy
                                                             options:options];
    expect(signal).to.matchError(^BOOL(NSError *error){
      return error.code == PTNErrorCodeUnrecognizedURLScheme;
    });
  });
});

SpecEnd
