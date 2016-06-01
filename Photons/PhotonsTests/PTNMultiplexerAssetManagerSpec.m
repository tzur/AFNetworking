// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNMultiplexerAssetManager.h"

#import "NSError+Photons.h"
#import "PTNDescriptor.h"
#import "PTNImageFetchOptions.h"
#import "PTNMultiplexingTestUtils.h"
#import "PTNNSURLTestUtils.h"
#import "PTNResizingStrategy.h"

SpecBegin(PTNMultiplexerAssetManager)

// Valid scheme.
static NSString * const kSchemeA = @"com.lightricks.Photons.A";

// Valid scheme.
static NSString * const kSchemeB = @"com.lightricks.Photons.B";

// Valid scheme being rejected.
static NSString * const kSchemeC = @"com.lightricks.Photons.C";

// Unconfigured scheme.
static NSString * const kSchemeD = @"com.lightricks.Photons.D";

__block id<PTNAssetManager> multiplexerManager;
__block id managerA;
__block id managerB;
__block id managerC;
__block RACSubject *returnSignalA;
__block RACSubject *returnSignalB;
__block id<PTNDescriptor> descriptorA;
__block id<PTNDescriptor> descriptorB;
__block id<PTNDescriptor> descriptorC;
__block id<PTNDescriptor> descriptorD;

beforeEach(^{
  returnSignalA = [RACReplaySubject replaySubjectWithCapacity:RACReplaySubjectUnlimitedCapacity];
  returnSignalB = [RACReplaySubject replaySubjectWithCapacity:RACReplaySubjectUnlimitedCapacity];

  managerA = PTNCreateAcceptingManager(returnSignalA);
  managerB = PTNCreateAcceptingManager(returnSignalB);
  managerC = PTNCreateRejectingManager();
  multiplexerManager = [[PTNMultiplexerAssetManager alloc] initWithSources:@{
    kSchemeA: managerA,
    kSchemeB: managerB,
    kSchemeC: managerC
  }];

  descriptorA = OCMProtocolMock(@protocol(PTNDescriptor));
  OCMStub([descriptorA ptn_identifier]).andReturn(PTNCreateURL(kSchemeA, nil, nil));
  descriptorB = OCMProtocolMock(@protocol(PTNDescriptor));
  OCMStub([descriptorB ptn_identifier]).andReturn(PTNCreateURL(kSchemeB, nil, nil));
  descriptorC = OCMProtocolMock(@protocol(PTNDescriptor));
  OCMStub([descriptorC ptn_identifier]).andReturn(PTNCreateURL(kSchemeC, nil, nil));
  descriptorD = OCMProtocolMock(@protocol(PTNDescriptor));
  OCMStub([descriptorD ptn_identifier]).andReturn(PTNCreateURL(kSchemeD, nil, nil));
});

context(@"album fetching", ^{
  it(@"should correctly forward album requests", ^{
    NSURL *url = PTNCreateURL(kSchemeA, nil, nil);
    expect([multiplexerManager fetchAlbumWithURL:url]).to.equal(returnSignalA);
    OCMVerify([managerA fetchAlbumWithURL:url]);
  });

  it(@"should error on album requests with unconfigured scheme", ^{
    NSURL *url = PTNCreateURL(kSchemeD, nil, nil);
    expect([multiplexerManager fetchAlbumWithURL:url]).to.matchError(^BOOL(NSError *error){
      return error.code == PTNErrorCodeUnrecognizedURLScheme;
    });
  });
});

