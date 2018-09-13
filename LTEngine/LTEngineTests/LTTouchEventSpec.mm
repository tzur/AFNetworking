// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEvent.h"

SpecBegin(LTTouchEvent)

__block NSTimeInterval timestamp;
__block CGPoint viewLocation;
__block CGPoint previousViewLocation;
__block NSNumber *previousTimestamp;
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
  timestamp = 1;
  viewLocation = CGPointMake(2, 3);
  previousViewLocation = CGPointMake(4, 5);
  previousTimestamp = @5.5;
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
});

context(@"initialization", ^{
  __block UITouch *touchMock;
  __block UITouch * strictTouchMock;
  __block id strictViewMock;

  beforeEach(^{
    touchMock = OCMClassMock([UITouch class]);
    strictTouchMock = OCMStrictClassMock([UITouch class]);
    strictViewMock = OCMStrictClassMock([UIView class]);
    OCMStub([strictTouchMock view]).andReturn(strictViewMock);
    OCMStub([strictTouchMock type]).andReturn(type);
  });

  afterEach(^{
    touchMock = nil;
    strictTouchMock = nil;
    strictViewMock = nil;
  });

  it(@"should initialize using the given sequence ID", ^{
    static const NSUInteger kSequenceID = 7;
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:kSequenceID];
    expect(touchEvent.sequenceID).to.equal(kSequenceID);
  });

  it(@"should initialize using the view of the given touch", ^{
    UIView *view = [[UIView alloc] init];
    OCMStub([touchMock view]).andReturn(view);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.view).to.beIdenticalTo(view);
  });

  it(@"should initialize using the timestamp of the given touch", ^{
    OCMExpect([touchMock timestamp]).andReturn(timestamp);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.timestamp).to.equal(timestamp);
    OCMVerifyAll((id)touchMock);
  });

  it(@"should initialize without previous timestamp", ^{
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.previousTimestamp).to.beNil();
  });

  context(@"locations in view", ^{
    it(@"should initialize using the view location of the given touch", ^{
      OCMStub([touchMock view]).andReturn(strictViewMock);
      OCMExpect([touchMock preciseLocationInView:strictViewMock]).andReturn(viewLocation);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                    sequenceID:0];
      expect(touchEvent.viewLocation).to.equal(viewLocation);
      OCMVerifyAll((id)touchMock);
    });

    it(@"should initialize using the previous view location of the given touch", ^{
      OCMStub([touchMock view]).andReturn(strictViewMock);
      OCMExpect([touchMock precisePreviousLocationInView:strictViewMock])
          .andReturn(previousViewLocation);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                    sequenceID:0];
      expect(touchEvent.previousViewLocation).to.equal(previousViewLocation);
      OCMVerifyAll((id)touchMock);
    });
  });

  it(@"should initialize using the phase of the given touch", ^{
    OCMExpect([touchMock phase]).andReturn(phase);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.phase).to.equal(phase);
    OCMVerifyAll((id)touchMock);
  });

  it(@"should initialize using the tap count of the given touch", ^{
    OCMExpect([touchMock tapCount]).andReturn(tapCount);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.tapCount).to.equal(tapCount);
    OCMVerifyAll((id)touchMock);
  });

  it(@"should initialize using the major radius of the given touch", ^{
    OCMExpect([touchMock majorRadius]).andReturn(majorRadius);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.majorRadius).to.equal(majorRadius);
    OCMVerifyAll((id)touchMock);
  });

  it(@"should initialize using the major radius tolerance of the given touch", ^{
    OCMExpect([touchMock majorRadiusTolerance]).andReturn(majorRadiusTolerance);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.majorRadiusTolerance).to.equal(majorRadiusTolerance);
    OCMVerifyAll((id)touchMock);
  });

  it(@"should initialize using the type of the given touch", ^{
    OCMExpect([touchMock type]).andReturn(type);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.type).to.equal(type);
    OCMVerifyAll((id)touchMock);
  });

  it(@"should initialize using the force of the given touch", ^{
    OCMExpect([touchMock force]).andReturn(force);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.force).to.equal(force);
    OCMVerifyAll((id)touchMock);
  });

  it(@"should initialize using the maximum possible force of the given touch", ^{
    OCMExpect([touchMock maximumPossibleForce]).andReturn(maximumPossibleForce);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.maximumPossibleForce).to.equal(maximumPossibleForce);
    OCMVerifyAll((id)touchMock);
  });

  context(@"azimuth angle", ^{
    it(@"should initialize using the azimuth angle if type is UITouchTypeStylus", ^{
      OCMStub([touchMock type]).andReturn(UITouchTypeStylus);
      OCMExpect([touchMock azimuthAngleInView:nil]).andReturn(azimuthAngle);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                    sequenceID:0];
      expect(touchEvent.azimuthAngle).to.equal(azimuthAngle);
      OCMVerifyAll((id)touchMock);
    });

    it(@"should not use the azimuth angle of the given touch if type is not UITouchTypeStylus", ^{
      OCMReject([touchMock azimuthAngleInView:nil]);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                    sequenceID:0];
      expect(touchEvent.azimuthAngle).to.beNil();
    });
  });

  context(@"azimuth unit vector", ^{
    it(@"should initialize using the azimuth unit vector if type is UITouchTypeStylus", ^{
      OCMStub([touchMock type]).andReturn(UITouchTypeStylus);
      OCMExpect([touchMock azimuthUnitVectorInView:nil])
          .andReturn(CGVectorMake(azimuthUnitVector.x, azimuthUnitVector.y));
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                    sequenceID:0];
      expect(touchEvent.azimuthUnitVector).to.equal(azimuthUnitVector);
      OCMVerifyAll((id)touchMock);
    });

    it(@"should not use the azimuth unit vector if type is not UITouchTypeStylus", ^{
      OCMReject([touchMock azimuthUnitVectorInView:nil]);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                    sequenceID:0];
      expect(touchEvent.azimuthUnitVector.isNull()).to.beTruthy();
    });
  });

  context(@"altitude angle", ^{
    it(@"should initialize using the altitude angle if type is UITouchTypeStylus", ^{
      OCMStub([touchMock type]).andReturn(UITouchTypeStylus);
      OCMExpect([touchMock altitudeAngle]).andReturn(altitudeAngle);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                    sequenceID:0];
      expect(touchEvent.altitudeAngle).to.equal(altitudeAngle);
      OCMVerifyAll((id)touchMock);
    });

    it(@"should not use the altitude angle if type is not UITouchTypeStylus", ^{
      OCMReject([touchMock altitudeAngle]);
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                    sequenceID:0];
      expect(touchEvent.altitudeAngle).to.beNil();
    });
  });

  it(@"should initialize using the estimation update index of the given touch", ^{
    OCMExpect([touchMock estimationUpdateIndex]).andReturn(estimationUpdateIndex);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.estimationUpdateIndex).to.equal(estimationUpdateIndex);
    OCMVerifyAll((id)touchMock);
  });

  it(@"should initialize using the estimated properties of the given touch", ^{
    OCMExpect([touchMock estimatedProperties]).andReturn(estimatedProperties);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.estimatedProperties).to.equal(estimatedProperties);
    OCMVerifyAll((id)touchMock);
  });

  it(@"should initialize using the estimated properties expecting updates of the given touch", ^{
    OCMExpect([touchMock estimatedPropertiesExpectingUpdates])
        .andReturn(propertiesExpectingUpdates);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                  sequenceID:0];
    expect(touchEvent.estimatedPropertiesExpectingUpdates).to.equal(propertiesExpectingUpdates);
    OCMVerifyAll((id)touchMock);
  });

  it(@"should correctly initialize with all required properties of the given touch", ^{
    // This test ensures that no additional new or existing properties of the given touch are
    // accessed without updating the tests.
    OCMExpect([strictTouchMock timestamp]).andReturn(timestamp);
    OCMExpect([strictTouchMock preciseLocationInView:strictViewMock]).andReturn(viewLocation);
    OCMExpect([strictTouchMock precisePreviousLocationInView:strictViewMock])
        .andReturn(previousViewLocation);
    OCMExpect([strictTouchMock phase]).andReturn(phase);
    OCMExpect([strictTouchMock tapCount]).andReturn(tapCount);
    OCMExpect([strictTouchMock majorRadius]).andReturn(majorRadius);
    OCMExpect([strictTouchMock majorRadiusTolerance]).andReturn(majorRadiusTolerance);
    OCMExpect([strictTouchMock force]).andReturn(force);
    OCMExpect([strictTouchMock maximumPossibleForce]).andReturn(maximumPossibleForce);
    OCMExpect([strictTouchMock azimuthAngleInView:nil]).andReturn(azimuthAngle);
    OCMExpect([strictTouchMock azimuthUnitVectorInView:nil])
        .andReturn(CGVectorMake(azimuthUnitVector.x, azimuthUnitVector.y));
    OCMExpect([strictTouchMock altitudeAngle]).andReturn(altitudeAngle);
    OCMExpect([strictTouchMock estimationUpdateIndex]).andReturn(estimationUpdateIndex);
    OCMExpect([strictTouchMock estimatedProperties]).andReturn(estimatedProperties);
    OCMExpect([strictTouchMock estimatedPropertiesExpectingUpdates])
        .andReturn(propertiesExpectingUpdates);

    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:strictTouchMock
                                                                  sequenceID:7];

    expect(touchEvent).toNot.beNil();
    expect(touchEvent.sequenceID).to.equal(7);
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

    OCMVerifyAll((id)strictTouchMock);
  });

  it(@"should initialize using timestamp of the given touch and given previous timestamp", ^{
    static const NSTimeInterval kPreviousTimestamp = 123.456789;
    OCMExpect([touchMock timestamp]).andReturn(kPreviousTimestamp + 1);

    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                           previousTimestamp:@(kPreviousTimestamp)
                                                                  sequenceID:0];

    OCMVerifyAll((id)touchMock);
    expect(touchEvent.timestamp).to.equal(kPreviousTimestamp + 1);
    expect([touchEvent.previousTimestamp doubleValue]).to.equal(kPreviousTimestamp);
  });

  it(@"should initialize using timestamp of the given touch but without previous timestamp", ^{
    OCMExpect([touchMock timestamp]).andReturn(timestamp);

    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                           previousTimestamp:nil
                                                                  sequenceID:0];
    OCMVerifyAll((id)touchMock);
    expect(touchEvent.timestamp).to.equal(timestamp);
    expect(touchEvent.previousTimestamp).to.beNil();
  });

  it(@"should initialize with a given timestamp and previous timestamp", ^{
    static const NSTimeInterval kTimestamp = 987.654321;
    static const NSTimeInterval kPreviousTimestamp = 123.456789;
    OCMReject([touchMock timestamp]);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                   timestamp:kTimestamp
                                                           previousTimestamp:@(kPreviousTimestamp)
                                                                  sequenceID:0];
    expect(touchEvent.timestamp).to.equal(kTimestamp);
    expect([touchEvent.previousTimestamp doubleValue]).to.equal(kPreviousTimestamp);
  });

  it(@"should initialize with a given timestamp but without previous timestamp", ^{
    static const NSTimeInterval kTimestamp = 987.654321;
    OCMReject([touchMock timestamp]);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                   timestamp:kTimestamp
                                                           previousTimestamp:nil sequenceID:0];

    expect(touchEvent.timestamp).to.equal(kTimestamp);
    expect(touchEvent.previousTimestamp).to.beNil();
  });
});

