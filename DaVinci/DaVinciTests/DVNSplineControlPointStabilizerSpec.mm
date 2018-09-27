// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSplineControlPointStabilizer.h"

#import <LTEngine/LTSplineControlPoint+AttributeKeys.h>

SpecBegin(DVNSplineControlPointStabilizer)

/// Maximum tolerated deviation between the actual location and the expected location of stabilized
/// control points.
static const CGFloat kEpsilon = 1e-4;

static NSString * const kKey = @"foo";
static NSString * const kSpeedKey = [LTSplineControlPoint keyForSpeedInScreenCoordinates];

__block DVNSplineControlPointStabilizer *stabilizer;
__block NSArray<LTSplineControlPoint *> *controlPoints;
__block LTSplineControlPoint *controlPoint1;
__block LTSplineControlPoint *controlPoint2;
__block LTSplineControlPoint *controlPoint3;
__block NSDictionary<NSString *, NSNumber *> *firstAttributes;
__block NSDictionary<NSString *, NSNumber *> *secondAttributes;
__block NSDictionary<NSString *, NSNumber *> *thirdAttributes;

beforeEach(^{
  stabilizer = [[DVNSplineControlPointStabilizer alloc] init];
  firstAttributes = @{kKey: @0};
  secondAttributes = @{kKey: @1};
  thirdAttributes = @{kKey: @2};
  controlPoint1 = [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointZero
                                                       attributes:firstAttributes];
  controlPoint2 = [[LTSplineControlPoint alloc] initWithTimestamp:1 location:CGPointMake(1, 0)
                                                       attributes:secondAttributes];
  controlPoint3 = [[LTSplineControlPoint alloc] initWithTimestamp:2 location:CGPointMake(2, 0)
                                                       attributes:thirdAttributes];
  controlPoints = @[controlPoint1, controlPoint2, controlPoint3];
});

