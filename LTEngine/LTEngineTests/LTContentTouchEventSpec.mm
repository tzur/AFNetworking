// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentTouchEvent.h"

SpecBegin(LTContentTouchEvent)

static const NSTimeInterval kTimestamp = 1;
static const CGPoint kViewLocation = CGPointMake(2, 3);
static const CGPoint kPreviousViewLocation = CGPointMake(4, 5);
static const NSNumber *kPreviousTimestamp = @0.5;
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

static const CGFloat kScaleFactor = 2;
static const CGPoint kTranslation = CGPointMake(1, 2);
static const CGAffineTransform kTranslationTransform =
    CGAffineTransformMakeTranslation(kTranslation.x, kTranslation.y);
static const CGAffineTransform kTransform = CGAffineTransformScale(kTranslationTransform,
                                                                   kScaleFactor, kScaleFactor);
static const CGPoint kContentLocation = (kScaleFactor * kViewLocation) + kTranslation;
static const CGPoint kPreviousContentLocation =
    (kScaleFactor * kPreviousViewLocation) + kTranslation;
static const CGFloat kContentZoomScale = 5;
static const CGSize kContentSize = CGSizeMake(1, 2);
static const CGFloat kMajorContentRadius = kScaleFactor * kMajorRadius;
static const CGFloat kMajorContentRadiusTolerance = kScaleFactor * kMajorRadiusTolerance;

static const LTVector2 kVelocityInViewCoordinates =
    LTVector2(kViewLocation - kPreviousViewLocation) /
    (kTimestamp - [kPreviousTimestamp doubleValue]);

static const NSNumber *kSpeedInViewCoordinates = @(kVelocityInViewCoordinates.length());

static const LTVector2 kVelocityInContentCoordinates =
    LTVector2(kContentLocation - kPreviousContentLocation) /
    (kTimestamp - [kPreviousTimestamp doubleValue]);

static const NSNumber *kSpeedInContentCoordinates = @(kVelocityInContentCoordinates.length());

__block id<LTTouchEvent> initialTouchEventMock;
__block id<LTTouchEvent> touchEventMock;

beforeEach(^{
  initialTouchEventMock = OCMProtocolMock(@protocol(LTTouchEvent));
  touchEventMock = OCMProtocolMock(@protocol(LTTouchEvent));
  OCMStub([initialTouchEventMock copyWithZone:nil]).andReturn(touchEventMock);
  OCMStub([touchEventMock timestamp]).andReturn(kTimestamp);
  OCMStub([touchEventMock viewLocation]).andReturn(kViewLocation);
  OCMStub([touchEventMock previousViewLocation]).andReturn(kPreviousViewLocation);
  OCMStub([touchEventMock previousTimestamp]).andReturn(kPreviousTimestamp);
  OCMStub([touchEventMock velocityInViewCoordinates]).andReturn(kVelocityInViewCoordinates);
  OCMStub([touchEventMock speedInViewCoordinates]).andReturn(kSpeedInViewCoordinates);
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

  OCMStub([initialTouchEventMock viewLocation]).andReturn(kViewLocation);
  OCMStub([initialTouchEventMock previousViewLocation]).andReturn(kPreviousViewLocation);
  OCMStub([initialTouchEventMock majorRadius]).andReturn(kMajorRadius);
  OCMStub([initialTouchEventMock majorRadiusTolerance]).andReturn(kMajorRadiusTolerance);
});

afterEach(^{
  touchEventMock = nil;
  initialTouchEventMock = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    LTContentTouchEvent *contentTouchEvent =
        [[LTContentTouchEvent alloc] initWithTouchEvent:initialTouchEventMock
                                            contentSize:kContentSize
                                       contentZoomScale:kContentZoomScale
                                              transform:kTransform];

    // LTTouchEvent protocol
    expect(contentTouchEvent.timestamp).to.equal(kTimestamp);
    expect(contentTouchEvent.viewLocation).to.equal(kViewLocation);
    expect(contentTouchEvent.previousViewLocation).to.equal(kPreviousViewLocation);
    expect(contentTouchEvent.previousTimestamp).to.equal(kPreviousTimestamp);
    expect(contentTouchEvent.velocityInViewCoordinates).to.equal(kVelocityInViewCoordinates);
    expect(contentTouchEvent.speedInViewCoordinates).to.equal(kSpeedInViewCoordinates);
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
    expect(contentTouchEvent.contentSize).to.equal(kContentSize);
    expect(contentTouchEvent.contentZoomScale).to.equal(kContentZoomScale);
    expect(contentTouchEvent.majorContentRadius).to.equal(kMajorContentRadius);
    expect(contentTouchEvent.majorContentRadiusTolerance).to.equal(kMajorContentRadiusTolerance);
  });
});

