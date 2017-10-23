// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterval.h"

typedef lt::Interval<CGFloat> LTTestInterval;

SpecBegin(LTInterval)

context(@"initialization", ^{
  context(@"separate specification of end point closures", ^{
    it(@"should initialize correctly", ^{
      LTTestInterval interval({0, 1}, LTTestInterval::Closed, LTTestInterval::Open);
      expect(interval.min()).to.equal(0);
      expect(interval.max()).to.equal(1);
      expect(interval.minEndpointIncluded()).to.beTruthy();
      expect(interval.maxEndpointIncluded()).to.beFalsy();
    });

    it(@"should initialize correctly, independent of value order", ^{
      LTTestInterval interval({1, 0}, LTTestInterval::Closed, LTTestInterval::Open);
      expect(interval.min()).to.equal(0);
      expect(interval.max()).to.equal(1);
      expect(interval.minEndpointIncluded()).to.beTruthy();
      expect(interval.maxEndpointIncluded()).to.beFalsy();
    });
  });

  context(@"unified specification of end point closures", ^{
    it(@"should initialize correctly", ^{
      LTTestInterval interval({-1, 2}, LTTestInterval::Closed);
      expect(interval.min()).to.equal(-1);
      expect(interval.max()).to.equal(2);
      expect(interval.minEndpointIncluded()).to.beTruthy();
      expect(interval.maxEndpointIncluded()).to.beTruthy();
    });

    it(@"should initialize correctly, independent of value order", ^{
      LTTestInterval interval({2, -1}, LTTestInterval::Closed);
      expect(interval.min()).to.equal(-1);
      expect(interval.max()).to.equal(2);
      expect(interval.minEndpointIncluded()).to.beTruthy();
      expect(interval.maxEndpointIncluded()).to.beTruthy();
    });
  });

  context(@"implicit specification of end point closures", ^{
    it(@"should initialize correctly", ^{
      LTTestInterval interval({-1, 2});
      expect(interval.min()).to.equal(-1);
      expect(interval.max()).to.equal(2);
      expect(interval.minEndpointIncluded()).to.beTruthy();
      expect(interval.maxEndpointIncluded()).to.beTruthy();
    });

    it(@"should initialize correctly, independent of value order", ^{
      LTTestInterval interval({2, -1});
      expect(interval.min()).to.equal(-1);
      expect(interval.max()).to.equal(2);
      expect(interval.minEndpointIncluded()).to.beTruthy();
      expect(interval.maxEndpointIncluded()).to.beTruthy();
    });
  });
});

context(@"equality", ^{
  it(@"should compare equality to other intervals", ^{
    LTTestInterval interval({0, 1});
    LTTestInterval anotherInterval({0, 1});
    expect(interval == anotherInterval).to.beTruthy();

    anotherInterval = LTTestInterval({0, 1}, LTTestInterval::Open);
    expect(interval == anotherInterval).to.beFalsy();

    anotherInterval = LTTestInterval({0, 2});
    expect(interval == anotherInterval).to.beFalsy();
  });

  it(@"should compare inequality to other intervals", ^{
    LTTestInterval interval({0, 1});
    LTTestInterval anotherInterval({0, 1});
    expect(interval != anotherInterval).to.beFalsy();

    anotherInterval = LTTestInterval({0, 1}, LTTestInterval::Open);
    expect(interval != anotherInterval).to.beTruthy();

    anotherInterval = LTTestInterval({0, 2});
    expect(interval != anotherInterval).to.beTruthy();
  });
});

context(@"hash", ^{
  it(@"should compute a hash of an interval", ^{
    LTTestInterval interval({0, 1});
    LTTestInterval anotherInterval({0, 1});
    expect(interval.hash()).to.equal(anotherInterval.hash());
  });
});

