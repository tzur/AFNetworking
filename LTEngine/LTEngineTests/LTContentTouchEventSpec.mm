// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentTouchEvent.h"

SpecBegin(LTContentTouchEvent)

static const NSTimeInterval kTimestamp = 1;
static const CGPoint kViewLocation = CGPointMake(2, 3);
static const CGPoint kPreviousViewLocation = CGPointMake(4, 5);
static const UITouchPhase kPhase = UITouchPhaseMoved;
static const NSUInteger kTapCount = 6;
static const CGFloat kMajorRadius = 7;
static const CGFloat kMajorRadiusTolerance = 8;
static const UITouchType kType = UITouchTypeStylus;
static const NSNumber *kForce = @9;
static const NSNumber *kMaximumPossibleForce = @10;
static const NSNumber *kAzimuthAngle = @11;
static const LTVector2 kAzimuthUnitVector = LTVector2(12, 13);
static const NSNumber *kAltitudeAngle = @14;
static const NSNumber *kEstimationUpdateIndex = @15;
static const UITouchProperties kEstimatedProperties =
    UITouchPropertyForce | UITouchPropertyLocation;
static const UITouchProperties kPropertiesExpectingUpdates = UITouchPropertyAzimuth;

static const CGPoint kContentLocation = CGPointMake(1, 2);
static const CGPoint kPreviousContentLocation = CGPointMake(3, 4);
static const CGFloat kContentZoomScale = 5;

__block id<LTTouchEvent> initialTouchEventMock;
__block id<LTTouchEvent> touchEventMock;

beforeEach(^{
  initialTouchEventMock = OCMProtocolMock(@protocol(LTTouchEvent));
  touchEventMock = OCMProtocolMock(@protocol(LTTouchEvent));
  OCMStub([initialTouchEventMock copyWithZone:nil]).andReturn(touchEventMock);
  OCMStub([touchEventMock timestamp]).andReturn(kTimestamp);
  OCMStub([touchEventMock viewLocation]).andReturn(kViewLocation);
  OCMStub([touchEventMock previousViewLocation]).andReturn(kPreviousViewLocation);
  OCMStub([touchEventMock phase]).andReturn(kPhase);
  OCMStub([touchEventMock tapCount]).andReturn(kTapCount);
  OCMStub([touchEventMock majorRadius]).andReturn(kMajorRadius);
  OCMStub([touchEventMock majorRadiusTolerance]).andReturn(kMajorRadiusTolerance);
  OCMStub([touchEventMock type]).andReturn(kType);
  OCMStub([touchEventMock force]).andReturn(kForce);
  OCMStub([touchEventMock maximumPossibleForce])
      .andReturn(kMaximumPossibleForce);
  OCMStub([touchEventMock azimuthAngle]).andReturn(kAzimuthAngle);
  OCMStub([touchEventMock azimuthUnitVector]).andReturn(kAzimuthUnitVector);
  OCMStub([touchEventMock altitudeAngle]).andReturn(kAltitudeAngle);
  OCMStub([touchEventMock estimationUpdateIndex]).andReturn(kEstimationUpdateIndex);
  OCMStub([touchEventMock estimatedProperties]).andReturn(kEstimatedProperties);
  OCMStub([touchEventMock estimatedPropertiesExpectingUpdates])
      .andReturn(kPropertiesExpectingUpdates);
});

afterEach(^{
  touchEventMock = nil;
  initialTouchEventMock = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    LTContentTouchEvent *contentTouchEvent =
        [[LTContentTouchEvent alloc] initWithTouchEvent:initialTouchEventMock
                                        contentLocation:kContentLocation
                                previousContentLocation:kPreviousContentLocation
                                       contentZoomScale:kContentZoomScale];

    // LTTouchEvent protocol
    expect(contentTouchEvent.timestamp).to.equal(kTimestamp);
    expect(contentTouchEvent.viewLocation).to.equal(kViewLocation);
    expect(contentTouchEvent.previousViewLocation).to.equal(kPreviousViewLocation);
    expect(contentTouchEvent.phase).to.equal(kPhase);
    expect(contentTouchEvent.tapCount).to.equal(kTapCount);
    expect(contentTouchEvent.majorRadius).to.equal(kMajorRadius);
    expect(contentTouchEvent.majorRadiusTolerance).to.equal(kMajorRadiusTolerance);
    expect(contentTouchEvent.force).to.equal(kForce);
    expect(contentTouchEvent.maximumPossibleForce).to.equal(kMaximumPossibleForce);
    expect(contentTouchEvent.azimuthAngle).to.equal(kAzimuthAngle);
    expect(contentTouchEvent.azimuthUnitVector).to.equal(kAzimuthUnitVector);
    expect(contentTouchEvent.altitudeAngle).to.equal(kAltitudeAngle);
    expect(contentTouchEvent.estimationUpdateIndex).to.equal(kEstimationUpdateIndex);
    expect(contentTouchEvent.estimatedProperties).to.equal(kEstimatedProperties);
    expect(contentTouchEvent.estimatedPropertiesExpectingUpdates)
        .to.equal(kPropertiesExpectingUpdates);

    // LTContentTouchEvent protocol
    expect(contentTouchEvent.contentLocation).to.equal(kContentLocation);
    expect(contentTouchEvent.previousContentLocation).to.equal(kPreviousContentLocation);
    expect(contentTouchEvent.contentZoomScale).to.equal(kContentZoomScale);
  });
});

context(@"copying", ^{
  it(@"should return itself as copy, due to immutability", ^{
    LTContentTouchEvent *contentTouchEvent =
        [[LTContentTouchEvent alloc] initWithTouchEvent:touchEventMock
                                        contentLocation:kContentLocation
                                previousContentLocation:kPreviousContentLocation
                                       contentZoomScale:kContentZoomScale];
    expect([contentTouchEvent copy]).to.beIdenticalTo(contentTouchEvent);
  });
});

SpecEnd
