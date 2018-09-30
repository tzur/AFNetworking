// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSpeedBasedSplineControlPointBuffer.h"

#import "LTSplineControlPoint+AttributeKeys.h"

static NSArray<LTSplineControlPoint *> *LTFakeControlPoints(CGPoints locations,
                                                            std::vector<NSTimeInterval> times) {
  NSMutableArray<LTSplineControlPoint *> *controlPoints = [NSMutableArray array];

  for (CGPoints::size_type i = 0; i < locations.size(); ++i) {
    LTSplineControlPoint *mock = OCMClassMock([LTSplineControlPoint class]);

    CGPoint location = locations[i];
    CGPoint previousLocation = i > 0 ? locations[i - 1] : CGPointNull;
    NSTimeInterval timestamp = times[i];

    OCMStub([mock timestamp]).andReturn(timestamp);
    if (i > 0) {
      NSTimeInterval previousTimestamp = times[i - 1];
      CGFloat speed = CGPointDistance(location, previousLocation) / (timestamp - previousTimestamp);
      auto attributes = @{[LTSplineControlPoint keyForSpeedInScreenCoordinates]: @(speed)};
      OCMStub([mock attributes]).andReturn(attributes);
    } else {
      auto attributes = @{[LTSplineControlPoint keyForSpeedInScreenCoordinates]: @0};
      OCMStub([mock attributes]).andReturn(attributes);
    }
    OCMStub([mock copy]).andReturn(mock);
    [controlPoints addObject:mock];
  }

  return controlPoints;
}

SpecBegin(LTSpeedBasedSplineControlPointBuffer)

__block LTSpeedBasedSplineControlPointBuffer *buffer;

beforeEach(^{
  buffer = [[LTSpeedBasedSplineControlPointBuffer alloc]
            initWithMaxSpeed:10 timeIntervals:lt::Interval<NSTimeInterval>({1, 2})];
});

static const lt::Interval<NSTimeInterval> kTimeIntervals =
    lt::Interval<NSTimeInterval>({1.0 / 120, 1.0 / 20});

