// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterval.h"

typedef lt::Interval<CGFloat> LTCGFloatInterval;
typedef lt::Interval<NSInteger> LTIntegerInterval;
typedef lt::Interval<NSUInteger> LTUIntegerInterval;

namespace lt {
template <typename T>
class IntervalSpec {
public:
  static void spec(SPTSpec *self) {
    static const CGFloat kEpsilon = 1e-7;

    context(@"initialization", ^{
      context(@"separate specification of end point closures", ^{
        it(@"should initialize correctly", ^{
          lt::Interval<T> interval({0, 1}, lt::Interval<T>::Closed, lt::Interval<T>::Open);
          expect(interval.inf()).to.equal(0);
          expect(interval.sup()).to.equal(1);
          expect(interval.infIncluded()).to.beTruthy();
          expect(interval.supIncluded()).to.beFalsy();
        });
      });

      context(@"unified specification of end point closures", ^{
        it(@"should initialize correctly", ^{
          lt::Interval<T> interval({0, 1}, lt::Interval<T>::Closed);
          expect(interval.inf()).to.equal(0);
          expect(interval.sup()).to.equal(1);
          expect(interval.infIncluded()).to.beTruthy();
          expect(interval.supIncluded()).to.beTruthy();
        });

        it(@"should initialize correctly, independent of value order", ^{
          lt::Interval<T> interval({1, 0}, lt::Interval<T>::Closed);
          expect(interval.inf()).to.equal(0);
          expect(interval.sup()).to.equal(1);
          expect(interval.infIncluded()).to.beTruthy();
          expect(interval.supIncluded()).to.beTruthy();
        });
      });

      context(@"implicit specification of end point closures", ^{
        it(@"should initialize correctly", ^{
          lt::Interval<T> interval({0, 1});
          expect(interval.inf()).to.equal(0);
          expect(interval.sup()).to.equal(1);
          expect(interval.infIncluded()).to.beTruthy();
          expect(interval.supIncluded()).to.beTruthy();
        });

        it(@"should initialize correctly, independent of value order", ^{
          lt::Interval<T> interval({2, 0});
          expect(interval.inf()).to.equal(0);
          expect(interval.sup()).to.equal(2);
          expect(interval.infIncluded()).to.beTruthy();
          expect(interval.supIncluded()).to.beTruthy();
        });
      });
    });

    context(@"hash", ^{
      it(@"should compute a hash of an interval", ^{
        lt::Interval<T> interval({0, 1});
        lt::Interval<T> anotherInterval({0, 1});
        expect(interval.hash()).to.equal(anotherInterval.hash());
      });
    });

    context(@"extrema", ^{
      it(@"should return correct extrema of a closed interval [a, b]", ^{
        lt::Interval<T> interval({0, 1});
        expect(*interval.min()).to.equal(0);
        expect(*interval.max()).to.equal(1);
      });

      it(@"should return empty optional when trying to retrieve minimum of empty interval", ^{
        lt::Interval<T> interval = lt::Interval<T>();
        std::experimental::optional<T> value = interval.min();
        expect(bool(value)).to.beFalsy();
      });

      it(@"should return empty optional when trying to retrieve maximum of empty interval", ^{
        lt::Interval<T> interval = lt::Interval<T>();
        std::experimental::optional<T> value = interval.max();
        expect(bool(value)).to.beFalsy();
      });
    });

    context(@"empty intervals", ^{
      it(@"should indicate that a non-empty interval is not empty", ^{
        lt::Interval<T> interval({0, 1});
        expect(interval.isEmpty()).to.beFalsy();

        interval = lt::Interval<T>({0, 0});
        expect(interval.isEmpty()).to.beFalsy();
      });

      it(@"should indicate that an empty interval is empty", ^{
        lt::Interval<T> interval({0, 0}, lt::Interval<T>::Closed, lt::Interval<T>::Open);
        expect(interval.isEmpty()).to.beTruthy();

        interval = lt::Interval<T>({0, 0}, lt::Interval<T>::Closed, lt::Interval<T>::Open);
        expect(interval.isEmpty()).to.beTruthy();

        interval = lt::Interval<T>({0, 0}, lt::Interval<T>::Open);
        expect(interval.isEmpty()).to.beTruthy();
      });
    });

    context(@"value inclusion", ^{
      context(@"open interval", ^{
        it(@"should return correct results for containment queries", ^{
          lt::Interval<T> interval({1, 3}, lt::Interval<T>::Open);
          expect(interval.contains(0)).to.beFalsy();
          expect(interval.contains(1)).to.beFalsy();
          expect(interval.contains(2)).to.beTruthy();
          expect(interval.contains(3)).to.beFalsy();
          expect(interval.contains(4)).to.beFalsy();
        });
      });

      context(@"left-open interval", ^{
        it(@"should return correct results for containment queries", ^{
          lt::Interval<T> interval({1, 3}, lt::Interval<T>::Open, lt::Interval<T>::Closed);
          expect(interval.contains(0)).to.beFalsy();
          expect(interval.contains(1)).to.beFalsy();
          expect(interval.contains(2)).to.beTruthy();
          expect(interval.contains(3)).to.beTruthy();
          expect(interval.contains(4)).to.beFalsy();
        });
      });

      context(@"right-open interval", ^{
        it(@"should return correct results for containment queries", ^{
          lt::Interval<T> interval({1, 3}, lt::Interval<T>::Closed, lt::Interval<T>::Open);
          expect(interval.contains(0)).to.beFalsy();
          expect(interval.contains(1)).to.beTruthy();
          expect(interval.contains(2)).to.beTruthy();
          expect(interval.contains(3)).to.beFalsy();
          expect(interval.contains(4)).to.beFalsy();
        });
      });

      context(@"closed interval", ^{
        it(@"should return correct results for containment queries", ^{
          lt::Interval<T> interval({1, 3});
          expect(interval.contains(0)).to.beFalsy();
          expect(interval.contains(1)).to.beTruthy();
          expect(interval.contains(2)).to.beTruthy();
          expect(interval.contains(3)).to.beTruthy();
          expect(interval.contains(4)).to.beFalsy();
        });
      });
    });

    context(@"intersection", ^{
      context(@"intersection indication", ^{
        it(@"should compute that two equal intervals intersect", ^{
          lt::Interval<T> interval({0, 1});
          lt::Interval<T> anotherInterval({0, 1});
          expect(interval.intersects(anotherInterval)).to.beTruthy();
        });

        context(@"different boundary conditions", ^{
          it(@"should compute that two intervals with different boundaries intersect", ^{
            lt::Interval<T> interval({0, 1});
            lt::Interval<T> anotherInterval({0, 1}, lt::Interval<T>::Closed, lt::Interval<T>::Open);
            expect(interval.intersects(anotherInterval)).to.beTruthy();

            anotherInterval = lt::Interval<T>({0, 1}, lt::Interval<T>::Open,
                                              lt::Interval<T>::Closed);
            expect(interval.intersects(anotherInterval)).to.beTruthy();
          });
        });

        it(@"should compute that two overlapping intervals intersect", ^{
          lt::Interval<T> interval({1, 3});
          lt::Interval<T> anotherInterval({0, 1});
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = lt::Interval<T>({0, 2.5});
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = lt::Interval<T>({0, 2.5}, lt::Interval<T>::Open);
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = lt::Interval<T>({0, 3});
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = lt::Interval<T>({0, 3}, lt::Interval<T>::Open);
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = lt::Interval<T>({2.5, 3});
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = lt::Interval<T>({2.5, 4}, lt::Interval<T>::Open);
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = lt::Interval<T>({2, 3});
          expect(interval.intersects(anotherInterval)).to.beTruthy();
        });

        it(@"should compute that two non-overlapping intervals do not intersect", ^{
          lt::Interval<T> interval({2, 3});
          lt::Interval<T> anotherInterval({0, 1});
          expect(interval.intersects(anotherInterval)).to.beFalsy();

          anotherInterval = lt::Interval<T>({0, 2}, lt::Interval<T>::Closed, lt::Interval<T>::Open);
          expect(interval.intersects(anotherInterval)).to.beFalsy();

          anotherInterval = lt::Interval<T>({3, 4}, lt::Interval<T>::Open, lt::Interval<T>::Closed);
          expect(interval.intersects(anotherInterval)).to.beFalsy();

          anotherInterval = lt::Interval<T>({4, 5});
          expect(interval.intersects(anotherInterval)).to.beFalsy();
        });
      });
    });

    context(@"linear interpolation", ^{
      it(@"should return its minimum value for factor of 0", ^{
        lt::Interval<T> interval({1, 2});
        expect(*interval.valueAt(0)).to.equal(1);
      });

      it(@"should return its center for factor of 0.5", ^{
        lt::Interval<T> interval({1, 2});
        expect(*interval.valueAt(0.5)).to.equal(1.5);
      });

      it(@"should return its maximum value for factor of 1", ^{
        lt::Interval<T> interval({1, 2});
        expect(*interval.valueAt(1)).to.equal(2);
      });

      it(@"should return empty optional when trying to interpolate value of empty interval", ^{
        lt::Interval<T> interval = lt::Interval<T>();
        std::experimental::optional<double> value = interval.valueAt(0);
        expect(bool(value)).to.beFalsy();
      });
    });

    context(@"parametric factor for linear interpolation", ^{
      __block lt::Interval<T> interval;

      beforeEach(^{
        interval = lt::Interval<T>({1, 5});
      });

      it(@"should return correct parametric factor for its minimum", ^{
        expect(*interval.parametricValue(*interval.min())).to.equal(0);
      });

      it(@"should return correct parametric factor for the minimum, in case of open interval", ^{
        interval = lt::Interval<T>({1, 5}, lt::Interval<T>::Open);
        expect(*interval.parametricValue(*interval.min())).to.equal(0);
      });

      it(@"should return correct parametric factor for its center", ^{
        expect(*interval.parametricValue(0.5 * (*interval.min() + *interval.max())))
            .to.equal(0.5);
      });

      it(@"should return correct parametric factor for its maximum", ^{
        expect(*interval.parametricValue(*interval.max())).to.equal(1);
      });

      it(@"should return correct parametric factor for its maximum, in case of open interval", ^{
        interval = lt::Interval<T>({1, 5}, lt::Interval<T>::Open);
        expect(*interval.parametricValue(*interval.max())).to.beCloseToWithin(1, kEpsilon);
      });

      it(@"should return empty optional when computing parametric factor of degenerate interval", ^{
        lt::Interval<T> interval = lt::Interval<T>({0, 0});
        std::experimental::optional<double> value = interval.parametricValue(0);
        expect(bool(value)).to.beFalsy();
      });

      it(@"should return empty optional when computing parametric factor of empty interval", ^{
        lt::Interval<T> interval = lt::Interval<T>();
        std::experimental::optional<double> value = interval.parametricValue(0);
        expect(bool(value)).to.beFalsy();
      });
    });

    context(@"length", ^{
      it(@"should return correct length of a closed interval", ^{
        lt::Interval<T> interval({0, 1});
        expect(interval.length()).to.equal(1);
      });

      it(@"should return correct length of an empty interval", ^{
        expect(lt::Interval<T>().length()).to.equal(0);
      });
    });

    context(@"clamped value", ^{
      __block lt::Interval<T> interval;

      context(@"closed interval", ^{
        beforeEach(^{
          interval = lt::Interval<T>({1, 3});
        });

        it(@"should return its minimum if value to project is smaller than the infimum", ^{
          expect(*interval.clamp(0)).to.equal(1);
        });

        it(@"should return its minimum if value to project equals the infimum", ^{
          expect(*interval.clamp(1)).to.equal(1);
        });

        it(@"should return the value to project if it is contained in the interval", ^{
          expect(*interval.clamp(2)).to.equal(2);
        });

        it(@"should return its maximum if value to project equals the supremum", ^{
          expect(*interval.clamp(3)).to.equal(3);
        });

        it(@"should return its maximum if value to project is greater than the supremum", ^{
          expect(*interval.clamp(4)).to.equal(3);
        });
      });

      context(@"open interval", ^{
        beforeEach(^{
          interval = lt::Interval<T>({1, 3}, lt::Interval<T>::Open);
        });

        it(@"should return its minimum if value to project is smaller than the infimum", ^{
          expect(*interval.clamp(0)).to.equal(*interval.min());
        });

        it(@"should return its minimum if value to project equals the infimum", ^{
          expect(*interval.clamp(1)).to.equal(*interval.min());
        });

        it(@"should return the value to project if it is contained in the interval", ^{
          expect(*interval.clamp(2)).to.equal(2);
        });

        it(@"should return its maximum if value to project equals the supremum", ^{
          expect(*interval.clamp(3)).to.equal(*interval.max());
        });

        it(@"should return its maximum if value to project is greater than the supremum", ^{
          expect(*interval.clamp(4)).to.equal(*interval.max());
        });
      });

      it(@"should return empty optional when computing clamped value for empty interval", ^{
        lt::Interval<T> interval = lt::Interval<T>();
        std::experimental::optional<T> value = interval.clamp(0);
        expect(bool(value)).to.beFalsy();
      });
    });

    context(@"description", ^{
      it(@"should return a proper description", ^{
        lt::Interval<T> interval = lt::Interval<T>({1, 2});
        expect(interval.description()).to.equal(@"[1, 2]");
        interval = lt::Interval<T>({2, 3}, lt::Interval<T>::Open);
        expect(interval.description()).to.equal(@"(2, 3)");
        interval = lt::Interval<T>({3, 4}, lt::Interval<T>::Open, lt::Interval<T>::Closed);
        expect(interval.description()).to.equal(@"(3, 4]");
        interval = lt::Interval<T>({4, 5}, lt::Interval<T>::Closed, lt::Interval<T>::Open);
        expect(interval.description()).to.equal(@"[4, 5)");
      });
    });
  }
};

} // namespace lt

