// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import <CoreMedia/CMSampleBuffer.h>

NS_ASSUME_NONNULL_BEGIN

/// Returns a hash value for the given \c sampleTimingInfo.
NSUInteger CAMSampleTimingInfoHash(CMSampleTimingInfo sampleTimingInfo);

/// Returns \c YES if \c left is equal to \c right.
BOOL CAMSampleTimingInfoIsEqual(CMSampleTimingInfo left, CMSampleTimingInfo right);

NS_ASSUME_NONNULL_END