context(@"NSObject protocol", ^{
  __block LTTouchEvent *touchEvent;
  __block UITouch *touchMock;

  static const NSUInteger kSequenceID = 7;

  beforeEach(^{
    touchMock = OCMClassMock([UITouch class]);
    touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock sequenceID:kSequenceID];
    expect(touchEvent.sequenceID).to.equal(kSequenceID);
  });

  context(@"equality", ^{
    it(@"should return YES when comparing to itself", ^{
      expect([touchEvent isEqual:touchEvent]).to.beTruthy();
    });

    it(@"should return NO when comparing to nil", ^{
      expect([touchEvent isEqual:nil]).to.beFalsy();
    });

    it(@"should return YES when comparing to equal touch event", ^{
      OCMStub([touchMock timestamp]).andReturn(timestamp);
      OCMStub([touchMock locationInView:OCMOCK_ANY]).andReturn(viewLocation);
      OCMStub([touchMock previousLocationInView:OCMOCK_ANY]).andReturn(previousViewLocation);
      OCMStub([touchMock phase]).andReturn(phase);
      OCMStub([touchMock tapCount]).andReturn(tapCount);
      OCMStub([touchMock majorRadius]).andReturn(majorRadius);
      OCMStub([touchMock majorRadiusTolerance]).andReturn(majorRadiusTolerance);
      OCMStub([touchMock force]).andReturn(force);
      OCMStub([touchMock maximumPossibleForce]).andReturn(maximumPossibleForce);
      OCMStub([touchMock azimuthAngleInView:OCMOCK_ANY]).andReturn(azimuthAngle);
      OCMStub([touchMock azimuthUnitVectorInView:OCMOCK_ANY])
          .andReturn(CGVectorMake(azimuthUnitVector.x, azimuthUnitVector.y));
      OCMStub([touchMock altitudeAngle]).andReturn(altitudeAngle);
      OCMStub([touchMock estimationUpdateIndex]).andReturn(estimationUpdateIndex);
      OCMStub([touchMock estimatedProperties]).andReturn(estimatedProperties);
      OCMStub([touchMock estimatedPropertiesExpectingUpdates])
          .andReturn(propertiesExpectingUpdates);

      touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock sequenceID:kSequenceID];
      LTTouchEvent *anotherTouchEvent =
          [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock sequenceID:kSequenceID];
      expect([touchEvent isEqual:anotherTouchEvent]).to.beTruthy();
    });

    it(@"should return NO when comparing to an object of a different class", ^{
      expect([touchEvent isEqual:[[NSObject alloc] init]]).to.beFalsy();
    });

    it(@"should return NO when comparing to different touch event", ^{
      LTTouchEvent *anotherTouchEvent =
          [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock sequenceID:kSequenceID + 1];
      expect([touchEvent isEqual:anotherTouchEvent]).to.beFalsy();
    });
  });

  context(@"hash", ^{
    it(@"should return the same hash value for equal objects", ^{
      LTTouchEvent *anotherTouchEvent =
          [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock sequenceID:kSequenceID];
      expect(touchEvent.hash).to.equal(anotherTouchEvent.hash);
    });
  });
});