SpecBegin(LTInterval)

lt::IntervalSpec<CGFloat>::spec(self);
lt::IntervalSpec<NSInteger>::spec(self);
lt::IntervalSpec<NSUInteger>::spec(self);

context(@"equality", ^{
  it(@"should compare equality to other intervals", ^{
    context(@"CGFloat intervals", ^{
      LTCGFloatInterval interval({0, 1});
      LTCGFloatInterval anotherInterval({0, 1});
      expect(interval == anotherInterval).to.beTruthy();

      anotherInterval = LTCGFloatInterval({0, 1}, LTCGFloatInterval::Open);
      expect(interval == anotherInterval).to.beFalsy();

      anotherInterval = LTCGFloatInterval({0, 2});
      expect(interval == anotherInterval).to.beFalsy();
    });

    context(@"NSInteger intervals", ^{
      LTIntegerInterval interval({0, 1});
      LTIntegerInterval anotherInterval({0, 1});
      expect(interval == anotherInterval).to.beTruthy();

      anotherInterval = LTIntegerInterval({0, 1}, LTIntegerInterval::Open);
      expect(interval == anotherInterval).to.beFalsy();

      anotherInterval = LTIntegerInterval({0, 2});
      expect(interval == anotherInterval).to.beFalsy();
    });

    context(@"NSUInteger intervals", ^{
      LTUIntegerInterval interval({0, 1});
      LTUIntegerInterval anotherInterval({0, 1});
      expect(interval == anotherInterval).to.beTruthy();

      anotherInterval = LTUIntegerInterval({0, 1}, LTUIntegerInterval::Open);
      expect(interval == anotherInterval).to.beFalsy();

      anotherInterval = LTUIntegerInterval({0, 2});
      expect(interval == anotherInterval).to.beFalsy();
    });
  });

  it(@"should compare inequality to other intervals", ^{
    context(@"CGFloat intervals", ^{
      LTCGFloatInterval interval({0, 1});
      LTCGFloatInterval anotherInterval({0, 1});
      expect(interval != anotherInterval).to.beFalsy();

      anotherInterval = LTCGFloatInterval({0, 1}, LTCGFloatInterval::Open);
      expect(interval != anotherInterval).to.beTruthy();

      anotherInterval = LTCGFloatInterval({0, 2});
      expect(interval != anotherInterval).to.beTruthy();
    });

    context(@"NSInteger intervals", ^{
      LTIntegerInterval interval({0, 1});
      LTIntegerInterval anotherInterval({0, 1});
      expect(interval != anotherInterval).to.beFalsy();

      anotherInterval = LTIntegerInterval({0, 1}, LTIntegerInterval::Open);
      expect(interval != anotherInterval).to.beTruthy();

      anotherInterval = LTIntegerInterval({0, 2});
      expect(interval != anotherInterval).to.beTruthy();
    });

    context(@"NSUInteger intervals", ^{
      LTUIntegerInterval interval({0, 1});
      LTUIntegerInterval anotherInterval({0, 1});
      expect(interval != anotherInterval).to.beFalsy();

      anotherInterval = LTUIntegerInterval({0, 1}, LTUIntegerInterval::Open);
      expect(interval != anotherInterval).to.beTruthy();

      anotherInterval = LTUIntegerInterval({0, 2});
      expect(interval != anotherInterval).to.beTruthy();
    });
  });
});

