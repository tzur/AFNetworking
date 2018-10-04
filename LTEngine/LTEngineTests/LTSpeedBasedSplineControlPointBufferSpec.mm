// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSpeedBasedSplineControlPointBuffer.h"

#import "LTSplineControlPoint+AttributeKeys.h"

static NSArray<LTSplineControlPoint *> *
    LTTestControlPoints(std::vector<std::pair<CGPoint, NSTimeInterval>> values) {
  auto controlPoints = [NSMutableArray<LTSplineControlPoint *> array];

  for (CGPoints::size_type i = 0; i < values.size(); ++i) {
    CGPoint location = values[i].first;
    NSTimeInterval timestamp = values[i].second;
    auto attributes = @{[LTSplineControlPoint keyForSpeedInScreenCoordinates]: @0};
    if (i > 0) {
      CGPoint previousLocation = values[i - 1].first;
      NSTimeInterval previousTimestamp = values[i - 1].second;
      CGFloat speed = CGPointDistance(location, previousLocation) / (timestamp - previousTimestamp);
      attributes = @{[LTSplineControlPoint keyForSpeedInScreenCoordinates]: @(speed)};
    }

    [controlPoints addObject:[[LTSplineControlPoint alloc] initWithTimestamp:timestamp
                                                                    location:location
                                                                  attributes:attributes]];
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
    NSArray<LTSplineControlPoint *> *controlPoints = LTTestControlPoints({{CGPointZero, 7}});
    expect([buffer processAndPossiblyBufferControlPoints:controlPoints
                                                   flush:NO]).to.haveACountOf(0);
    expect(buffer.bufferedControlPoints).to.equal(controlPoints);
  });

  it(@"should buffer multiple control points", ^{
    NSArray<LTSplineControlPoint *> *controlPoints =
        LTTestControlPoints({{CGPointZero, 7}, {CGPointMake(0, 1), 7.5}, {CGPointMake(0, 2), 8}});
    expect([buffer processAndPossiblyBufferControlPoints:controlPoints
                                                   flush:NO]).to.haveACountOf(0);
    expect(buffer.bufferedControlPoints).to.equal(controlPoints);
  });

  it(@"should buffer multiple control points with speed greater than maximum speed", ^{
    NSArray<LTSplineControlPoint *> *controlPoints =
        LTTestControlPoints({{CGPointZero, 7}, {CGPointMake(0, 1), 7.01}});
    expect([buffer processAndPossiblyBufferControlPoints:controlPoints
                                                   flush:NO]).to.haveACountOf(0);
    expect(buffer.bufferedControlPoints).to.equal(controlPoints);
  });

  it(@"should buffer control points fulfilling condition", ^{
    NSArray<LTSplineControlPoint *> *controlPoints =
        LTTestControlPoints({{CGPointZero, 7}, {CGPointMake(0, 1), 7.5}, {CGPointMake(0, 2), 8},
                             {CGPointMake(0, 3), 8.5}});
    expect([buffer processAndPossiblyBufferControlPoints:controlPoints flush:NO])
        .to.equal(@[controlPoints[0]]);
    expect(buffer.bufferedControlPoints).to.equal(@[controlPoints[1], controlPoints[2],
                                                    controlPoints[3]]);
  });

  it(@"should maintain buffered control points after processing empty array", ^{
    NSArray<LTSplineControlPoint *> *controlPoints =
        LTTestControlPoints({{CGPointZero, 7}, {CGPointMake(0, 1), 7.5}, {CGPointMake(0, 2), 8},
                             {CGPointMake(0, 3), 8.5}});
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
          LTTestControlPoints({{CGPointZero, 7}, {CGPointMake(0, 1), 7.1}, {CGPointMake(0, 2), 7.2},
                               {CGPointMake(0, 3), 7.3}, {CGPointMake(0, 4), 7.4}});
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
          LTTestControlPoints({{CGPointZero, 7}, {CGPointMake(0, 1), 7.1}, {CGPointMake(0, 2), 7.2},
                               {CGPointMake(0, 3), 9}, {CGPointMake(0, 4), 10},
                               {CGPointMake(0, 5), 11}});

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
        LTTestControlPoints({{CGPointZero, 7}, {CGPointMake(0, 1), 7.25}, {CGPointMake(0, 2), 7.5},
                             {CGPointMake(0, 3), 7.75}});
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
        LTTestControlPoints({{CGPointMake(0, 4), 7.004}, {CGPointMake(0, 5), 7.005}});
    NSArray<LTSplineControlPoint *> *flushedPoints =
        [buffer processAndPossiblyBufferControlPoints:additionalControlPoints flush:YES];
    expect(flushedPoints)
        .to.equal([controlPoints arrayByAddingObjectsFromArray:additionalControlPoints]);
    expect(buffer.bufferedControlPoints).to.haveACountOf(0);
  });
});

SpecEnd
