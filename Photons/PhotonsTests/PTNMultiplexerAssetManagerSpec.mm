// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNMultiplexerAssetManager.h"

#import "NSError+Photons.h"
#import "PTNAVAssetFetchOptions.h"
#import "PTNDescriptor.h"
#import "PTNImageFetchOptions.h"
#import "PTNMultiplexingTestUtils.h"
#import "PTNNSURLTestUtils.h"
#import "PTNResizingStrategy.h"
#import "PTNTestUtils.h"

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

  descriptorA = PTNCreateDescriptor((PTNCreateURL(kSchemeA, nil, nil)), nil, 0, nil);
  descriptorB = PTNCreateDescriptor((PTNCreateURL(kSchemeB, nil, nil)), nil, 0, nil);
  descriptorC = PTNCreateDescriptor((PTNCreateURL(kSchemeC, nil, nil)), nil, 0, nil);
  descriptorD = PTNCreateDescriptor((PTNCreateURL(kSchemeD, nil, nil)), nil, 0, nil);
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

context(@"AVAsset fetching", ^{
  __block PTNAVAssetFetchOptions *options;

  beforeEach(^{
    options = OCMClassMock([PTNAVAssetFetchOptions class]);
  });

  it(@"should correctly forward AVAsset requests", ^{
    RACSignal *signal = [multiplexerManager fetchAVAssetWithDescriptor:descriptorA options:options];
    expect(signal).to.equal(returnSignalA);
    OCMVerify([managerA fetchAVAssetWithDescriptor:descriptorA  options:options]);
  });

  it(@"should error on AVAsset requests with unconfigured scheme", ^{
    RACSignal *signal = [multiplexerManager fetchAVAssetWithDescriptor:descriptorD options:options];
    expect(signal).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeUnrecognizedURLScheme;
    });
  });
});

context(@"image data fetching", ^{
  it(@"should forward image data requests", ^{
    RACSignal *signal = [multiplexerManager fetchImageDataWithDescriptor:descriptorA];
    expect(signal).to.equal(returnSignalA);
    OCMVerify([managerA fetchImageDataWithDescriptor:descriptorA]);
  });

  it(@"should error on image data requests with unconfigured scheme", ^{
    RACSignal *signal = [multiplexerManager fetchImageDataWithDescriptor:descriptorD];
    expect(signal).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeUnrecognizedURLScheme;
    });
  });
});

context(@"AV preview fetching", ^{
  __block PTNAVAssetFetchOptions *options;

  beforeEach(^{
    options = OCMClassMock([PTNAVAssetFetchOptions class]);
  });

  it(@"should correctly forward AV preview requests", ^{
    RACSignal *signal = [multiplexerManager fetchAVPreviewWithDescriptor:descriptorA
                                                                 options:options];
    expect(signal).to.equal(returnSignalA);
    OCMVerify([managerA fetchAVPreviewWithDescriptor:descriptorA options:options]);
  });

  it(@"should error on AV perview requests with unconfigured scheme", ^{
    RACSignal *signal = [multiplexerManager fetchAVPreviewWithDescriptor:descriptorD
                                                                 options:options];
    expect(signal).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeUnrecognizedURLScheme;
    });
  });
});