context(@"extrema", ^{
  context(@"CGFloat intervals", ^{
    it(@"should return correct extrema of a left-open interval", ^{
      LTCGFloatInterval interval({0, 1}, LTCGFloatInterval::Open, LTCGFloatInterval::Closed);
      expect(*interval.min()).to.equal(std::nextafter((CGFloat)0, (CGFloat)1));
      expect(*interval.max()).to.equal(1);
    });

    it(@"should return correct extrema of a right-open interval", ^{
      LTCGFloatInterval interval({0, 1}, LTCGFloatInterval::Closed, LTCGFloatInterval::Open);
      expect(*interval.min()).to.equal(0);
      expect(*interval.max()).to.equal(std::nextafter((CGFloat)1, (CGFloat)0));
    });

    it(@"should return correct extrema of an open interval", ^{
      LTCGFloatInterval interval({0, 1}, LTCGFloatInterval::Open);
      expect(*interval.min()).to.equal(std::nextafter((CGFloat)0, (CGFloat)1));
      expect(*interval.max()).to.equal(std::nextafter((CGFloat)1, (CGFloat)0));
    });
  });

  context(@"NSInteger intervals", ^{
    it(@"should return correct extrema of a left-open interval", ^{
      LTIntegerInterval interval({-1, 1}, LTIntegerInterval::Open, LTIntegerInterval::Closed);
      expect(*interval.min()).to.equal(0);
      expect(*interval.max()).to.equal(1);
    });

    it(@"should return correct extrema of a right-open interval", ^{
      LTIntegerInterval interval({-1, 1}, LTIntegerInterval::Closed, LTIntegerInterval::Open);
      expect(*interval.min()).to.equal(-1);
      expect(*interval.max()).to.equal(0);
    });

    it(@"should return correct extrema of an open interval", ^{
      LTIntegerInterval interval({-1, 1}, LTIntegerInterval::Open);
      expect(*interval.min()).to.equal(0);
      expect(*interval.max()).to.equal(0);
    });
  });

  context(@"NSUInteger intervals", ^{
    it(@"should return correct extrema of a left-open interval", ^{
      LTUIntegerInterval interval({0, 2}, LTUIntegerInterval::Open, LTUIntegerInterval::Closed);
      expect(*interval.min()).to.equal(1);
      expect(*interval.max()).to.equal(2);
    });

    it(@"should return correct extrema of a right-open interval", ^{
      LTUIntegerInterval interval({0, 2}, LTUIntegerInterval::Closed, LTUIntegerInterval::Open);
      expect(*interval.min()).to.equal(0);
      expect(*interval.max()).to.equal(1);
    });

    it(@"should return correct extrema of an open interval", ^{
      LTUIntegerInterval interval({0, 2}, LTUIntegerInterval::Open);
      expect(*interval.min()).to.equal(1);
      expect(*interval.max()).to.equal(1);
    });
  });
});

