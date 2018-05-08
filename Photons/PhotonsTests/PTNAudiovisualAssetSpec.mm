// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNAudiovisualAsset.h"

#import <AVFoundation/AVFoundation.h>

#import "PTNTestResources.h"

SpecBegin(PTNAudiovisualAsset)

__block AVAsset *underlyingAsset;
__block PTNAudiovisualAsset *audioVisualAsset1;
__block PTNAudiovisualAsset *audioVisualAsset2;
__block PTNAudiovisualAsset *otherAudioVisualAsset;

beforeEach(^{
  otherAudioVisualAsset = OCMClassMock([AVAsset class]);
  underlyingAsset = [AVAsset assetWithURL:PTNOneSecondVideoURL()];
  audioVisualAsset1 = [[PTNAudiovisualAsset alloc] initWithAVAsset:underlyingAsset];
  audioVisualAsset2 = [[PTNAudiovisualAsset alloc] initWithAVAsset:underlyingAsset];
});

it(@"should fetch AVAsset", ^{
  expect([audioVisualAsset1 fetchAVAsset]).to.sendValues(@[underlyingAsset]);
});

context(@"equality", ^{
  it(@"should handle isEqual correctly", ^{
    expect(audioVisualAsset1).to.equal(audioVisualAsset2);
    expect(audioVisualAsset2).to.equal(audioVisualAsset1);

    expect(audioVisualAsset1).notTo.equal(otherAudioVisualAsset);
    expect(audioVisualAsset2).notTo.equal(otherAudioVisualAsset);
  });

  it(@"should create proper hash", ^{
    expect(audioVisualAsset1.hash).to.equal(audioVisualAsset2.hash);
  });
});

SpecEnd