context(@"av data fetching", ^{
  it(@"should forward image data requests", ^{
    RACSignal *signal = [multiplexerManager fetchAVDataWithDescriptor:descriptorA];
    expect(signal).to.equal(returnSignalA);
    OCMVerify([managerA fetchAVDataWithDescriptor:descriptorA]);
  });

  it(@"should error on image data requests with unconfigured scheme", ^{
    RACSignal *signal = [multiplexerManager fetchAVDataWithDescriptor:descriptorD];
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

    it(@"should err when relevant underlying descriptor does not respond to delete selector", ^{
      id<PTNAssetManager> nonRespondingAssetManager = OCMProtocolMock(@protocol(NSObject));
      multiplexerManager = [[PTNMultiplexerAssetManager alloc] initWithSources:@{
        kSchemeA: nonRespondingAssetManager
      }];

      RACSignal *values = [multiplexerManager deleteDescriptors:@[descriptorA]];
      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeUnsupportedOperation &&
            [error.ptn_associatedDescriptors isEqual:@[descriptorA]];
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

    it(@"should err when relevant underlying descriptor does not respond to delete selector", ^{
      id<PTNAssetManager> nonRespondingAssetManager = OCMProtocolMock(@protocol(NSObject));
      multiplexerManager = [[PTNMultiplexerAssetManager alloc] initWithSources:@{
        kSchemeA: nonRespondingAssetManager
      }];

      RACSignal *values = [multiplexerManager removeDescriptors:@[descriptorA]
                                                      fromAlbum:albumDescriptorA];
      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeUnsupportedOperation &&
            [error.ptn_associatedDescriptors isEqual:@[descriptorA]];
      });
    });
  });

  context(@"favorite", ^{
    beforeEach(^{
      descriptorA = PTNCreateAssetDescriptor(PTNCreateURL(kSchemeA, nil, nil), nil, 0, nil, nil,
                                             nil, nil, PTNAssetDescriptorCapabilityFavorite);
      descriptorB = PTNCreateAssetDescriptor(PTNCreateURL(kSchemeB, nil, nil), nil, 0, nil, nil,
                                             nil, nil, PTNAssetDescriptorCapabilityFavorite);
    });

    it(@"should forward favorite requests to underlying managers", ^{
      RACSignal *values = [multiplexerManager favoriteDescriptors:@[descriptorA, descriptorB]
                                                         favorite:YES];

      [returnSignalA sendCompleted];
      expect(values).toNot.complete();
      [returnSignalB sendCompleted];
      expect(values).will.complete();
      OCMVerify([managerA favoriteDescriptors:@[descriptorA] favorite:YES]);
      OCMVerify([managerB favoriteDescriptors:@[descriptorB] favorite:YES]);
    });

    it(@"should err when given descriptor have an unconfigured scheme", ^{
      RACSignal *values = [multiplexerManager favoriteDescriptors:@[descriptorA, descriptorD]
                                                         favorite:YES];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeUnrecognizedURLScheme &&
            [error.ptn_associatedDescriptors isEqual:@[descriptorD]];
      });
    });

    it(@"should err when any descriptors do not conform to PTNAssetDescriptor", ^{
      RACSignal *values = [multiplexerManager favoriteDescriptors:@[descriptorA, descriptorC]
                                                         favorite:YES];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidDescriptor &&
            [error.ptn_associatedDescriptors isEqual:@[descriptorC]];
      });
    });

    it(@"should err when any descriptors don't support PTNAssetDescriptorCapabilityFavorite", ^{
      id<PTNAssetDescriptor> Unfavorable =
          PTNCreateAssetDescriptor(PTNCreateURL(kSchemeA, nil, nil), nil, 0, nil, nil, nil, nil, 0);
      RACSignal *values = [multiplexerManager favoriteDescriptors:@[descriptorA, Unfavorable]
                                                         favorite:YES];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidDescriptor &&
            [error.ptn_associatedDescriptors isEqual:@[Unfavorable]];
      });
    });

    it(@"should err when relevant underlying descriptor does not respond to favorite selector", ^{
      id<PTNAssetManager> nonRespondingAssetManager = OCMProtocolMock(@protocol(NSObject));
      multiplexerManager = [[PTNMultiplexerAssetManager alloc] initWithSources:@{
        kSchemeA: nonRespondingAssetManager
      }];

      RACSignal *values = [multiplexerManager favoriteDescriptors:@[descriptorA] favorite:YES];
      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeUnsupportedOperation &&
            [error.ptn_associatedDescriptors isEqual:@[descriptorA]];
      });
    });
  });
});

SpecEnd