context(@"empty intervals", ^{
  it(@"should indicate that an empty CGFloat interval is empty", ^{
    LTCGFloatInterval interval({0, std::nextafter((CGFloat)0, (CGFloat)1)},
                               LTCGFloatInterval::Open);
    expect(interval.isEmpty()).to.beTruthy();
  });

  context(@"edge cases for floating-point intervals", ^{
    it(@"should indicate that an empty CGFloat interval is empty", ^{
      LTCGFloatInterval interval({-0.0, +0.0}, LTCGFloatInterval::Open);
      expect(interval.isEmpty()).to.beTruthy();
    });

    it(@"should indicate that an empty left-open CGFloat interval is empty", ^{
      LTCGFloatInterval interval({-0.0, +0.0}, LTCGFloatInterval::Open, LTCGFloatInterval::Closed);
      expect(interval.isEmpty()).to.beTruthy();
    });

    it(@"should indicate that an empty right-open CGFloat interval is empty", ^{
      LTCGFloatInterval interval({-0.0, +0.0}, LTCGFloatInterval::Closed, LTCGFloatInterval::Open);
      expect(interval.isEmpty()).to.beTruthy();
    });

    it(@"should indicate that a non-empty CGFloat interval is not empty", ^{
      LTCGFloatInterval interval({-0.0, +0.0});
      expect(interval.isEmpty()).to.beFalsy();
    });
  });

  it(@"should indicate that an empty NSInteger interval is empty", ^{
    LTIntegerInterval interval({-1, 0}, LTIntegerInterval::Open);
    expect(interval.isEmpty()).to.beTruthy();
  });

  it(@"should indicate that an empty NSUInteger interval is empty", ^{
    LTUIntegerInterval interval({0, 1}, LTUIntegerInterval::Open);
    expect(interval.isEmpty()).to.beTruthy();
  });
});