context(@"initialization", ^{
  it(@"should initialize with default values", ^{
    buffer = [[LTSpeedBasedSplineControlPointBuffer alloc] init];
    expect(buffer.bufferedControlPoints).to.equal(@[]);
    expect(buffer.maxSpeed).to.equal(5000);
    expect(buffer.timeIntervals == kTimeIntervals).to.beTruthy();
  });

  context(@"invalid initialization attempts", ^{
    it(@"should raise when attempting to initialize with negative maximum speed", ^{
      expect(^{
        buffer = [[LTSpeedBasedSplineControlPointBuffer alloc] initWithMaxSpeed:-1
                                                                  timeIntervals:kTimeIntervals];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to initialize with zero maximum speed", ^{
      expect(^{
        buffer = [[LTSpeedBasedSplineControlPointBuffer alloc] initWithMaxSpeed:0
                                                                  timeIntervals:kTimeIntervals];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"buffering", ^{
  it(@"should buffer single control point", ^{
    NSArray<LTSplineControlPoint *> *controlPoints = LTFakeControlPoints({CGPointZero}, {7});
    expect([buffer processAndPossiblyBufferControlPoints:controlPoints
                                                   flush:NO]).to.haveACountOf(0);
    expect(buffer.bufferedControlPoints).to.equal(controlPoints);
  });

  it(@"should buffer multiple control points", ^{
    NSArray<LTSplineControlPoint *> *controlPoints =
        LTFakeControlPoints({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2)},
                            {7, 7.5, 8});
    expect([buffer processAndPossiblyBufferControlPoints:controlPoints
                                                   flush:NO]).to.haveACountOf(0);
    expect(buffer.bufferedControlPoints).to.equal(controlPoints);
  });

  it(@"should buffer multiple control points with speed greater than maximum speed", ^{
    NSArray<LTSplineControlPoint *> *controlPoints =
        LTFakeControlPoints({CGPointZero, CGPointMake(0, 1)}, {7, 7.01});
    expect([buffer processAndPossiblyBufferControlPoints:controlPoints
                                                   flush:NO]).to.haveACountOf(0);
    expect(buffer.bufferedControlPoints).to.equal(controlPoints);
  });

  it(@"should buffer control points fulfilling condition", ^{
    NSArray<LTSplineControlPoint *> *controlPoints =
        LTFakeControlPoints({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2), CGPointMake(0, 3)},
                            {7, 7.5, 8, 8.5});
    expect([buffer processAndPossiblyBufferControlPoints:controlPoints flush:NO])
        .to.equal(@[controlPoints[0]]);
    expect(buffer.bufferedControlPoints).to.equal(@[controlPoints[1], controlPoints[2],
                                                    controlPoints[3]]);
  });

  it(@"should maintain buffered control points after processing empty array", ^{
    NSArray<LTSplineControlPoint *> *controlPoints =
        LTFakeControlPoints({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2), CGPointMake(0, 3)},
                            {7, 7.5, 8, 8.5});
    [buffer processAndPossiblyBufferControlPoints:controlPoints flush:NO];
    expect(buffer.bufferedControlPoints).to.equal(@[controlPoints[1], controlPoints[2],
                                                    controlPoints[3]]);
    [buffer processAndPossiblyBufferControlPoints:@[] flush:NO];
    expect(buffer.bufferedControlPoints).to.equal(@[controlPoints[1], controlPoints[2],
                                                    controlPoints[3]]);
  });

  context(@"iterative calls", ^{
    it(@"should buffer multiple control points", ^{
      NSArray<LTSplineControlPoint *> *allControlPoints =
        LTFakeControlPoints({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2), CGPointMake(0, 3),
                             CGPointMake(0, 4)}, {7, 7.5, 8, 8.5});
      NSArray<LTSplineControlPoint *> *controlPoints =
          [allControlPoints subarrayWithRange:NSMakeRange(0, 3)];
      expect([buffer processAndPossiblyBufferControlPoints:controlPoints flush:NO])
          .to.haveACountOf(0);
      expect(buffer.bufferedControlPoints).to.equal(controlPoints);

      controlPoints = [allControlPoints subarrayWithRange:NSMakeRange(3, 2)];
      expect([buffer processAndPossiblyBufferControlPoints:controlPoints flush:NO])
          .to.equal(@[]);
      expect(buffer.bufferedControlPoints).to.equal(allControlPoints);
    });

    it(@"should buffer control points fulfilling condition", ^{
      NSArray<LTSplineControlPoint *> *allControlPoints =
        LTFakeControlPoints({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2), CGPointMake(0, 3),
                             CGPointMake(0, 4), CGPointMake(0, 5)},
                            {7, 7.1, 7.2, 9, 10, 11});

      NSArray<LTSplineControlPoint *> *controlPoints =
          [allControlPoints subarrayWithRange:NSMakeRange(0, 4)];
      expect([buffer processAndPossiblyBufferControlPoints:controlPoints flush:NO])
          .to.equal(@[allControlPoints[0]]);
      expect(buffer.bufferedControlPoints).to.equal(@[allControlPoints[1], allControlPoints[2],
                                                      allControlPoints[3]]);

      controlPoints = [allControlPoints subarrayWithRange:NSMakeRange(4, 2)];
      expect([buffer processAndPossiblyBufferControlPoints:controlPoints flush:NO])
          .to.equal(@[allControlPoints[1], allControlPoints[2], allControlPoints[3]]);
      expect(buffer.bufferedControlPoints).to.equal(@[allControlPoints[4], allControlPoints[5]]);
    });
  });
});

context(@"flushing", ^{
  __block NSArray<LTSplineControlPoint *> *controlPoints;

  beforeEach(^{
    controlPoints =
        LTFakeControlPoints({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2), CGPointMake(0, 3)},
                            {7, 7.25, 7.5, 7.75});
  });

  it(@"should return all provided control points upon flushing", ^{
    NSArray<LTSplineControlPoint *> *flushedPoints =
        [buffer processAndPossiblyBufferControlPoints:controlPoints flush:YES];
    expect(flushedPoints).to.equal(controlPoints);
    expect(buffer.bufferedControlPoints).to.haveACountOf(0);
  });

  it(@"should return all buffered control points upon flushing", ^{
    [buffer processAndPossiblyBufferControlPoints:controlPoints flush:NO];
    NSArray<LTSplineControlPoint *> *flushedPoints =
        [buffer processAndPossiblyBufferControlPoints:@[] flush:YES];
    expect(flushedPoints).to.equal(controlPoints);
    expect(buffer.bufferedControlPoints).to.haveACountOf(0);
  });

  it(@"should return all buffered and provided control points upon flushing", ^{
    [buffer processAndPossiblyBufferControlPoints:controlPoints flush:NO];
    NSArray<LTSplineControlPoint *> *additionalControlPoints =
        LTFakeControlPoints({CGPointMake(0, 4), CGPointMake(0, 5)}, {7.004, 7.005});
    NSArray<LTSplineControlPoint *> *flushedPoints =
        [buffer processAndPossiblyBufferControlPoints:additionalControlPoints flush:YES];
    expect(flushedPoints)
        .to.equal([controlPoints arrayByAddingObjectsFromArray:additionalControlPoints]);
    expect(buffer.bufferedControlPoints).to.haveACountOf(0);
  });
});

SpecEnd
