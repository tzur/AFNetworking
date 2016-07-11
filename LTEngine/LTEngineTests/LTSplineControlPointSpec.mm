// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSplineControlPoint.h"

SpecBegin(LTSplineControlPoint)

__block LTSplineControlPoint *point;
__block NSDictionary<NSString *, NSNumber *> *attributes;

beforeEach(^{
  attributes = @{@"attribute": @7};
  point = [[LTSplineControlPoint alloc] initWithTimestamp:1 location:CGPointMake(2, 3)
                                               attributes:attributes];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(point.timestamp).to.equal(1);
    expect(point.location).to.equal(CGPointMake(2, 3));
    expect(point.location).to.equal(CGPointMake(2, 3));
    expect(point.xCoordinateOfLocation).to.equal(2);
    expect(point.yCoordinateOfLocation).to.equal(3);
    expect(point.attributes).to.equal(attributes);
  });

  it(@"should raise when attempting to initialize with NULL point", ^{
    expect(^{
      point = [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointNull];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      point = [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointNull
                                                   attributes:@{}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize with a copy of the given attributes", ^{
    NSMutableDictionary<NSString *, NSNumber *> *mutableAttributes =
        [NSMutableDictionary dictionary];
    point = [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointZero
                                                 attributes:mutableAttributes];
    expect(point.attributes).to.equal(mutableAttributes);
    expect(point.attributes).toNot.beIdenticalTo(mutableAttributes);
  });
});

context(@"NSObject protocol", ^{
  context(@"equality", ^{
    it(@"should return YES when comparing to itself", ^{
      expect([point isEqual:point]).to.beTruthy();
    });

    it(@"should return YES when comparing to equal point", ^{
      LTSplineControlPoint *anotherPoint =
          [[LTSplineControlPoint alloc] initWithTimestamp:1 location:CGPointMake(2, 3)
                                               attributes:attributes];
      expect([point isEqual:anotherPoint]).to.beTruthy();
      expect([point isEqualIgnoringTimestamp:anotherPoint]).to.beTruthy();
    });

    it(@"should return YES when comparing to equal point, ignoring timestamp", ^{
      LTSplineControlPoint *anotherPoint =
      [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(2, 3)
                                           attributes:attributes];
      expect([point isEqualIgnoringTimestamp:anotherPoint]).to.beTruthy();
    });

    it(@"should return NO when comparing to nil", ^{
      expect([point isEqual:nil]).to.beFalsy();
    });

    it(@"should return NO when comparing to an object of a different class", ^{
      expect([point isEqual:[[NSObject alloc] init]]).to.beFalsy();
    });

    it(@"should return NO when comparing to point with different timestamp", ^{
      LTSplineControlPoint *anotherPoint =
          [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(2, 3)
                                               attributes:attributes];
      expect([point isEqual:anotherPoint]).to.beFalsy();
    });

    it(@"should return NO when comparing to point with different location", ^{
      LTSplineControlPoint *anotherPoint =
          [[LTSplineControlPoint alloc] initWithTimestamp:1 location:CGPointMake(0, 1)
                                               attributes:attributes];
      expect([point isEqual:anotherPoint]).to.beFalsy();
      expect([point isEqualIgnoringTimestamp:anotherPoint]).to.beFalsy();
    });

    it(@"should return NO when comparing to point with different attributes", ^{
      LTSplineControlPoint *anotherPoint =
          [[LTSplineControlPoint alloc] initWithTimestamp:1 location:CGPointMake(0, 1)
                                               attributes:@{@"anotherAttribute": @7}];
      expect([point isEqual:anotherPoint]).to.beFalsy();
      expect([point isEqualIgnoringTimestamp:anotherPoint]).to.beFalsy();
    });
  });

  context(@"hash", ^{
    it(@"should return the same hash value for equal objects", ^{
      LTSplineControlPoint *anotherPoint =
          [[LTSplineControlPoint alloc] initWithTimestamp:point.timestamp location:point.location
                                               attributes:attributes];
      expect([point hash]).to.equal([anotherPoint hash]);
    });
  });
});

context(@"NSKeyValueCoding", ^{
  it(@"should return a queried key value from the attributes", ^{
    expect([point valueForKey:@"attribute"]).to.equal(@7);
  });

  it(@"should return a queried key value from the properties", ^{
    expect([point valueForKey:@keypath(point, location)]).to.equal($(CGPointMake(2, 3)));
  });
});

context(@"NSCopying protocol", ^{
  it(@"should return itself as copy, due to immutability", ^{
    expect([point copy]).to.beIdenticalTo(point);
  });
});

context(@"LTInterpolatableObject", ^{
  it(@"should provide the correct properties to interpolate", ^{
    NSSet<NSString *> *properties = [point propertiesToInterpolate];
    expect(properties.count).to.equal(3);
    expect(properties).to.contain(@keypath(point, xCoordinateOfLocation));
    expect(properties).to.contain(@keypath(point, yCoordinateOfLocation));
    expect(properties).to.contain(@"attribute");
  });
});

SpecEnd