context(@"value inclusion", ^{
  context(@"open interval", ^{
    it(@"should return correct results for containment queries of a CGFloat interval", ^{
      LTCGFloatInterval interval({0.5, 1.5}, LTCGFloatInterval::Open);
      expect(interval.contains(0.5)).to.beFalsy();
      expect(interval.contains(std::nextafter((CGFloat)0.5, (CGFloat)1.5))).to.beTruthy();
      expect(interval.contains(std::nextafter((CGFloat)1.5, (CGFloat)0.5))).to.beTruthy();
      expect(interval.contains(1.5)).to.beFalsy();
    });
  });

  context(@"left-open interval", ^{
    it(@"should return correct results for containment queries of a CGFloat interval", ^{
      LTCGFloatInterval interval({0.5, 1.5}, LTCGFloatInterval::Open, LTCGFloatInterval::Closed);
      expect(interval.contains(0.5)).to.beFalsy();
      expect(interval.contains(std::nextafter((CGFloat)0.5, (CGFloat)1.5))).to.beTruthy();
      expect(interval.contains(std::nextafter((CGFloat)1.5, (CGFloat)0.5))).to.beTruthy();
      expect(interval.contains(1.5)).to.beTruthy();
    });
  });

  context(@"right-open interval", ^{
    it(@"should return correct results for containment queries of a CGFloat interval", ^{
      LTCGFloatInterval interval({0.5, 1.5}, LTCGFloatInterval::Closed, LTCGFloatInterval::Open);
      expect(interval.contains(0.5)).to.beTruthy();
      expect(interval.contains(std::nextafter((CGFloat)0.5, (CGFloat)1.5))).to.beTruthy();
      expect(interval.contains(std::nextafter((CGFloat)1.5, (CGFloat)0.5))).to.beTruthy();
      expect(interval.contains(1.5)).to.beFalsy();
    });
  });

  context(@"closed interval", ^{
    it(@"should return correct results for containment queries of a CGFloat interval", ^{
      LTCGFloatInterval interval({0.5, 1.5});
      expect(interval.contains(0.5)).to.beTruthy();
      expect(interval.contains(std::nextafter((CGFloat)0.5, (CGFloat)1.5))).to.beTruthy();
      expect(interval.contains(std::nextafter((CGFloat)1.5, (CGFloat)0.5))).to.beTruthy();
      expect(interval.contains(1.5)).to.beTruthy();
    });
  });
});