context(@"invalid arguments", ^{
  it(@"should raise when providing negative smoothing intensity", ^{
    expect(^{
      [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:-0.5 preserveState:NO
                 fadeOutSmoothing:NO];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when providing zero smoothing intensity", ^{
    expect(^{
      [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:0 preserveState:NO
                 fadeOutSmoothing:NO];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"smoothing intensity", ^{
  it(@"should return correct number of points", ^{
    NSArray<LTSplineControlPoint *> *receivedControlPoints =
        [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:0.5 preserveState:NO
                   fadeOutSmoothing:NO];
    expect(receivedControlPoints).to.haveACountOf(controlPoints.count);
  });

  it(@"should return an empty array when no points were given", ^{
    expect([stabilizer pointsForPoints:@[] smoothedWithIntensity:0.5 preserveState:NO
                      fadeOutSmoothing:NO]).to.haveCountOf(0);
    expect([stabilizer pointsForPoints:@[] smoothedWithIntensity:1 preserveState:NO
                      fadeOutSmoothing:NO]).to.haveCountOf(0);
    expect([stabilizer pointsForPoints:@[] smoothedWithIntensity:1 preserveState:YES
                      fadeOutSmoothing:NO]).to.haveCountOf(0);
    expect([stabilizer pointsForPoints:@[] smoothedWithIntensity:1 preserveState:YES
                      fadeOutSmoothing:YES]).to.haveCountOf(0);
  });

  context(@"zero speed", ^{
    it(@"should return provided points, up to negligible deviation, for intensity close to 0", ^{
      NSArray<LTSplineControlPoint *> *receivedControlPoints =
          [stabilizer pointsForPoints:controlPoints
                smoothedWithIntensity:std::nextafter<CGFloat>(0, 1) preserveState:NO
                     fadeOutSmoothing:NO];
      expect(receivedControlPoints[0].location).to.equal(CGPointZero);
      expect(receivedControlPoints[0].attributes).to.equal(firstAttributes);

      expect(receivedControlPoints[1].location).to.equal(CGPointMake(1, 0));
      expect(receivedControlPoints[1].attributes).to.equal(secondAttributes);

      expect(receivedControlPoints[2].location).to.equal(CGPointMake(2, 0));
      expect(receivedControlPoints[2].attributes).to.equal(thirdAttributes);
    });

    it(@"should return smoothed points for medium smoothing intensity", ^{
      NSArray<LTSplineControlPoint *> *receivedControlPoints =
          [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:0.5 preserveState:NO
                     fadeOutSmoothing:NO];
      expect(receivedControlPoints[0].location).to.equal(CGPointZero);
      expect(receivedControlPoints[0].attributes).to.equal(firstAttributes);

      expect(receivedControlPoints[1].location).to.beCloseToPointWithin(CGPointMake(0.703, 0),
                                                                        kEpsilon);
      expect(receivedControlPoints[1].attributes.allKeys).to.equal(@[kKey]);
      expect([receivedControlPoints[1].attributes[kKey] CGFloatValue]).to.beCloseToWithin(0.703,
                                                                                          kEpsilon);

      expect(receivedControlPoints[2].location).to.beCloseToPointWithin(CGPointMake(1.6147, 0),
                                                                        kEpsilon);
      expect(receivedControlPoints[2].attributes.allKeys).to.equal(@[kKey]);
      expect([receivedControlPoints[2].attributes[kKey] CGFloatValue]).to.beCloseToWithin(1.6147,
                                                                                          kEpsilon);
    });

    it(@"should return smoothed points for large smoothing intensity", ^{
      NSArray<LTSplineControlPoint *> *receivedControlPoints =
          [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:1 preserveState:NO
                     fadeOutSmoothing:NO];
      expect(receivedControlPoints[0].location).to.equal(CGPointZero);
      expect(receivedControlPoints[0].attributes).to.equal(firstAttributes);

      expect(receivedControlPoints[1].location).to.beCloseToPointWithin(CGPointMake(0.406, 0),
                                                                        kEpsilon);
      expect(receivedControlPoints[1].attributes.allKeys).to.equal(@[kKey]);
      expect([receivedControlPoints[1].attributes[kKey] CGFloatValue]).to.beCloseToWithin(0.406,
                                                                                          kEpsilon);

      expect(receivedControlPoints[2].location).to.beCloseToPointWithin(CGPointMake(1.0531, 0),
                                                                        kEpsilon);
      expect(receivedControlPoints[2].attributes.allKeys).to.equal(@[kKey]);
      expect([receivedControlPoints[2].attributes[kKey] CGFloatValue]).to.beCloseToWithin(1.0531,
                                                                                          kEpsilon);
    });
  });

  context(@"non-zero speed", ^{
    beforeEach(^{
      firstAttributes = @{
        kKey: @0,
        kSpeedKey: @500
      };
      secondAttributes = @{
        kKey: @1,
        kSpeedKey: @500
      };
      thirdAttributes = @{
        kKey: @2,
        kSpeedKey: @500
      };
      controlPoints = @[[[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointZero
                                                             attributes:firstAttributes],
                        [[LTSplineControlPoint alloc] initWithTimestamp:1 location:CGPointMake(1, 0)
                                                             attributes:secondAttributes],
                        [[LTSplineControlPoint alloc] initWithTimestamp:2 location:CGPointMake(2, 0)
                                                             attributes:thirdAttributes]];
    });

    it(@"should return provided points, up to negligible deviation, for intensity close to 0", ^{
      NSArray<LTSplineControlPoint *> *receivedControlPoints =
          [stabilizer pointsForPoints:controlPoints
                smoothedWithIntensity:std::nextafter<CGFloat>(0, 1) preserveState:NO
                     fadeOutSmoothing:NO];
      expect(receivedControlPoints[0].location).to.equal(CGPointZero);
      expect(receivedControlPoints[0].attributes).to.equal(firstAttributes);

      expect(receivedControlPoints[1].location).to.equal(CGPointMake(1, 0));
      expect(receivedControlPoints[1].attributes).to.equal(secondAttributes);

      expect(receivedControlPoints[2].location).to.equal(CGPointMake(2, 0));
      expect(receivedControlPoints[2].attributes).to.equal(thirdAttributes);
    });

    it(@"should return smoothed points for medium smoothing intensity", ^{
      NSArray<LTSplineControlPoint *> *receivedControlPoints =
          [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:0.5 preserveState:NO
                     fadeOutSmoothing:NO];
      expect(receivedControlPoints[0].location).to.equal(CGPointZero);
      expect(receivedControlPoints[0].attributes).to.equal(firstAttributes);

      expect(receivedControlPoints[1].location).to.beCloseToPointWithin(CGPointMake(0.6092, 0),
                                                                        kEpsilon);
      expect(receivedControlPoints[1].attributes.count).to.equal(2);
      expect([receivedControlPoints[1].attributes[kKey] CGFloatValue]).to.beCloseToWithin(0.6092,
                                                                                          kEpsilon);
      expect([receivedControlPoints[1].attributes[kSpeedKey] CGFloatValue]).to.equal(500);

      expect(receivedControlPoints[2].location).to.beCloseToPointWithin(CGPointMake(1.4564, 0),
                                                                        kEpsilon);
      expect(receivedControlPoints[2].attributes.count).to.equal(2);
      expect([receivedControlPoints[2].attributes[kKey] CGFloatValue]).to.beCloseToWithin(1.4564,
                                                                                          kEpsilon);
      expect([receivedControlPoints[2].attributes[kSpeedKey] CGFloatValue]).to.equal(500);
    });

    it(@"should return smoothed points for large smoothing intensity", ^{
      NSArray<LTSplineControlPoint *> *receivedControlPoints =
          [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:1 preserveState:NO
                     fadeOutSmoothing:NO];
      expect(receivedControlPoints[0].location).to.equal(CGPointZero);
      expect(receivedControlPoints[0].attributes).to.equal(firstAttributes);

      expect(receivedControlPoints[1].location).to.beCloseToPointWithin(CGPointMake(0.2184, 0),
                                                                        kEpsilon);
      expect(receivedControlPoints[1].attributes.count).to.equal(2);
      expect([receivedControlPoints[1].attributes[kKey] CGFloatValue]).to.beCloseToWithin(0.2184,
                                                                                          kEpsilon);
      expect([receivedControlPoints[1].attributes[kSpeedKey] CGFloatValue]).to.equal(500);

      expect(receivedControlPoints[2].location).to.beCloseToPointWithin(CGPointMake(0.6075, 0),
                                                                        kEpsilon);
      expect(receivedControlPoints[2].attributes.count).to.equal(2);
      expect([receivedControlPoints[2].attributes[kKey] CGFloatValue]).to.beCloseToWithin(0.6075,
                                                                                          kEpsilon);
      expect([receivedControlPoints[2].attributes[kSpeedKey] CGFloatValue]).to.equal(500);
    });
  });
});

context(@"timestamps", ^{
  it(@"should return smoothed control points with correct timestamps", ^{
    NSArray<LTSplineControlPoint *> *receivedControlPoints =
        [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:0.5 preserveState:NO
                   fadeOutSmoothing:NO];
    expect(receivedControlPoints[0].timestamp).to.equal(0);
    expect(receivedControlPoints[1].timestamp).to.equal(1);
    expect(receivedControlPoints[2].timestamp).to.equal(2);
  });
});

context(@"consecutive calls", ^{
  it(@"should return smoothed points for consecutive calls", ^{
    NSArray<LTSplineControlPoint *> *receivedControlPoints =
        [stabilizer pointsForPoints:[controlPoints subarrayWithRange:NSMakeRange(0, 2)]
              smoothedWithIntensity:1 preserveState:NO fadeOutSmoothing:NO];
    expect(receivedControlPoints).to.haveACountOf(2);
    expect(receivedControlPoints[0].location).to.equal(CGPointZero);
    expect(receivedControlPoints[0].attributes).to.equal(firstAttributes);

    expect(receivedControlPoints[1].location).to.beCloseToPointWithin(CGPointMake(0.406, 0),
                                                                      kEpsilon);
    expect(receivedControlPoints[1].attributes.allKeys).to.equal(@[kKey]);
    expect([receivedControlPoints[1].attributes[kKey] CGFloatValue]).to.beCloseToWithin(0.406,
                                                                                        kEpsilon);

    receivedControlPoints =
        [stabilizer pointsForPoints:@[controlPoints[2]] smoothedWithIntensity:1 preserveState:NO
                   fadeOutSmoothing:NO];
    expect(receivedControlPoints).to.haveACountOf(1);
    expect(receivedControlPoints[0].location).to.beCloseToPointWithin(CGPointMake(1.0531, 0),
                                                                      kEpsilon);
    expect(receivedControlPoints[0].attributes.allKeys).to.equal(@[kKey]);
    expect([receivedControlPoints[0].attributes[kKey] CGFloatValue]).to.beCloseToWithin(1.0531,
                                                                                        kEpsilon);
  });

  context(@"reset", ^{
    it(@"should return correct smoothed points for consecutive calls without reset", ^{
      NSArray<LTSplineControlPoint *> *receivedControlPoints =
          [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:1 preserveState:NO
                     fadeOutSmoothing:NO];
      NSArray<LTSplineControlPoint *> *additionalReceivedControlPoints =
          [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:1 preserveState:NO
                     fadeOutSmoothing:NO];
      expect(receivedControlPoints).toNot.equal(additionalReceivedControlPoints);
    });

    it(@"should return correct smoothed points for consecutive calls with reset in between", ^{
      NSArray<LTSplineControlPoint *> *receivedControlPoints =
          [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:1 preserveState:NO
                     fadeOutSmoothing:NO];
      [stabilizer reset];
      NSArray<LTSplineControlPoint *> *additionalReceivedControlPoints =
          [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:1 preserveState:NO
                     fadeOutSmoothing:NO];
      expect(receivedControlPoints).to.equal(additionalReceivedControlPoints);
    });
  });
});

context(@"state preservation", ^{
  it(@"should preserve its state", ^{
    auto points = [stabilizer pointsForPoints:@[controlPoint1, controlPoint2]
                        smoothedWithIntensity:0.5 preserveState:NO fadeOutSmoothing:NO];
    expect([stabilizer pointsForPoints:@[controlPoint1] smoothedWithIntensity:0.5 preserveState:YES
                      fadeOutSmoothing:NO]).to.haveCountOf(1);

    auto additionalPoints = [stabilizer pointsForPoints:@[controlPoint3] smoothedWithIntensity:0.5
                                          preserveState:NO fadeOutSmoothing:NO];
    auto actualPoints = [points arrayByAddingObjectsFromArray:additionalPoints];
    auto expectedPoints = [[[DVNSplineControlPointStabilizer alloc] init]
                           pointsForPoints:@[controlPoint1, controlPoint2, controlPoint3]
                           smoothedWithIntensity:0.5 preserveState:NO fadeOutSmoothing:NO];
    expect(expectedPoints).to.equal(actualPoints);
  });

  it(@"should not displace the last point", ^{
    [stabilizer pointsForPoints:controlPoints smoothedWithIntensity:0.5 preserveState:NO
               fadeOutSmoothing:NO];
    NSArray<LTSplineControlPoint *> *additionalPoints = @[
      [[LTSplineControlPoint alloc] initWithTimestamp:3 location:CGPointMake(3, 0)
                                           attributes:@{kKey: @3}],
      [[LTSplineControlPoint alloc] initWithTimestamp:4 location:CGPointMake(4, 0)
                                                       attributes:@{kKey: @4}],
      [[LTSplineControlPoint alloc] initWithTimestamp:5 location:CGPointMake(5, 0)
                                                       attributes:@{kKey: @5}]
    ];
    auto smoothedAdditionalPoints = [stabilizer pointsForPoints:additionalPoints
                                          smoothedWithIntensity:0.5 preserveState:YES
                                               fadeOutSmoothing:YES];
    expect(additionalPoints.lastObject.location)
        .to.beCloseToPointWithin(smoothedAdditionalPoints.lastObject.location, kEpsilon);
  });
});

SpecEnd