context(@"NSObject protocol", ^{
  __block LTContentTouchEvent *contentTouchEvent;
  __block LTContentTouchEvent *equalContentTouchEvent;

  beforeEach(^{
    contentTouchEvent = [[LTContentTouchEvent alloc] initWithTouchEvent:initialTouchEventMock
                                                            contentSize:kContentSize
                                                       contentZoomScale:kContentZoomScale
                                                              transform:kTransform];
    equalContentTouchEvent = [[LTContentTouchEvent alloc] initWithTouchEvent:initialTouchEventMock
                                                                 contentSize:kContentSize
                                                            contentZoomScale:kContentZoomScale
                                                                   transform:kTransform];
  });

  context(@"equality", ^{
    it(@"should return YES when comparing to itself", ^{
      expect([contentTouchEvent isEqual:contentTouchEvent]).to.beTruthy();
    });

    it(@"should return NO when comparing to nil", ^{
      expect([contentTouchEvent isEqual:nil]).to.beFalsy();
    });

    it(@"should return YES when comparing to equal content touch event", ^{
      expect([contentTouchEvent isEqual:equalContentTouchEvent]).to.beTruthy();
    });

    it(@"should return NO when comparing to an object of a different class", ^{
      expect([contentTouchEvent isEqual:[[NSObject alloc] init]]).to.beFalsy();
    });

    it(@"should return NO when comparing to different content touch event", ^{
      LTContentTouchEvent *anotherContentTouchEvent =
          [[LTContentTouchEvent alloc] initWithTouchEvent:initialTouchEventMock
                                              contentSize:kContentSize
                                         contentZoomScale:kContentZoomScale * 2
                                                transform:kTransform];
      expect([contentTouchEvent isEqual:anotherContentTouchEvent]).to.beFalsy();
    });
  });

  context(@"hash", ^{
    it(@"should return the same hash value for equal objects", ^{
      expect(contentTouchEvent.hash).to.equal(equalContentTouchEvent.hash);
    });
  });
});

context(@"copying", ^{
  it(@"should return itself as copy, due to immutability", ^{
    LTContentTouchEvent *contentTouchEvent =
        [[LTContentTouchEvent alloc] initWithTouchEvent:initialTouchEventMock
                                            contentSize:kContentSize
                                       contentZoomScale:kContentZoomScale transform:kTransform];
    expect([contentTouchEvent copy]).to.beIdenticalTo(contentTouchEvent);
  });
});

context(@"velocity and speed in content coordinates", ^{
  context(@"velocity", ^{
    it(@"should return the correct velocity", ^{
      LTContentTouchEvent *contentTouchEvent =
          [[LTContentTouchEvent alloc] initWithTouchEvent:initialTouchEventMock
                                              contentSize:kContentSize
                                         contentZoomScale:kContentZoomScale transform:kTransform];
      expect(contentTouchEvent.velocityInContentCoordinates)
          .to.equal(kVelocityInContentCoordinates);
    });

    it(@"should return LTVector2::null() as velocity if previousTimestamp is nil", ^{
      initialTouchEventMock = OCMProtocolMock(@protocol(LTTouchEvent));
      touchEventMock = OCMProtocolMock(@protocol(LTTouchEvent));
      OCMStub([initialTouchEventMock copyWithZone:nil]).andReturn(touchEventMock);
      OCMStub([touchEventMock previousTimestamp]);

      LTContentTouchEvent *contentTouchEvent =
          [[LTContentTouchEvent alloc] initWithTouchEvent:initialTouchEventMock
                                              contentSize:kContentSize
                                         contentZoomScale:kContentZoomScale transform:kTransform];
      expect(contentTouchEvent.velocityInContentCoordinates.isNull()).to.beTruthy();
    });
  });

  context(@"speed", ^{
    it(@"should return the correct speed", ^{
      LTContentTouchEvent *contentTouchEvent =
          [[LTContentTouchEvent alloc] initWithTouchEvent:initialTouchEventMock
                                              contentSize:kContentSize
                                         contentZoomScale:kContentZoomScale transform:kTransform];
      expect(contentTouchEvent.speedInContentCoordinates).to.equal(kSpeedInContentCoordinates);
    });

    it(@"should return nil as speed if previousTimestamp is nil", ^{
      initialTouchEventMock = OCMProtocolMock(@protocol(LTTouchEvent));
      touchEventMock = OCMProtocolMock(@protocol(LTTouchEvent));
      OCMStub([initialTouchEventMock copyWithZone:nil]).andReturn(touchEventMock);
      OCMStub([touchEventMock previousTimestamp]);

      LTContentTouchEvent *contentTouchEvent =
          [[LTContentTouchEvent alloc] initWithTouchEvent:initialTouchEventMock
                                              contentSize:kContentSize
                                         contentZoomScale:kContentZoomScale transform:kTransform];
      expect(contentTouchEvent.speedInContentCoordinates).to.beNil();
    });
  });
});

SpecEnd