context(@"intersection", ^{
  context(@"intersection indication", ^{
    context(@"different boundary conditions", ^{
      it(@"should compute that two CGFLoat intervals with different boundaries intersect", ^{
        LTCGFloatInterval interval({0, 1});
        LTCGFloatInterval anotherInterval({0, 1}, LTCGFloatInterval::Open);
        expect(interval.intersects(anotherInterval)).to.beTruthy();
      });

      it(@"should compute that two NSInteger intervals with different boundaries intersect", ^{
        LTIntegerInterval interval({0, 1});
        LTIntegerInterval anotherInterval({0, 2}, LTIntegerInterval::Open);
        expect(interval.intersects(anotherInterval)).to.beTruthy();
      });

      it(@"should compute that two NSUInteger intervals with different boundaries intersect", ^{
        LTUIntegerInterval interval({0, 1});
        LTUIntegerInterval anotherInterval({0, 2}, LTUIntegerInterval::Open);
        expect(interval.intersects(anotherInterval)).to.beTruthy();
      });
    });
  });

  context(@"intersection computation", ^{
    context(@"CGFloat interval", ^{
      it(@"should compute the intersection of two equal intervals", ^{
        LTCGFloatInterval interval({0, 1});
        LTCGFloatInterval anotherInterval({0, 1});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();
      });

      it(@"should compute how two equal intervals with different boundary conditions intersect", ^{
        LTCGFloatInterval interval({0, 1});
        LTCGFloatInterval anotherInterval({0, 1}, LTCGFloatInterval::Closed,
                                          LTCGFloatInterval::Open);
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = LTCGFloatInterval({0, 1}, LTCGFloatInterval::Open,
                                            LTCGFloatInterval::Closed);
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = LTCGFloatInterval({0, 1}, LTCGFloatInterval::Open);
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();
      });

      it(@"should compute that two overlapping intervals intersect", ^{
        LTCGFloatInterval interval({0, 1});
        LTCGFloatInterval anotherInterval({-1, 0});
        expect(interval.intersectionWith(anotherInterval) ==
               LTCGFloatInterval({0, 0})).to.beTruthy();

        anotherInterval = LTCGFloatInterval({-1, 0.5});
        expect(interval.intersectionWith(anotherInterval) ==
               LTCGFloatInterval({0, 0.5})).to.beTruthy();

        anotherInterval = LTCGFloatInterval({-1, 0.5}, LTCGFloatInterval::Open);
        expect(interval.intersectionWith(anotherInterval) ==
               LTCGFloatInterval({0, 0.5}, LTCGFloatInterval::Closed,
                                 LTCGFloatInterval::Open)).to.beTruthy();

        anotherInterval = LTCGFloatInterval({-1, 2});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();

        anotherInterval = LTCGFloatInterval({-1, 2}, LTCGFloatInterval::Open);
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();

        anotherInterval = LTCGFloatInterval({0.5, 2});
        expect(interval.intersectionWith(anotherInterval) ==
               LTCGFloatInterval({0.5, 1})).to.beTruthy();

        anotherInterval = LTCGFloatInterval({0.5, 2}, LTCGFloatInterval::Open);
        expect(interval.intersectionWith(anotherInterval) ==
               LTCGFloatInterval({0.5, 1}, LTCGFloatInterval::Open,
                                 LTCGFloatInterval::Closed)).to.beTruthy();

        anotherInterval = LTCGFloatInterval({1, 2});
        expect(interval.intersectionWith(anotherInterval) ==
               LTCGFloatInterval({1, 1})).to.beTruthy();
      });

      it(@"should compute that two non-overlapping intervals do not intersect", ^{
        LTCGFloatInterval interval({0, 1});
        LTCGFloatInterval anotherInterval({-2, -1});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = LTCGFloatInterval({-1, 0}, LTCGFloatInterval::Closed,
                                            LTCGFloatInterval::Open);
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = LTCGFloatInterval({1, 2}, LTCGFloatInterval::Open,
                                            LTCGFloatInterval::Closed);
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = LTCGFloatInterval({2, 3});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();
      });
    });

    context(@"NSInteger interval", ^{
      it(@"should compute the intersection of two equal intervals", ^{
        LTIntegerInterval interval({0, 1});
        LTIntegerInterval anotherInterval({0, 1});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();
      });

      it(@"should compute how two equal intervals with different boundary conditions intersect", ^{
        LTIntegerInterval interval({0, 1});
        LTIntegerInterval anotherInterval({0, 1}, LTIntegerInterval::Closed,
                                          LTIntegerInterval::Open);
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = LTIntegerInterval({0, 1}, LTIntegerInterval::Open,
                                            LTIntegerInterval::Closed);
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = LTIntegerInterval({0, 1}, LTIntegerInterval::Open);
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();
      });

      it(@"should compute that two overlapping intervals intersect", ^{
        LTIntegerInterval interval({0, 1});
        LTIntegerInterval anotherInterval({-1, 0});
        expect(interval.intersectionWith(anotherInterval) ==
               LTIntegerInterval({0, 0})).to.beTruthy();

        anotherInterval = LTIntegerInterval({-1, 1});
        expect(interval.intersectionWith(anotherInterval) ==
               LTIntegerInterval({0, 1})).to.beTruthy();

        anotherInterval = LTIntegerInterval({-1, 1}, LTIntegerInterval::Open);
        expect(interval.intersectionWith(anotherInterval) ==
               LTIntegerInterval({0, 1}, LTIntegerInterval::Closed,
                                 LTIntegerInterval::Open)).to.beTruthy();

        anotherInterval = LTIntegerInterval({-1, 2});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();

        anotherInterval = LTIntegerInterval({-1, 2}, LTIntegerInterval::Open);
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();

        anotherInterval = LTIntegerInterval({1, 2});
        expect(interval.intersectionWith(anotherInterval) ==
               LTIntegerInterval({1, 1})).to.beTruthy();

        anotherInterval = LTIntegerInterval({1, 2}, LTIntegerInterval::Closed,
                                            LTIntegerInterval::Open);
        expect(interval.intersectionWith(anotherInterval) ==
               LTIntegerInterval({1, 1})).to.beTruthy();

        anotherInterval = LTIntegerInterval({1, 2});
        expect(interval.intersectionWith(anotherInterval) ==
               LTIntegerInterval({1, 1})).to.beTruthy();
      });

      it(@"should compute that two non-overlapping intervals do not intersect", ^{
        LTIntegerInterval interval({0, 1});
        LTIntegerInterval anotherInterval({-2, -1});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = LTIntegerInterval({-1, 0}, LTIntegerInterval::Closed,
                                            LTIntegerInterval::Open);
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = LTIntegerInterval({1, 2}, LTIntegerInterval::Open,
                                            LTIntegerInterval::Closed);
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = LTIntegerInterval({2, 3});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();
      });
    });

    context(@"NSUInteger interval", ^{
      it(@"should compute the intersection of two equal intervals", ^{
        LTIntegerInterval interval({0, 1});
        LTIntegerInterval anotherInterval({0, 1});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();
      });

      it(@"should compute how two equal intervals with different boundary conditions intersect", ^{
        LTIntegerInterval interval({0, 1});
        LTIntegerInterval anotherInterval({0, 1}, LTIntegerInterval::Closed,
                                          LTIntegerInterval::Open);
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = LTIntegerInterval({0, 1}, LTIntegerInterval::Open,
                                            LTIntegerInterval::Closed);
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = LTIntegerInterval({0, 1}, LTIntegerInterval::Open);
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();
      });

      it(@"should compute that two overlapping intervals intersect", ^{
        LTIntegerInterval interval({0, 1});
        LTIntegerInterval anotherInterval({0, 0});
        expect(interval.intersectionWith(anotherInterval) == LTIntegerInterval({0, 0}))
            .to.beTruthy();

        anotherInterval = LTIntegerInterval({0, 1});
        expect(interval.intersectionWith(anotherInterval) == LTIntegerInterval({0, 1}))
            .to.beTruthy();

        anotherInterval = LTIntegerInterval({0, 1}, LTIntegerInterval::Open);
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = LTIntegerInterval({0, 2});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();

        anotherInterval = LTIntegerInterval({0, 2}, LTIntegerInterval::Open);
        expect(interval.intersectionWith(anotherInterval) ==
               LTIntegerInterval({0, 1}, LTIntegerInterval::Open, LTIntegerInterval::Closed))
            .to.beTruthy();

        anotherInterval = LTIntegerInterval({0, 2}, LTIntegerInterval::Open,
                                            LTIntegerInterval::Closed);
        expect(interval.intersectionWith(anotherInterval) ==
               LTIntegerInterval({0, 1}, LTIntegerInterval::Open, LTIntegerInterval::Closed))
            .to.beTruthy();

        anotherInterval = LTIntegerInterval({0, 2}, LTIntegerInterval::Closed,
                                            LTIntegerInterval::Open);
        expect(interval.intersectionWith(anotherInterval) == LTIntegerInterval({0, 1}))
            .to.beTruthy();

        anotherInterval = LTIntegerInterval({1, 2});
        expect(interval.intersectionWith(anotherInterval) == LTIntegerInterval({1, 1}))
            .to.beTruthy();
      });

      it(@"should compute that two non-overlapping intervals do not intersect", ^{
        LTIntegerInterval interval({0, 1});
        LTIntegerInterval anotherInterval({0, 0}, LTIntegerInterval::Open,
                                          LTIntegerInterval::Closed);
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = LTIntegerInterval({0, 0}, LTIntegerInterval::Closed,
                                            LTIntegerInterval::Open);
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = LTIntegerInterval({1, 2}, LTIntegerInterval::Open,
                                            LTIntegerInterval::Closed);
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = LTIntegerInterval({2, 3});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();
      });
    });
  });
});

