// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

@class CLHeading, CLLocation, CLLocationManager;

/// Object for measuring device location. After starting, the latest location data is always
/// available in \c location and \c heading.
@protocol CAMDeviceLocation <NSObject>

/// Start measuring device location.
///
/// @note calling this method for the first time on a device may prompt the user requesting for
/// permission to use location services.
///
/// @note measurement can potentially consume a lot of resources and power, so this method should be
/// called as late as possible.
- (void)startMeasuringLocation;

/// Stop measuring device location.
///
/// @note measurement can potentially consume a lot of resources and power, so this method should be
/// called as early as possible.
- (void)stopMeasuringLocation;

/// Last known location of the device. May be \c nil if no location was measured until now or if
/// the user did not grant permissions to access location services.
@property (readonly, nonatomic, nullable) CLLocation *location;

/// Last known heading of the device (the direction the device is pointing at). May be \c nil if
/// no heading was measured until now or if the user did not grant permissions to access location
/// services.
@property (readonly, nonatomic, nullable) CLHeading *heading;

@end

/// Concrete implementation of \c id<CAMDeviceLocation> which uses \c CLLocationManager for
/// location data retrieval.
@interface CAMDeviceLocation : NSObject <CAMDeviceLocation>

/// Convenience initilazer.
- (instancetype)init;

/// Initializes with the given \c deviceLocation.
- (instancetype)initWithLocationManager:(CLLocationManager *)deviceLocation;

@end

NS_ASSUME_NONNULL_END