context(@"copying", ^{
  it(@"should return itself as copy, due to immutability", ^{
    LTTouchEvent *touchEvent =
        [LTTouchEvent touchEventWithPropertiesOfTouch:OCMClassMock([UITouch class]) sequenceID:0];
    expect([touchEvent copy]).to.beIdenticalTo(touchEvent);
  });
});

context(@"velocity and speed", ^{
  __block UITouch *touchMock;

  beforeEach(^{
    touchMock = OCMClassMock([UITouch class]);
    OCMExpect([touchMock preciseLocationInView:OCMOCK_ANY]).andReturn(CGPointMake(0, 7));
    OCMExpect([touchMock precisePreviousLocationInView:OCMOCK_ANY]).andReturn(CGPointZero);
    OCMStub([touchMock timestamp]).andReturn(1);
  });

  context(@"velocity", ^{
    it(@"should return the correct velocity", ^{
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                             previousTimestamp:@0
                                                                    sequenceID:0];
      expect(touchEvent.velocityInViewCoordinates).to.equal(LTVector2(0, 7));
    });

    it(@"should return LTVector2::null() as velocity if previousTimestamp is nil", ^{
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                    sequenceID:0];
      expect(touchEvent.velocityInViewCoordinates.isNull()).to.beTruthy();
    });

    it(@"should return LTVector2::null() as velocity if timestamp equals previousTimestamp", ^{
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                     timestamp:0
                                                             previousTimestamp:@0
                                                                    sequenceID:0];
      expect(touchEvent.velocityInViewCoordinates.isNull()).to.beTruthy();
    });
  });

  context(@"speed", ^{
    it(@"should return the correct speed", ^{
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                             previousTimestamp:@0
                                                                    sequenceID:0];
      expect(touchEvent.speedInViewCoordinates).to.equal(@7);
    });

    it(@"should return nil as speed if timestamp equals previousTimestamp", ^{
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                     timestamp:0
                                                             previousTimestamp:@0
                                                                    sequenceID:0];
      expect(touchEvent.speedInViewCoordinates).to.beNil();
    });

    it(@"should return nil as speed if previousTimestamp is nil", ^{
      LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touchMock
                                                                    sequenceID:0];
      expect(touchEvent.speedInViewCoordinates).to.beNil();
    });
  });
});

SpecEnd
