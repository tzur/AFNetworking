// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CAMDeviceLocation.h"

#import <CoreLocation/CoreLocation.h>

@interface CAMDeviceLocation () <CLLocationManagerDelegate>
@end

SpecBegin(CAMDeviceLocation)

it(@"should start location updates", ^{
  id manager = OCMClassMock([CLLocationManager class]);
  CAMDeviceLocation *deviceLocation = [[CAMDeviceLocation alloc] initWithLocationManager:manager];
  OCMStub([manager authorizationStatus]).andReturn(kCLAuthorizationStatusAuthorizedWhenInUse);

  [deviceLocation startMeasuringLocation];
  OCMVerify([manager startUpdatingLocation]);
  OCMVerify([manager startUpdatingHeading]);

  [manager stopMocking];
});

it(@"should stop location updates", ^{
  id manager = OCMClassMock([CLLocationManager class]);
  CAMDeviceLocation *deviceLocation = [[CAMDeviceLocation alloc] initWithLocationManager:manager];
  OCMStub([manager authorizationStatus]).andReturn(kCLAuthorizationStatusAuthorizedWhenInUse);

  [deviceLocation startMeasuringLocation];
  [deviceLocation stopMeasuringLocation];
  OCMVerify([manager stopUpdatingLocation]);
  OCMVerify([manager stopUpdatingHeading]);

  [manager stopMocking];
});

context(@"authorization", ^{
  it(@"should check permissions", ^{
    id manager = OCMClassMock([CLLocationManager class]);
    CAMDeviceLocation *deviceLocation = [[CAMDeviceLocation alloc] initWithLocationManager:manager];

    OCMExpect([manager authorizationStatus]);
    [deviceLocation startMeasuringLocation];
    OCMVerifyAll(manager);
  });

  it(@"should not start if restricted", ^{
    id manager = OCMClassMock([CLLocationManager class]);
    CAMDeviceLocation *deviceLocation = [[CAMDeviceLocation alloc] initWithLocationManager:manager];
    OCMStub([manager authorizationStatus]).andReturn(kCLAuthorizationStatusRestricted);

    OCMReject([manager startUpdatingLocation]);
    OCMReject([manager startUpdatingHeading]);
    [deviceLocation startMeasuringLocation];
    OCMVerifyAll(manager);

    [manager stopMocking];
  });

  it(@"should not start if denied", ^{
    id manager = OCMClassMock([CLLocationManager class]);
    CAMDeviceLocation *deviceLocation = [[CAMDeviceLocation alloc] initWithLocationManager:manager];
    OCMStub([manager authorizationStatus]).andReturn(kCLAuthorizationStatusDenied);

    OCMReject([manager startUpdatingLocation]);
    OCMReject([manager startUpdatingHeading]);
    [deviceLocation startMeasuringLocation];
    OCMVerifyAll(manager);

    [manager stopMocking];
  });

  it(@"should explicitely request permissions if undetermined", ^{
    id manager = OCMClassMock([CLLocationManager class]);
    CAMDeviceLocation *deviceLocation = [[CAMDeviceLocation alloc] initWithLocationManager:manager];
    OCMStub([manager authorizationStatus]).andReturn(kCLAuthorizationStatusNotDetermined);

    [deviceLocation startMeasuringLocation];
    OCMVerify([manager requestWhenInUseAuthorization]);

    [manager stopMocking];
  });
});

context(@"CLLocationManagerDelegate", ^{
  __block id locationManager;
  __block CAMDeviceLocation *deviceLocation;

  beforeEach(^{
    locationManager = OCMClassMock([CLLocationManager class]);
    deviceLocation = [[CAMDeviceLocation alloc] initWithLocationManager:locationManager];
  });

  it(@"should update location", ^{
    CLLocation *location = [[CLLocation alloc] init];
    [deviceLocation locationManager:locationManager didUpdateLocations:@[location]];
    expect(deviceLocation.location).to.beIdenticalTo(location);
  });

  it(@"should use latest location", ^{
    CLLocation *locationOld = [[CLLocation alloc] init];
    CLLocation *locationNew = [[CLLocation alloc] init];
    [deviceLocation locationManager:locationManager didUpdateLocations:@[locationOld, locationNew]];
    expect(deviceLocation.location).to.beIdenticalTo(locationNew);
  });

  it(@"should update heading", ^{
    CLHeading *heading = [[CLHeading alloc] init];
    [deviceLocation locationManager:locationManager didUpdateHeading:heading];
    expect(deviceLocation.heading).to.beIdenticalTo(heading);
  });
});

SpecEnd