context(@"linear interpolation", ^{
  it(@"should return its minimum value for factor of 0, in case of open CGFloat interval", ^{
    LTCGFloatInterval interval({-1, 2}, LTCGFloatInterval::Open);
    expect(*interval.valueAt(0)).to.equal(std::nextafter((CGFloat)-1, (CGFloat)2));
  });

  it(@"should return its minimum value for factor of 0, in case of open NSInteger interval", ^{
    LTIntegerInterval interval({-1, 1}, LTIntegerInterval::Open);
    expect(*interval.valueAt(0)).to.equal(0);
  });

  it(@"should return its minimum value for factor of 0, in case of open NSUInteger interval", ^{
    LTUIntegerInterval interval({0, 2}, LTUIntegerInterval::Open);
    expect(*interval.valueAt(0)).to.equal(1);
  });

  it(@"should return its maximum value for factor of 1, in case of open CGFloat interval", ^{
    LTCGFloatInterval interval({-1, 2}, LTCGFloatInterval::Open);
    expect(*interval.valueAt(1)).to.equal(std::nextafter((CGFloat)2, (CGFloat)-1));
  });

  it(@"should return its maximum value for factor of 1, in case of open NSInteger interval", ^{
    LTIntegerInterval interval({-1, 1}, LTIntegerInterval::Open);
    expect(*interval.valueAt(1)).to.equal(0);
  });

  it(@"should return its maximum value for factor of 1, in case of open NSUInteger interval", ^{
    LTUIntegerInterval interval({0, 2}, LTUIntegerInterval::Open);
    expect(*interval.valueAt(1)).to.equal(1);
  });
});

context(@"length", ^{
  context(@"CGFloat interval", ^{
    it(@"should return correct length of a left-open interval", ^{
      LTCGFloatInterval interval({0, 1}, LTCGFloatInterval::Open, LTCGFloatInterval::Closed);
      expect(interval.length()).to.equal(1 - std::nextafter((CGFloat)0, (CGFloat)1));
    });

    it(@"should return correct length of a right-open interval", ^{
      LTCGFloatInterval interval({0, 1}, LTCGFloatInterval::Closed, LTCGFloatInterval::Open);
      expect(interval.length()).to.equal(std::nextafter((CGFloat)1, (CGFloat)0));
    });

    it(@"should return correct length of an open interval", ^{
      LTCGFloatInterval interval({0, 1}, LTCGFloatInterval::Open);
      expect(interval.length()).to.equal(std::nextafter((CGFloat)1, (CGFloat)0) -
                                         std::nextafter((CGFloat)0, (CGFloat)1));
    });
  });

  context(@"NSInteger interval", ^{
    it(@"should return correct length of a left-open interval", ^{
      LTIntegerInterval interval({-2, 2}, LTIntegerInterval::Open, LTIntegerInterval::Closed);
      expect(interval.length()).to.equal(3);
    });

    it(@"should return correct length of a right-open interval", ^{
      LTIntegerInterval interval({-2, 2}, LTIntegerInterval::Closed, LTIntegerInterval::Open);
      expect(interval.length()).to.equal(3);
    });

    it(@"should return correct length of an open interval", ^{
      LTIntegerInterval interval({-2, 2}, LTIntegerInterval::Open);
      expect(interval.length()).to.equal(2);
    });
  });

  context(@"NSUInteger interval", ^{
    it(@"should return correct length of a left-open interval", ^{
      LTUIntegerInterval interval({0, 4}, LTUIntegerInterval::Open, LTUIntegerInterval::Closed);
      expect(interval.length()).to.equal(3);
    });

    it(@"should return correct length of a right-open interval", ^{
      LTUIntegerInterval interval({0, 4}, LTUIntegerInterval::Closed, LTUIntegerInterval::Open);
      expect(interval.length()).to.equal(3);
    });

    it(@"should return correct length of an open interval", ^{
      LTUIntegerInterval interval({0, 4}, LTUIntegerInterval::Open);
      expect(interval.length()).to.equal(2);
    });
  });
});

context(@"description", ^{
  it(@"should return a proper description of a CGFloat interval", ^{
    LTCGFloatInterval interval({0.5, 2});
    expect(interval.description()).to.equal(@"[0.5, 2]");
  });

  it(@"should return a proper description of an NSInteger interval", ^{
    LTIntegerInterval interval({-1, 2});
    expect(interval.description()).to.equal(@"[-1, 2]");
  });

  it(@"should return a proper description of an NSUInteger interval", ^{
    LTUIntegerInterval interval({0, 2});
    expect(interval.description()).to.equal(@"[0, 2]");
  });
});