context(@"asset fetching", ^{
  it(@"should correctly forward asset requests", ^{
    NSURL *url = PTNCreateURL(kSchemeA, nil, nil);
    expect([multiplexerManager fetchDescriptorWithURL:url]).to.equal(returnSignalA);
    OCMVerify([managerA fetchDescriptorWithURL:url]);
  });

  it(@"should error on asset requests with unconfigured scheme", ^{
    NSURL *url = PTNCreateURL(kSchemeD, nil, nil);
    expect([multiplexerManager fetchDescriptorWithURL:url]).to.matchError(^BOOL(NSError *error){
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
    RACSignal *signal = [multiplexerManager fetchImageWithDescriptor:descriptorA
                                                    resizingStrategy:strategy
                                                             options:options];
    expect(signal).to.equal(returnSignalA);
    OCMVerify([managerA fetchImageWithDescriptor:descriptorA resizingStrategy:strategy
                                         options:options]);
  });

  it(@"should error on image requests with unconfigured scheme", ^{
    RACSignal *signal = [multiplexerManager fetchImageWithDescriptor:descriptorD
                                                    resizingStrategy:strategy
                                                             options:options];
    expect(signal).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeUnrecognizedURLScheme;
    });
  });
});

context(@"changes", ^{
  context(@"asset deletion", ^{
    it(@"should forward delete requests to underlying managers", ^{
      RACSignal *values = [multiplexerManager deleteDescriptors:@[descriptorA, descriptorB]];

      [returnSignalA sendCompleted];
      expect(values).notTo.finish();

      [returnSignalB sendCompleted];
      expect(values).will.finish();

      OCMVerify([managerA deleteDescriptors:@[descriptorA]]);
      OCMVerify([managerB deleteDescriptors:@[descriptorB]]);
    });

    it(@"should forward errors when underlying managers errs", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      [returnSignalB sendError:error];

      RACSignal *values = [multiplexerManager deleteDescriptors:@[descriptorA, descriptorB]];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == 1337;
      });
    });

    it(@"should err when one or more given descriptors have an unconfigured scheme", ^{
      RACSignal *values = [multiplexerManager deleteDescriptors:@[descriptorA, descriptorD]];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeUnrecognizedURLScheme &&
            [error.ptn_associatedDescriptors isEqual:@[descriptorD]];
      });
    });
  });

  context(@"asset removal", ^{
    __block id<PTNAlbumDescriptor> albumDescriptorA;
    __block id<PTNAlbumDescriptor> albumDescriptorB;
    __block id<PTNAlbumDescriptor> albumDescriptorD;

    beforeEach(^{
      albumDescriptorA = OCMProtocolMock(@protocol(PTNAlbumDescriptor));
      OCMStub([albumDescriptorA ptn_identifier]).andReturn(PTNCreateURL(kSchemeA, nil, nil));
      albumDescriptorB = OCMProtocolMock(@protocol(PTNAlbumDescriptor));
      OCMStub([albumDescriptorB ptn_identifier]).andReturn(PTNCreateURL(kSchemeB, nil, nil));
      albumDescriptorD = OCMProtocolMock(@protocol(PTNAlbumDescriptor));
      OCMStub([albumDescriptorD ptn_identifier]).andReturn(PTNCreateURL(kSchemeD, nil, nil));
    });

    it(@"should forward remove requests to underlying managers", ^{
      RACSignal *values = [multiplexerManager removeDescriptors:@[descriptorA, descriptorA]
                                                      fromAlbum:albumDescriptorA];

      expect(values).to.equal(returnSignalA);
    });

    it(@"should err when given album descriptor has an unconfigured scheme", ^{
      RACSignal *values = [multiplexerManager removeDescriptors:@[descriptorA, descriptorA]
                                                      fromAlbum:albumDescriptorD];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeUnrecognizedURLScheme &&
            [error.ptn_associatedDescriptor isEqual:albumDescriptorD];
      });
    });

    it(@"should err when given descriptors don't match album descriptor scheme", ^{
      NSArray *descriptors = @[descriptorA, descriptorB, descriptorC];
      RACSignal *values = [multiplexerManager removeDescriptors:descriptors
                                                      fromAlbum:albumDescriptorA];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetRemovalFromAlbumFailed;
      });
    });
  });
});

SpecEnd
