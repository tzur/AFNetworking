// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitObserver.h"

NS_ASSUME_NONNULL_BEGIN

@class PHChange;

/// Fake PhotoKit observer for easier testing.
@interface PTNPhotoKitFakeObserver : NSObject <PTNPhotoKitObserver>

/// Send a change on the observation signal.
- (void)sendChange:(PHChange *)change;

@end

NS_ASSUME_NONNULL_END
