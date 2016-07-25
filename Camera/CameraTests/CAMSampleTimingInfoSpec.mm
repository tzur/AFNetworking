// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CAMSampleTimingInfo.h"

SpecBegin(CAMSampleTimingInfo)

__block CMSampleTimingInfo sampleTimingInfo;
__block CMSampleTimingInfo sameSampleTimingInfo;

beforeEach(^{
  sampleTimingInfo = {CMTimeMake(1, 60), CMTimeMake(2, 60), CMTimeMake(3, 60)};
  sameSampleTimingInfo = sampleTimingInfo;
});

context(@"CAMSampleTimingInfoHash", ^{
  it(@"should return same hash value for objects with same values", ^{
    expect(CAMSampleTimingInfoHash(sampleTimingInfo))
        .to.equal(CAMSampleTimingInfoHash(sameSampleTimingInfo));
  });
});

context(@"CAMSampleTimingInfoIsEqual", ^{
  __block CMSampleTimingInfo differentSampleTimingInfo1;
  __block CMSampleTimingInfo differentSampleTimingInfo2;
  __block CMSampleTimingInfo differentSampleTimingInfo3;
  __block CMSampleTimingInfo differentSampleTimingInfo4;

  beforeEach(^{
    differentSampleTimingInfo1 = {CMTimeMake(2, 60), CMTimeMake(2, 60), CMTimeMake(3, 60)};
    differentSampleTimingInfo2 = {kCMTimeZero, CMTimeMake(2, 60), kCMTimeZero};
    differentSampleTimingInfo3 = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    differentSampleTimingInfo4 = {kCMTimeZero, kCMTimeZero, kCMTimeZero};
  });

  it(@"should return YES when given objects with same values", ^{
    expect(CAMSampleTimingInfoIsEqual(sampleTimingInfo, sameSampleTimingInfo)).to.beTruthy();
  });

  it(@"should return NO when given objects with different values", ^{
    expect(CAMSampleTimingInfoIsEqual(sampleTimingInfo, differentSampleTimingInfo1)).to.beFalsy();
    expect(CAMSampleTimingInfoIsEqual(sampleTimingInfo, differentSampleTimingInfo2)).to.beFalsy();
    expect(CAMSampleTimingInfoIsEqual(sampleTimingInfo, differentSampleTimingInfo3)).to.beFalsy();
    expect(CAMSampleTimingInfoIsEqual(sampleTimingInfo, differentSampleTimingInfo4)).to.beFalsy();
  });
});

SpecEnd
