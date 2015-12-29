// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEvent.h"

SpecBegin(LTTouchEvent)

context(@"initialization", ^{
  __block id touchMock;
  __block id strictTouchMock;
  __block id strictViewMock;
  __block NSTimeInterval timestamp;
  __block CGPoint viewLocation;
  __block CGPoint previousViewLocation;
  __block CGFloat majorRadius;
  __block CGFloat majorRadiusTolerance;
  __block NSUInteger tapCount;
  __block UITouchPhase phase;
  __block UITouchType type;
  __block CGFloat force;
  __block CGFloat maximumPossibleForce;
  __block CGFloat azimuthAngle;
  __block LTVector2 azimuthUnitVector;
  __block CGFloat altitudeAngle;
  __block NSNumber *estimationUpdateIndex;
  __block UITouchProperties estimatedProperties;
  __block UITouchProperties propertiesExpectingUpdates;

  beforeEach(^{
    touchMock = OCMClassMock([UITouch class]);
    strictTouchMock = OCMStrictClassMock([UITouch class]);
    strictViewMock = OCMStrictClassMock([UIView class]);

    timestamp = 1;
    viewLocation = CGPointMake(2, 3);
    previousViewLocation = CGPointMake(4, 5);
    phase = UITouchPhaseMoved;
    tapCount = 6;
    majorRadius = 7;
    majorRadiusTolerance = 8;
    type = UITouchTypeStylus;
    force = 9;
    maximumPossibleForce = 10;
    azimuthAngle = 11;
    azimuthUnitVector = LTVector2(12, 13);
    altitudeAngle = 14;
    estimationUpdateIndex = @15;
    estimatedProperties = UITouchPropertyForce | UITouchPropertyLocation;
    propertiesExpectingUpdates = UITouchPropertyAzimuth;

    OCMStub([strictTouchMock view]).andReturn(strictViewMock);
    OCMStub([(UITouch *)strictTouchMock type]).andReturn(type);
  });

  afterEach(^{
    touchMock = nil;
    strictTouchMock = nil;
    strictViewMock = nil;
  });

  it(@"should initialize using the address of the given touch as sequence ID", ^{
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.sequenceID).to.equal((NSUInteger)touchMock);
  });

  it(@"should initialize using the view of the given touch", ^{
    UIView *view = [[UIView alloc] init];
    OCMExpect([touchMock view]).andReturn(view);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.view).to.beIdenticalTo(view);
    OCMVerifyAll(touchMock);
  });

  it(@"should initialize using the time stamp of the given touch", ^{
    OCMExpect([touchMock timestamp]).andReturn(timestamp);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.timestamp).to.equal(timestamp);
    OCMVerifyAll(touchMock);
  });

  context(@"locations in view", ^{
    it(@"should initialize using the view location of the given touch", ^{
      OCMStub([touchMock view]).andReturn(strictViewMock);
      OCMExpect([touchMock locationInView:strictViewMock]).andReturn(viewLocation);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
      expect(touchEvent.viewLocation).to.equal(viewLocation);
      OCMVerifyAll(touchMock);
    });

    it(@"should initialize using the previous view location of the given touch", ^{
      OCMStub([touchMock view]).andReturn(strictViewMock);
      OCMExpect([touchMock previousLocationInView:strictViewMock]).andReturn(previousViewLocation);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
      expect(touchEvent.previousViewLocation).to.equal(previousViewLocation);
      OCMVerifyAll(touchMock);
    });
  });

  it(@"should initialize using the phase of the given touch", ^{
    OCMExpect([touchMock phase]).andReturn(phase);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.phase).to.equal(phase);
    OCMVerifyAll(touchMock);
  });

  it(@"should initialize using the tap count of the given touch", ^{
    OCMExpect([(UITouch *)touchMock tapCount]).andReturn(tapCount);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.tapCount).to.equal(tapCount);
    OCMVerifyAll(touchMock);
  });

  it(@"should initialize using the major radius of the given touch", ^{
    OCMExpect([touchMock majorRadius]).andReturn(majorRadius);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.majorRadius).to.equal(majorRadius);
    OCMVerifyAll(touchMock);
  });

  it(@"should initialize using the major radius tolerance of the given touch", ^{
    OCMExpect([touchMock majorRadiusTolerance]).andReturn(majorRadiusTolerance);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.majorRadiusTolerance).to.equal(majorRadiusTolerance);
    OCMVerifyAll(touchMock);
  });

  it(@"should initialize using the type of the given touch", ^{
    OCMExpect([(UITouch *)touchMock type]).andReturn(type);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.type).to.equal(type);
    OCMVerifyAll(touchMock);
  });

  it(@"should initialize using the force of the given touch", ^{
    OCMExpect([(UITouch *)touchMock force]).andReturn(force);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.force).to.equal(force);
    OCMVerifyAll(touchMock);
  });

  it(@"should initialize using the maximum possible force of the given touch", ^{
    OCMExpect([(UITouch *)touchMock maximumPossibleForce]).andReturn(maximumPossibleForce);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.maximumPossibleForce).to.equal(maximumPossibleForce);
    OCMVerifyAll(touchMock);
  });

  context(@"azimuth angle", ^{
    it(@"should initialize using the azimuth angle if type is UITouchTypeStylus", ^{
      OCMStub([(UITouch *)touchMock type]).andReturn(UITouchTypeStylus);
      OCMExpect([touchMock azimuthAngleInView:nil]).andReturn(azimuthAngle);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
      expect(touchEvent.azimuthAngle).to.equal(azimuthAngle);
      OCMVerifyAll(touchMock);
    });

    it(@"should not use the azimuth angle of the given touch if type is not UITouchTypeStylus", ^{
      OCMExpect([[touchMock reject] azimuthAngleInView:nil]);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
      expect(touchEvent.azimuthAngle).to.beNil();
      OCMVerifyAll(touchMock);
    });
  });

  context(@"azimuth unit vector", ^{
    it(@"should initialize using the azimuth unit vector if type is UITouchTypeStylus", ^{
      OCMStub([(UITouch *)touchMock type]).andReturn(UITouchTypeStylus);
      OCMExpect([touchMock azimuthUnitVectorInView:nil])
          .andReturn(CGVectorMake(azimuthUnitVector.x, azimuthUnitVector.y));
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
      expect(touchEvent.azimuthUnitVector).to.equal(azimuthUnitVector);
      OCMVerifyAll(touchMock);
    });

    it(@"should not use the azimuth unit vector if type is not UITouchTypeStylus", ^{
      OCMExpect([[touchMock reject] azimuthUnitVectorInView:nil]);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
      expect(touchEvent.azimuthUnitVector.isNull()).to.beTruthy();
      OCMVerifyAll(touchMock);
    });
  });

  context(@"altitude angle", ^{
    it(@"should initialize using the altitude angle if type is UITouchTypeStylus", ^{
      OCMStub([(UITouch *)touchMock type]).andReturn(UITouchTypeStylus);
      OCMExpect([(UITouch *)touchMock altitudeAngle]).andReturn(altitudeAngle);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
      expect(touchEvent.altitudeAngle).to.equal(altitudeAngle);
      OCMVerifyAll(touchMock);
    });

    it(@"should not use the altitude angle if type is not UITouchTypeStylus", ^{
      OCMExpect([(UITouch *)[touchMock reject] altitudeAngle]);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
      expect(touchEvent.altitudeAngle).to.beNil();
      OCMVerifyAll(touchMock);
    });
  });

  it(@"should initialize using the estimation update index of the given touch", ^{
    OCMExpect([touchMock estimationUpdateIndex]).andReturn(estimationUpdateIndex);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.estimationUpdateIndex).to.equal(estimationUpdateIndex);
    OCMVerifyAll(touchMock);
  });

  it(@"should initialize using the estimated properties of the given touch", ^{
    OCMExpect([(UITouch *)touchMock estimatedProperties]).andReturn(estimatedProperties);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.estimatedProperties).to.equal(estimatedProperties);
    OCMVerifyAll(touchMock);
  });

  it(@"should initialize using the estimated properties expecting updates of the given touch", ^{
    OCMExpect([(UITouch *)touchMock estimatedPropertiesExpectingUpdates])
        .andReturn(propertiesExpectingUpdates);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock];
    expect(touchEvent.estimatedPropertiesExpectingUpdates).to.equal(propertiesExpectingUpdates);
    OCMVerifyAll(touchMock);
  });

  it(@"should correctly initialize with all required properties of the given touch", ^{
    // This test ensures that no additional new or existing properties of the given touch are
    // accessed without updating the tests.
    OCMExpect([strictTouchMock timestamp]).andReturn(timestamp);
    OCMExpect([strictTouchMock locationInView:strictViewMock]).andReturn(viewLocation);
    OCMExpect([strictTouchMock previousLocationInView:strictViewMock])
        .andReturn(previousViewLocation);
    OCMExpect([strictTouchMock phase]).andReturn(phase);
    OCMExpect([(UITouch *)strictTouchMock tapCount]).andReturn(tapCount);
    OCMExpect([strictTouchMock majorRadius]).andReturn(majorRadius);
    OCMExpect([strictTouchMock majorRadiusTolerance]).andReturn(majorRadiusTolerance);
    OCMExpect([(UITouch *)strictTouchMock force]).andReturn(force);
    OCMExpect([(UITouch *)strictTouchMock maximumPossibleForce]).andReturn(maximumPossibleForce);
    OCMExpect([(UITouch *)strictTouchMock azimuthAngleInView:nil]).andReturn(azimuthAngle);
    OCMExpect([(UITouch *)strictTouchMock azimuthUnitVectorInView:nil])
        .andReturn(CGVectorMake(azimuthUnitVector.x, azimuthUnitVector.y));
    OCMExpect([(UITouch *)strictTouchMock altitudeAngle]).andReturn(altitudeAngle);
    OCMExpect([strictTouchMock estimationUpdateIndex]).andReturn(estimationUpdateIndex);
    OCMExpect([(UITouch *)strictTouchMock estimatedProperties]).andReturn(estimatedProperties);
    OCMExpect([(UITouch *)strictTouchMock estimatedPropertiesExpectingUpdates])
        .andReturn(propertiesExpectingUpdates);

    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:strictTouchMock];

    expect(touchEvent).toNot.beNil();
    expect(touchEvent.sequenceID).to.equal((NSUInteger)strictTouchMock);
    expect(touchEvent.timestamp).to.equal(timestamp);
    expect(touchEvent.view).to.beIdenticalTo(strictViewMock);
    expect(touchEvent.viewLocation).to.equal(viewLocation);
    expect(touchEvent.previousViewLocation).to.equal(previousViewLocation);
    expect(touchEvent.phase).to.equal(phase);
    expect(touchEvent.tapCount).to.equal(tapCount);
    expect(touchEvent.majorRadius).to.equal(majorRadius);
    expect(touchEvent.majorRadiusTolerance).to.equal(majorRadiusTolerance);
    expect(touchEvent.type).to.equal(type);
    expect(touchEvent.force).to.equal(force);
    expect(touchEvent.maximumPossibleForce).to.equal(maximumPossibleForce);
    expect(touchEvent.azimuthAngle).to.equal(azimuthAngle);
    expect(touchEvent.azimuthUnitVector).to.equal(azimuthUnitVector);
    expect(touchEvent.altitudeAngle).to.equal(altitudeAngle);
    expect(touchEvent.estimationUpdateIndex).to.equal(estimationUpdateIndex);
    expect(touchEvent.estimatedProperties).to.equal(estimatedProperties);
    expect(touchEvent.estimatedPropertiesExpectingUpdates).to.equal(propertiesExpectingUpdates);

    OCMVerifyAll(strictTouchMock);
  });
});

context(@"copying", ^{
  it(@"should return itself as copy, due to immutability", ^{
    LTTouchEvent *touchEvent =
        [LTTouchEvent touchEventWithPropertiesOfTouch:OCMClassMock([UITouch class])];
    expect([touchEvent copy]).to.beIdenticalTo(touchEvent);
  });
});

SpecEnd
