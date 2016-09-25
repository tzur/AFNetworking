// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

@class CMMotionManager;

/// Protocol for object that tracks the device orientation, regardless of whether the device
/// orientation lock is active.
@protocol CAMDeviceOrientation <NSObject>

/// Returns a \c RACSignal that samples the device's current physical orientation in fixed
/// interavals, and sends distinct \c UIInterfaceOrientation values. If the the device's orientation
/// can't be determined (e.g. device is lying flat), the signal doesn't send any value.
///
/// The signal sends on an arbitrary thread, errs if it can't track the device orientation, and
/// completes when this object is deallocated.
///
/// @param refreshInterval refresh interval of the device's orintation.
- (RACSignal *)deviceOrientationWithRefreshInterval:(NSTimeInterval)refreshInterval;

@end

/// Object that conforms to \c CAMDeviceOrientation protocol, using the device's motion sensors.
@interface CAMDeviceOrientation : NSObject <CAMDeviceOrientation>

/// Initializes with default \c CMMotionManager.
- (instancetype)init;

/// Initializes with the given \c motionManager.
- (instancetype)initWithMotionManager:(CMMotionManager *)motionManager NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