context(@"empty intervals", ^{
  it(@"should indicate that a non-empty interval is not empty", ^{
    LTTestInterval interval({0, 1});
    expect(interval.isEmpty()).to.beFalsy();

    interval = LTTestInterval({0, 0});
    expect(interval.isEmpty()).to.beFalsy();
  });

  it(@"should indicate that an empty interval is empty", ^{
    LTTestInterval interval({0, 0}, LTTestInterval::Closed, LTTestInterval::Open);
    expect(interval.isEmpty()).to.beTruthy();

    interval = LTTestInterval({0, 0}, LTTestInterval::Closed, LTTestInterval::Open);
    expect(interval.isEmpty()).to.beTruthy();

    interval = LTTestInterval({0, 0}, LTTestInterval::Open);
    expect(interval.isEmpty()).to.beTruthy();

    interval = LTTestInterval({0, std::nextafter((CGFloat)0, (CGFloat)1)}, LTTestInterval::Open);
    expect(interval.isEmpty()).to.beTruthy();
  });
});

context(@"value inclusion", ^{
  it(@"should return correct results for containment queries of an open interval", ^{
    LTTestInterval interval({0, 1}, LTTestInterval::Open);
    expect(interval.contains((CGFloat)-1)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)-1))).to.beFalsy();
    expect(interval.contains(0)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)1))).to.beTruthy();
    expect(interval.contains(0.5)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)0))).to.beTruthy();
    expect(interval.contains(1)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)2))).to.beFalsy();
    expect(interval.contains(1.5)).to.beFalsy();
  });

  it(@"should return correct results for containment queries of a half-closed interval (a, b]", ^{
    LTTestInterval interval({0, 1}, LTTestInterval::Open, LTTestInterval::Closed);
    expect(interval.contains(-1)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)-1))).to.beFalsy();
    expect(interval.contains(0)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)1))).to.beTruthy();
    expect(interval.contains(0.5)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)0))).to.beTruthy();
    expect(interval.contains(1)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)2))).to.beFalsy();
    expect(interval.contains(1.5)).to.beFalsy();
  });

  it(@"should return correct results for containment queries of a half-closed interval [a, b)", ^{
    LTTestInterval interval({0, 1}, LTTestInterval::Closed, LTTestInterval::Open);
    expect(interval.contains(-1)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)-1))).to.beFalsy();
    expect(interval.contains(0)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)1))).to.beTruthy();
    expect(interval.contains(0.5)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)0))).to.beTruthy();
    expect(interval.contains(1)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)2))).to.beFalsy();
    expect(interval.contains(1.5)).to.beFalsy();
  });

  it(@"should return correct results for containment queries of a closed interval", ^{
    LTTestInterval interval({0, 1});
    expect(interval.contains(-1)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)-1))).to.beFalsy();
    expect(interval.contains(0)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)1))).to.beTruthy();
    expect(interval.contains(0.5)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)0))).to.beTruthy();
    expect(interval.contains(1)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)2))).to.beFalsy();
    expect(interval.contains(1.5)).to.beFalsy();
  });
});