context(@"interval from string", ^{
  context(@"CGFloat intervals", ^{
    it(@"should return correct open CGFloat interval for a given string", ^{
      lt::Interval<CGFloat> interval = LTCGFloatIntervalFromString(@"(-0.25, 1.25)");
      expect(interval == lt::Interval<CGFloat>({-0.25, 1.25}, lt::Interval<CGFloat>::Open))
          .to.beTruthy();
    });

    it(@"should return correct left-open CGFloat interval for a given string", ^{
      lt::Interval<CGFloat> interval = LTCGFloatIntervalFromString(@"(-0.5, 1.5]");
      expect(interval == lt::Interval<CGFloat>({-0.5, 1.5}, lt::Interval<CGFloat>::Open,
                                               lt::Interval<CGFloat>::Closed)).to.beTruthy();
    });

    it(@"should return correct right-open CGFloat interval for a given string", ^{
      lt::Interval<CGFloat> interval = LTCGFloatIntervalFromString(@"[-0.75, 1.75)");
      expect(interval == lt::Interval<CGFloat>({-0.75, 1.75}, lt::Interval<CGFloat>::Closed,
                                               lt::Interval<CGFloat>::Open)).to.beTruthy();
    });

    it(@"should return correct closed CGFloat interval for a given string", ^{
      lt::Interval<CGFloat> interval = LTCGFloatIntervalFromString(@"[-1.0, 2.0]");
      expect(interval == lt::Interval<CGFloat>({-1, 2})).to.beTruthy();
    });

    context(@"string with invalid format", ^{
      it(@"should return empty CGFloat intervals for given strings with invalid formats", ^{
        lt::Interval<CGFloat> interval = LTCGFloatIntervalFromString(@"(-0.25)");
        expect(interval.inf()).to.equal(0);
        expect(interval.isEmpty()).to.beTruthy();

        interval = LTCGFloatIntervalFromString(@"(-0.25, , 2.0)");
        expect(interval.inf()).to.equal(0);
        expect(interval.isEmpty()).to.beTruthy();

        interval = LTCGFloatIntervalFromString(@"()");
        expect(interval.inf()).to.equal(0);
        expect(interval.isEmpty()).to.beTruthy();
      });
    });
  });

  context(@"NSInteger intervals", ^{
    it(@"should return correct open NSInteger interval for a given string", ^{
      lt::Interval<NSInteger> interval = LTNSIntegerIntervalFromString(@"(-7, 8)");
      expect(interval == lt::Interval<NSInteger>({-7, 8}, lt::Interval<NSInteger>::Open))
          .to.beTruthy();
    });

    it(@"should return correct left-open NSInteger interval for a given string", ^{
      lt::Interval<NSInteger> interval = LTNSIntegerIntervalFromString(@"(-6, 7]");
      expect(interval == lt::Interval<NSInteger>({-6, 7}, lt::Interval<NSInteger>::Open,
                                                 lt::Interval<NSInteger>::Closed)).to.beTruthy();
    });

    it(@"should return correct right-open NSInteger interval for a given string", ^{
      lt::Interval<NSInteger> interval = LTNSIntegerIntervalFromString(@"[-5, 6)");
      expect(interval == lt::Interval<NSInteger>({-5, 6}, lt::Interval<NSInteger>::Closed,
                                                 lt::Interval<NSInteger>::Open)).to.beTruthy();
    });

    it(@"should return correct closed NSInteger interval for a given string", ^{
      lt::Interval<NSInteger> interval = LTNSIntegerIntervalFromString(@"[-4, 5]");
      expect(interval == lt::Interval<NSInteger>({-4, 5})).to.beTruthy();
    });

    context(@"string with invalid format", ^{
      it(@"should return empty NSInteger intervals for given strings with invalid formats", ^{
        lt::Interval<NSInteger> interval = LTNSIntegerIntervalFromString(@"(-4)");
        expect(interval.inf()).to.equal(0);
        expect(interval.isEmpty()).to.beTruthy();

        interval = LTNSIntegerIntervalFromString(@"(-4, , 5)");
        expect(interval.inf()).to.equal(0);
        expect(interval.isEmpty()).to.beTruthy();

        interval = LTNSIntegerIntervalFromString(@"()");
        expect(interval.inf()).to.equal(0);
        expect(interval.isEmpty()).to.beTruthy();
      });
    });
  });

  context(@"NSUInteger intervals", ^{
    it(@"should return correct open NSUInteger interval for a given string", ^{
      lt::Interval<NSUInteger> interval = LTNSUIntegerIntervalFromString(@"(7, 8)");
      expect(interval == lt::Interval<NSUInteger>({7, 8}, lt::Interval<NSUInteger>::Open))
          .to.beTruthy();
    });

    it(@"should return correct left-open NSUInteger interval for a given string", ^{
      lt::Interval<NSUInteger> interval = LTNSUIntegerIntervalFromString(@"(6, 7]");
      expect(interval == lt::Interval<NSUInteger>({6, 7}, lt::Interval<NSUInteger>::Open,
                                                  lt::Interval<NSUInteger>::Closed)).to.beTruthy();
    });

    it(@"should return correct right-open NSUInteger interval for a given string", ^{
      lt::Interval<NSUInteger> interval = LTNSUIntegerIntervalFromString(@"[5, 6)");
      expect(interval == lt::Interval<NSUInteger>({5, 6}, lt::Interval<NSUInteger>::Closed,
                                                  lt::Interval<NSUInteger>::Open)).to.beTruthy();
    });

    it(@"should return correct closed NSUInteger interval for a given string", ^{
      lt::Interval<NSUInteger> interval = LTNSUIntegerIntervalFromString(@"[4, 5]");
      expect(interval == lt::Interval<NSUInteger>({4, 5})).to.beTruthy();
    });

    context(@"string with invalid format", ^{
      it(@"should return empty NSInteger intervals for given strings with invalid formats", ^{
        lt::Interval<NSInteger> interval = LTNSIntegerIntervalFromString(@"(4)");
        expect(interval.inf()).to.equal(0);
        expect(interval.isEmpty()).to.beTruthy();

        interval = LTNSIntegerIntervalFromString(@"(4, , 5)");
        expect(interval.inf()).to.equal(0);
        expect(interval.isEmpty()).to.beTruthy();

        interval = LTNSIntegerIntervalFromString(@"()");
        expect(interval.inf()).to.equal(0);
        expect(interval.isEmpty()).to.beTruthy();
      });
    });
  });
});

SpecEnd
