// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CAMDeviceLocation.h"

#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CAMDeviceLocation () <CLLocationManagerDelegate>

/// \c CoreLocation manager to read data from.
@property (readonly, nonatomic) CLLocationManager *manager;

/// Last known location of the device. May be \c nil if no location was measured until now or if
/// the user did not grant permissions to access location services.
@property (readwrite, nonatomic, nullable) CLLocation *location;

/// Last known heading of the device (the direction the device is pointing at). May be \c nil if
/// no heading was measured until now or if the user did not grant permissions to access location
/// services.
@property (readwrite, nonatomic, nullable) CLHeading *heading;

@end

@implementation CAMDeviceLocation

- (instancetype)init {
  return [self initWithLocationManager:[[CLLocationManager alloc] init]];
}

- (instancetype)initWithLocationManager:(CLLocationManager *)locationManager {
  if (self = [super init]) {
    _manager = locationManager;
  }
  return self;
}

- (void)startMeasuringLocation {
  CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
  if (authorizationStatus == kCLAuthorizationStatusRestricted ||
      authorizationStatus == kCLAuthorizationStatusDenied) {
    return;
  }

  self.manager.delegate = self;
  [self.manager requestWhenInUseAuthorization];

  self.manager.desiredAccuracy = kCLLocationAccuracyBest;
  self.manager.distanceFilter = kCLDistanceFilterNone;
  self.manager.headingFilter = kCLHeadingFilterNone;
  [self.manager startUpdatingLocation];
  [self.manager startUpdatingHeading];
}

- (void)stopMeasuringLocation {
  [self.manager stopUpdatingHeading];
  [self.manager stopUpdatingLocation];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate
#pragma mark -

- (void)locationManager:(CLLocationManager __unused *)manager
     didUpdateLocations:(NSArray *)locations {
  self.location = [locations lastObject];
}

- (void)locationManager:(CLLocationManager __unused *)manager
       didUpdateHeading:(CLHeading *)newHeading {
  self.heading = newHeading;
}

@end

NS_ASSUME_NONNULL_END