context(@"intersection", ^{
  context(@"intersection indication", ^{
    it(@"should compute that two equal intervals intersect", ^{
      LTTestInterval interval({0, 1});
      LTTestInterval anotherInterval({0, 1});
      expect(interval.intersects(anotherInterval)).to.beTruthy();
    });

    it(@"should compute that two equal intervals with different boundary conditions intersect", ^{
      LTTestInterval interval({0, 1});
      LTTestInterval anotherInterval({0, 1}, LTTestInterval::Open);
      expect(interval.intersects(anotherInterval)).to.beTruthy();

      anotherInterval = LTTestInterval({0, 1}, LTTestInterval::Closed, LTTestInterval::Open);
      expect(interval.intersects(anotherInterval)).to.beTruthy();

      anotherInterval = LTTestInterval({0, 1}, LTTestInterval::Open, LTTestInterval::Closed);
      expect(interval.intersects(anotherInterval)).to.beTruthy();
    });

    it(@"should compute that two overlapping intervals intersect", ^{
      LTTestInterval interval({0, 1});
      LTTestInterval anotherInterval({-1, 0});
      expect(interval.intersects(anotherInterval)).to.beTruthy();

      anotherInterval = LTTestInterval({-1, 0.5});
      expect(interval.intersects(anotherInterval)).to.beTruthy();

      anotherInterval = LTTestInterval({-1, 0.5}, LTTestInterval::Open);
      expect(interval.intersects(anotherInterval)).to.beTruthy();

      anotherInterval = LTTestInterval({-1, 2});
      expect(interval.intersects(anotherInterval)).to.beTruthy();

      anotherInterval = LTTestInterval({-1, 2}, LTTestInterval::Open);
      expect(interval.intersects(anotherInterval)).to.beTruthy();

      anotherInterval = LTTestInterval({0.5, 2});
      expect(interval.intersects(anotherInterval)).to.beTruthy();

      anotherInterval = LTTestInterval({0.5, 2}, LTTestInterval::Open);
      expect(interval.intersects(anotherInterval)).to.beTruthy();

      anotherInterval = LTTestInterval({1, 2});
      expect(interval.intersects(anotherInterval)).to.beTruthy();
    });

    it(@"should compute that two non-overlapping intervals do not intersect", ^{
      LTTestInterval interval({0, 1});
      LTTestInterval anotherInterval({-2, -1});
      expect(interval.intersects(anotherInterval)).to.beFalsy();

      anotherInterval = LTTestInterval({-1, 0}, LTTestInterval::Closed, LTTestInterval::Open);
      expect(interval.intersects(anotherInterval)).to.beFalsy();

      anotherInterval = LTTestInterval({1, 2}, LTTestInterval::Open, LTTestInterval::Closed);
      expect(interval.intersects(anotherInterval)).to.beFalsy();

      anotherInterval = LTTestInterval({2, 3});
      expect(interval.intersects(anotherInterval)).to.beFalsy();
    });
  });

  context(@"intersection computation", ^{
    it(@"should compute the intersection of two equal intervals", ^{
      LTTestInterval interval({0, 1});
      LTTestInterval anotherInterval({0, 1});
      expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();
    });

    it(@"should compute that two equal intervals with different boundary conditions intersect", ^{
      LTTestInterval interval({0, 1});
      LTTestInterval anotherInterval({0, 1}, LTTestInterval::Closed, LTTestInterval::Open);
      expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

      anotherInterval = LTTestInterval({0, 1}, LTTestInterval::Open, LTTestInterval::Closed);
      expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

      anotherInterval = LTTestInterval({0, 1}, LTTestInterval::Open);
      expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();
    });

    it(@"should compute that two overlapping intervals intersect", ^{
      LTTestInterval interval({0, 1});
      LTTestInterval anotherInterval({-1, 0});
      expect(interval.intersectionWith(anotherInterval) ==
             LTTestInterval({0, 0})).to.beTruthy();

      anotherInterval = LTTestInterval({-1, 0.5});
      expect(interval.intersectionWith(anotherInterval) ==
             LTTestInterval({0, 0.5})).to.beTruthy();

      anotherInterval = LTTestInterval({-1, 0.5}, LTTestInterval::Open);
      expect(interval.intersectionWith(anotherInterval) ==
             LTTestInterval({0, 0.5}, LTTestInterval::Closed, LTTestInterval::Open)).to.beTruthy();

      anotherInterval = LTTestInterval({-1, 2});
      expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();

      anotherInterval = LTTestInterval({-1, 2}, LTTestInterval::Open);
      expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();

      anotherInterval = LTTestInterval({0.5, 2});
      expect(interval.intersectionWith(anotherInterval) ==
             LTTestInterval({0.5, 1})).to.beTruthy();

      anotherInterval = LTTestInterval({0.5, 2}, LTTestInterval::Open);
      expect(interval.intersectionWith(anotherInterval) ==
             LTTestInterval({0.5, 1}, LTTestInterval::Open, LTTestInterval::Closed)).to.beTruthy();

      anotherInterval = LTTestInterval({1, 2});
      expect(interval.intersectionWith(anotherInterval) ==
             LTTestInterval({1, 1})).to.beTruthy();
    });

    it(@"should compute that two non-overlapping intervals do not intersect", ^{
      LTTestInterval interval({0, 1});
      LTTestInterval anotherInterval({-2, -1});
      expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

      anotherInterval = LTTestInterval({-1, 0}, LTTestInterval::Closed, LTTestInterval::Open);
      expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

      anotherInterval = LTTestInterval({1, 2}, LTTestInterval::Open, LTTestInterval::Closed);
      expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

      anotherInterval = LTTestInterval({2, 3});
      expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();
    });
  });
});

SpecEnd
