// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterval.h"

using lt::Interval;

namespace lt {
template <typename T>
class IntervalSpec {
public:
  static void spec(SPTSpec *self) {
    static const CGFloat kEpsilon = 1e-7;

    context(@"initialization", ^{
      context(@"separate specification of end point closures", ^{
        it(@"should initialize correctly", ^{
          Interval<T> interval({0, 1}, Interval<T>::Closed, Interval<T>::Open);
          expect(interval.inf()).to.equal(0);
          expect(interval.sup()).to.equal(1);
          expect(interval.infIncluded()).to.beTruthy();
          expect(interval.supIncluded()).to.beFalsy();
        });
      });

      context(@"unified specification of end point closures", ^{
        it(@"should initialize correctly", ^{
          Interval<T> interval({0, 1}, Interval<T>::Closed);
          expect(interval.inf()).to.equal(0);
          expect(interval.sup()).to.equal(1);
          expect(interval.infIncluded()).to.beTruthy();
          expect(interval.supIncluded()).to.beTruthy();
        });

        it(@"should initialize correctly, independent of value order", ^{
          Interval<T> interval({1, 0}, Interval<T>::Closed);
          expect(interval.inf()).to.equal(0);
          expect(interval.sup()).to.equal(1);
          expect(interval.infIncluded()).to.beTruthy();
          expect(interval.supIncluded()).to.beTruthy();
        });
      });

      context(@"implicit specification of end point closures", ^{
        it(@"should initialize correctly", ^{
          Interval<T> interval({0, 1});
          expect(interval.inf()).to.equal(0);
          expect(interval.sup()).to.equal(1);
          expect(interval.infIncluded()).to.beTruthy();
          expect(interval.supIncluded()).to.beTruthy();
        });

        it(@"should initialize correctly, independent of value order", ^{
          Interval<T> interval({2, 0});
          expect(interval.inf()).to.equal(0);
          expect(interval.sup()).to.equal(2);
          expect(interval.infIncluded()).to.beTruthy();
          expect(interval.supIncluded()).to.beTruthy();
        });
      });

      context(@"closed single-value interval", ^{
        it(@"should initialize correctly", ^{
          Interval<T> interval(7);
          expect(interval.inf()).to.equal(7);
          expect(interval.sup()).to.equal(7);
          expect(interval.infIncluded()).to.beTruthy();
          expect(interval.supIncluded()).to.beTruthy();
        });
      });
    });

    context(@"factory methods", ^{
      it(@"should return an open interval", ^{
        Interval<T> interval = Interval<T>::oo({7, 8});
        expect(interval.inf()).to.equal(7);
        expect(interval.sup()).to.equal(8);
        expect(interval.infIncluded()).to.beFalsy();
        expect(interval.supIncluded()).to.beFalsy();
      });

      it(@"should return a left-open interval", ^{
        Interval<T> interval = Interval<T>::oc({7, 8});
        expect(interval.inf()).to.equal(7);
        expect(interval.sup()).to.equal(8);
        expect(interval.infIncluded()).to.beFalsy();
        expect(interval.supIncluded()).to.beTruthy();
      });

      it(@"should return a right-open interval", ^{
        Interval<T> interval = Interval<T>::co({7, 8});
        expect(interval.inf()).to.equal(7);
        expect(interval.sup()).to.equal(8);
        expect(interval.infIncluded()).to.beTruthy();
        expect(interval.supIncluded()).to.beFalsy();
      });
    });

    context(@"fixed values", ^{
      it(@"should return a [0, 1] interval", ^{
        Interval<T> interval = Interval<T>::zeroToOne();
        expect(interval.inf()).to.equal(0);
        expect(interval.sup()).to.equal(1);
        expect(interval.infIncluded()).to.beTruthy();
        expect(interval.supIncluded()).to.beTruthy();
      });

      it(@"should return a (0, 1] interval", ^{
        Interval<T> interval = Interval<T>::openZeroToClosedOne();
        expect(interval.inf()).to.equal(0);
        expect(interval.sup()).to.equal(1);
        expect(interval.infIncluded()).to.beFalsy();
        expect(interval.supIncluded()).to.beTruthy();
      });

      it(@"should return an interval with all non-negative numbers", ^{
        Interval<T> interval = Interval<T>::nonNegativeNumbers();
        expect(interval.inf()).to.equal(0);
        expect(interval.sup()).to.equal(std::numeric_limits<T>::max());
        expect(interval.infIncluded()).to.beTruthy();
        expect(interval.supIncluded()).to.beTruthy();
      });

      it(@"should return an interval with all positive numbers", ^{
        Interval<T> interval = Interval<T>::positiveNumbers();
        expect(interval.inf()).to.equal(0);
        expect(interval.sup()).to.equal(std::numeric_limits<T>::max());
        expect(interval.infIncluded()).to.beFalsy();
        expect(interval.supIncluded()).to.beTruthy();
      });
    });

    context(@"hash", ^{
      it(@"should compute a hash of an interval", ^{
        Interval<T> interval({0, 1});
        Interval<T> anotherInterval({0, 1});
        expect(interval.hash()).to.equal(anotherInterval.hash());
      });
    });

    context(@"extrema", ^{
      it(@"should return correct extrema of a closed interval [a, b]", ^{
        Interval<T> interval({0, 1});
        expect(*interval.min()).to.equal(0);
        expect(*interval.max()).to.equal(1);
      });

      it(@"should return empty optional when trying to retrieve minimum of empty interval", ^{
        Interval<T> interval = Interval<T>();
        std::experimental::optional<T> value = interval.min();
        expect(bool(value)).to.beFalsy();
      });

      it(@"should return empty optional when trying to retrieve maximum of empty interval", ^{
        Interval<T> interval = Interval<T>();
        std::experimental::optional<T> value = interval.max();
        expect(bool(value)).to.beFalsy();
      });
    });

    context(@"empty intervals", ^{
      it(@"should indicate that a non-empty interval is not empty", ^{
        Interval<T> interval({0, 1});
        expect(interval.isEmpty()).to.beFalsy();

        interval = Interval<T>({0, 0});
        expect(interval.isEmpty()).to.beFalsy();
      });

      it(@"should indicate that an empty interval is empty", ^{
        Interval<T> interval = Interval<T>::oc({0, 0});
        expect(interval.isEmpty()).to.beTruthy();

        interval = Interval<T>::co({0, 0});
        expect(interval.isEmpty()).to.beTruthy();

        interval = Interval<T>::oo({0, 0});
        expect(interval.isEmpty()).to.beTruthy();
      });
    });

    context(@"value inclusion", ^{
      context(@"open interval", ^{
        it(@"should return correct results for containment queries", ^{
          Interval<T> interval = Interval<T>::oo({1, 3});
          expect(interval.contains(0)).to.beFalsy();
          expect(interval.contains(1)).to.beFalsy();
          expect(interval.contains(2)).to.beTruthy();
          expect(interval.contains(3)).to.beFalsy();
          expect(interval.contains(4)).to.beFalsy();
        });
      });

      context(@"left-open interval", ^{
        it(@"should return correct results for containment queries", ^{
          Interval<T> interval = Interval<T>::oc({1, 3});
          expect(interval.contains(0)).to.beFalsy();
          expect(interval.contains(1)).to.beFalsy();
          expect(interval.contains(2)).to.beTruthy();
          expect(interval.contains(3)).to.beTruthy();
          expect(interval.contains(4)).to.beFalsy();
        });
      });

      context(@"right-open interval", ^{
        it(@"should return correct results for containment queries", ^{
          Interval<T> interval = Interval<T>::co({1, 3});
          expect(interval.contains(0)).to.beFalsy();
          expect(interval.contains(1)).to.beTruthy();
          expect(interval.contains(2)).to.beTruthy();
          expect(interval.contains(3)).to.beFalsy();
          expect(interval.contains(4)).to.beFalsy();
        });
      });

      context(@"closed interval", ^{
        it(@"should return correct results for containment queries", ^{
          Interval<T> interval({1, 3});
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
          Interval<T> interval({0, 1});
          Interval<T> anotherInterval({0, 1});
          expect(interval.intersects(anotherInterval)).to.beTruthy();
        });

        context(@"different boundary conditions", ^{
          it(@"should compute that two intervals with different boundaries intersect", ^{
            Interval<T> interval({0, 1});
            Interval<T> anotherInterval = Interval<T>::co({0, 1});
            expect(interval.intersects(anotherInterval)).to.beTruthy();

            anotherInterval = Interval<T>::oc({0, 1});
            expect(interval.intersects(anotherInterval)).to.beTruthy();
          });
        });

        it(@"should compute that two overlapping intervals intersect", ^{
          Interval<T> interval({1, 3});
          Interval<T> anotherInterval({0, 1});
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = Interval<T>({0, 2.5});
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = Interval<T>::oo({0, 2.5});
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = Interval<T>({0, 3});
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = Interval<T>::oo({0, 3});
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = Interval<T>({2.5, 3});
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = Interval<T>::oo({2.5, 4});
          expect(interval.intersects(anotherInterval)).to.beTruthy();

          anotherInterval = Interval<T>({2, 3});
          expect(interval.intersects(anotherInterval)).to.beTruthy();
        });

        it(@"should compute that two non-overlapping intervals do not intersect", ^{
          Interval<T> interval({2, 3});
          Interval<T> anotherInterval({0, 1});
          expect(interval.intersects(anotherInterval)).to.beFalsy();

          anotherInterval = Interval<T>::co({0, 2});
          expect(interval.intersects(anotherInterval)).to.beFalsy();

          anotherInterval = Interval<T>::oc({3, 4});
          expect(interval.intersects(anotherInterval)).to.beFalsy();

          anotherInterval = Interval<T>({4, 5});
          expect(interval.intersects(anotherInterval)).to.beFalsy();
        });
      });
    });

    context(@"linear interpolation", ^{
      it(@"should return its minimum value for factor of 0", ^{
        Interval<T> interval({1, 2});
        expect(*interval.valueAt(0)).to.equal(1);
      });

      it(@"should return its center for factor of 0.5", ^{
        Interval<T> interval({1, 2});
        expect(*interval.valueAt(0.5)).to.equal(1.5);
      });

      it(@"should return its maximum value for factor of 1", ^{
        Interval<T> interval({1, 2});
        expect(*interval.valueAt(1)).to.equal(2);
      });

      it(@"should return empty optional when trying to interpolate value of empty interval", ^{
        Interval<T> interval = Interval<T>();
        std::experimental::optional<double> value = interval.valueAt(0);
        expect(bool(value)).to.beFalsy();
      });
    });

    context(@"parametric factor for linear interpolation", ^{
      __block Interval<T> interval;

      beforeEach(^{
        interval = Interval<T>({1, 5});
      });

      it(@"should return correct parametric factor for its minimum", ^{
        expect(*interval.parametricValue(*interval.min())).to.equal(0);
      });

      it(@"should return correct parametric factor for the minimum, in case of open interval", ^{
        interval = Interval<T>::oo({1, 5});
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
        interval = Interval<T>::oo({1, 5});
        expect(*interval.parametricValue(*interval.max())).to.beCloseToWithin(1, kEpsilon);
      });

      it(@"should return empty optional when computing parametric factor of degenerate interval", ^{
        Interval<T> interval = Interval<T>({0, 0});
        std::experimental::optional<double> value = interval.parametricValue(0);
        expect(bool(value)).to.beFalsy();
      });

      it(@"should return empty optional when computing parametric factor of empty interval", ^{
        Interval<T> interval = Interval<T>();
        std::experimental::optional<double> value = interval.parametricValue(0);
        expect(bool(value)).to.beFalsy();
      });
    });

    context(@"length", ^{
      it(@"should return correct length of a closed interval", ^{
        Interval<T> interval({0, 1});
        expect(interval.length()).to.equal(1);
      });

      it(@"should return correct length of an empty interval", ^{
        expect(Interval<T>().length()).to.equal(0);
      });
    });

    context(@"clamped value", ^{
      __block Interval<T> interval;

      context(@"closed interval", ^{
        beforeEach(^{
          interval = Interval<T>({1, 3});
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
          interval = Interval<T>::oo({1, 3});
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
        Interval<T> interval = Interval<T>();
        std::experimental::optional<T> value = interval.clamp(0);
        expect(bool(value)).to.beFalsy();
      });
    });

    context(@"description", ^{
      it(@"should return a proper description", ^{
        Interval<T> interval = Interval<T>({1, 2});
        expect(interval.description()).to.equal(@"[1, 2]");
        interval = Interval<T>::oo({2, 3});
        expect(interval.description()).to.equal(@"(2, 3)");
        interval = Interval<T>::oc({3, 4});
        expect(interval.description()).to.equal(@"(3, 4]");
        interval = Interval<T>::co({4, 5});
        expect(interval.description()).to.equal(@"[4, 5)");
      });
    });
  }
};

} // namespace lt

namespace lt {
template <typename T, typename S>
class IntervalCastingSpec {
public:
  static void spec(SPTSpec *self) {
    context(@"casting", ^{
      static T kInf = 1.5;
      static T kSup = 2.75;
      static S kCastInf = kInf;
      static S kCastSup = kSup;

      it(@"should cast an open interval", ^{
        Interval<T> interval = Interval<T>::oo({kInf, kSup});
        Interval<S> castInterval = (Interval<S>)interval;
        expect(castInterval.inf()).to.equal(kCastInf);
        expect(castInterval.sup()).to.equal(kCastSup);
        expect(castInterval.infIncluded()).to.beFalsy();
        expect(castInterval.supIncluded()).to.beFalsy();
      });

      it(@"should cast a left-open interval", ^{
        Interval<T> interval = Interval<T>::oc({kInf, kSup});
        Interval<S> castInterval = (Interval<S>)interval;
        expect(castInterval.inf()).to.equal(kCastInf);
        expect(castInterval.sup()).equal(kCastSup);
        expect(castInterval.infIncluded()).to.beFalsy();
        expect(castInterval.supIncluded()).to.beTruthy();
      });

      it(@"should cast a right-open interval", ^{
        Interval<T> interval = Interval<T>::co({kInf, kSup});
        Interval<S> castInterval = (Interval<S>)interval;
        expect(castInterval.inf()).to.equal(kCastInf);
        expect(castInterval.sup()).equal(kCastSup);
        expect(castInterval.infIncluded()).to.beTruthy();
        expect(castInterval.supIncluded()).to.beFalsy();
      });

      it(@"should cast a closed interval", ^{
        Interval<T> interval = Interval<T>({kInf, kSup});
        Interval<S> castInterval = (Interval<S>)interval;
        expect(castInterval.inf()).to.equal(kCastInf);
        expect(castInterval.sup()).equal(kCastSup);
        expect(castInterval.infIncluded()).to.beTruthy();
        expect(castInterval.supIncluded()).to.beTruthy();
      });
    });
  }
};

} // namespace lt

SpecBegin(LTInterval)

lt::IntervalSpec<CGFloat>::spec(self);
lt::IntervalSpec<NSInteger>::spec(self);
lt::IntervalSpec<NSUInteger>::spec(self);

lt::IntervalCastingSpec<CGFloat, NSInteger>::spec(self);
lt::IntervalCastingSpec<CGFloat, NSUInteger>::spec(self);
lt::IntervalCastingSpec<NSInteger, CGFloat>::spec(self);
lt::IntervalCastingSpec<NSInteger, NSUInteger>::spec(self);
lt::IntervalCastingSpec<NSUInteger, CGFloat>::spec(self);
lt::IntervalCastingSpec<NSUInteger, NSInteger>::spec(self);

context(@"equality", ^{
  it(@"should compare equality to other intervals", ^{
    context(@"CGFloat intervals", ^{
      Interval<CGFloat> interval({0, 1});
      Interval<CGFloat> anotherInterval({0, 1});
      expect(interval == anotherInterval).to.beTruthy();

      anotherInterval = Interval<CGFloat>::oo({0, 1});
      expect(interval == anotherInterval).to.beFalsy();

      anotherInterval = Interval<CGFloat>({0, 2});
      expect(interval == anotherInterval).to.beFalsy();
    });

    context(@"NSInteger intervals", ^{
      Interval<NSInteger> interval({0, 1});
      Interval<NSInteger> anotherInterval({0, 1});
      expect(interval == anotherInterval).to.beTruthy();

      anotherInterval = Interval<NSInteger>::oo({0, 1});
      expect(interval == anotherInterval).to.beFalsy();

      anotherInterval = Interval<NSInteger>({0, 2});
      expect(interval == anotherInterval).to.beFalsy();
    });

    context(@"NSUInteger intervals", ^{
      Interval<NSUInteger> interval({0, 1});
      Interval<NSUInteger> anotherInterval({0, 1});
      expect(interval == anotherInterval).to.beTruthy();

      anotherInterval = Interval<NSUInteger>::oo({0, 1});
      expect(interval == anotherInterval).to.beFalsy();

      anotherInterval = Interval<NSUInteger>({0, 2});
      expect(interval == anotherInterval).to.beFalsy();
    });
  });

  it(@"should compare inequality to other intervals", ^{
    context(@"CGFloat intervals", ^{
      Interval<CGFloat> interval({0, 1});
      Interval<CGFloat> anotherInterval({0, 1});
      expect(interval != anotherInterval).to.beFalsy();

      anotherInterval = Interval<CGFloat>::oo({0, 1});
      expect(interval != anotherInterval).to.beTruthy();

      anotherInterval = Interval<CGFloat>({0, 2});
      expect(interval != anotherInterval).to.beTruthy();
    });

    context(@"NSInteger intervals", ^{
      Interval<NSInteger> interval({0, 1});
      Interval<NSInteger> anotherInterval({0, 1});
      expect(interval != anotherInterval).to.beFalsy();

      anotherInterval = Interval<NSInteger>::oo({0, 1});
      expect(interval != anotherInterval).to.beTruthy();

      anotherInterval = Interval<NSInteger>({0, 2});
      expect(interval != anotherInterval).to.beTruthy();
    });

    context(@"NSUInteger intervals", ^{
      Interval<NSUInteger> interval({0, 1});
      Interval<NSUInteger> anotherInterval({0, 1});
      expect(interval != anotherInterval).to.beFalsy();

      anotherInterval = Interval<NSUInteger>::oo({0, 1});
      expect(interval != anotherInterval).to.beTruthy();

      anotherInterval = Interval<NSUInteger>({0, 2});
      expect(interval != anotherInterval).to.beTruthy();
    });
  });
});

context(@"extrema", ^{
  context(@"CGFloat intervals", ^{
    it(@"should return correct extrema of a left-open interval", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::oc({0, 1});
      expect(*interval.min()).to.equal(std::nextafter((CGFloat)0, (CGFloat)1));
      expect(*interval.max()).to.equal(1);
    });

    it(@"should return correct extrema of a right-open interval", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::co({0, 1});
      expect(*interval.min()).to.equal(0);
      expect(*interval.max()).to.equal(std::nextafter((CGFloat)1, (CGFloat)0));
    });

    it(@"should return correct extrema of an open interval", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::oo({0, 1});
      expect(*interval.min()).to.equal(std::nextafter((CGFloat)0, (CGFloat)1));
      expect(*interval.max()).to.equal(std::nextafter((CGFloat)1, (CGFloat)0));
    });
  });

  context(@"NSInteger intervals", ^{
    it(@"should return correct extrema of a left-open interval", ^{
      Interval<NSInteger> interval = Interval<NSInteger>::oc({-1, 1});
      expect(*interval.min()).to.equal(0);
      expect(*interval.max()).to.equal(1);
    });

    it(@"should return correct extrema of a right-open interval", ^{
      Interval<NSInteger> interval = Interval<NSInteger>::co({-1, 1});
      expect(*interval.min()).to.equal(-1);
      expect(*interval.max()).to.equal(0);
    });

    it(@"should return correct extrema of an open interval", ^{
      Interval<NSInteger> interval = Interval<NSInteger>::oo({-1, 1});
      expect(*interval.min()).to.equal(0);
      expect(*interval.max()).to.equal(0);
    });
  });

  context(@"NSUInteger intervals", ^{
    it(@"should return correct extrema of a left-open interval", ^{
      Interval<NSUInteger> interval = Interval<NSUInteger>::oc({0, 2});
      expect(*interval.min()).to.equal(1);
      expect(*interval.max()).to.equal(2);
    });

    it(@"should return correct extrema of a right-open interval", ^{
      Interval<NSUInteger> interval = Interval<NSUInteger>::co({0, 2});
      expect(*interval.min()).to.equal(0);
      expect(*interval.max()).to.equal(1);
    });

    it(@"should return correct extrema of an open interval", ^{
      Interval<NSUInteger> interval = Interval<NSUInteger>::oo({0, 2});
      expect(*interval.min()).to.equal(1);
      expect(*interval.max()).to.equal(1);
    });
  });
});

context(@"fixed intervals containing negative numbers", ^{
  it(@"should return a [-1, 1] interval", ^{
    Interval<CGFloat> interval = Interval<CGFloat>::minusOneToOne();
    expect(interval.inf()).to.equal(-1);
    expect(interval.sup()).to.equal(1);
    expect(interval.infIncluded()).to.beTruthy();
    expect(interval.supIncluded()).to.beTruthy();
  });
});

context(@"empty intervals", ^{
  it(@"should indicate that an empty CGFloat interval is empty", ^{
    Interval<CGFloat> interval = Interval<CGFloat>::oo({0, std::nextafter((CGFloat)0, (CGFloat)1)});
    expect(interval.isEmpty()).to.beTruthy();
  });

  context(@"edge cases for floating-point intervals", ^{
    it(@"should indicate that an empty CGFloat interval is empty", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::oo({-0.0, +0.0});
      expect(interval.isEmpty()).to.beTruthy();
    });

    it(@"should indicate that an empty left-open CGFloat interval is empty", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::oc({-0.0, +0.0});
      expect(interval.isEmpty()).to.beTruthy();
    });

    it(@"should indicate that an empty right-open CGFloat interval is empty", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::co({-0.0, +0.0});
      expect(interval.isEmpty()).to.beTruthy();
    });

    it(@"should indicate that a non-empty CGFloat interval is not empty", ^{
      Interval<CGFloat> interval({-0.0, +0.0});
      expect(interval.isEmpty()).to.beFalsy();
    });
  });

  it(@"should indicate that an empty NSInteger interval is empty", ^{
    Interval<NSInteger> interval = Interval<NSInteger>::oo({-1, 0});
    expect(interval.isEmpty()).to.beTruthy();
  });

  it(@"should indicate that an empty NSUInteger interval is empty", ^{
    Interval<NSUInteger> interval = Interval<NSUInteger>::oo({0, 1});
    expect(interval.isEmpty()).to.beTruthy();
  });
});

context(@"conversion to closed interval", ^{
  context(@"CGFloat interval", ^{
    it(@"should return the correct closed interval if it is open", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::oo({0, 1}).closed();
      expect(interval == Interval<CGFloat>({std::nextafter((CGFloat)0, (CGFloat)1),
                                            std::nextafter((CGFloat)1, (CGFloat)0)})).to.beTruthy();
    });

    it(@"should return the correct closed interval if it is left-open", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::openZeroToClosedOne().closed();
      expect(interval == Interval<CGFloat>({std::nextafter((CGFloat)0, (CGFloat)1), 1}))
          .to.beTruthy();
    });

    it(@"should return the correct closed interval if it is right-open", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::co({0, 1}).closed();
      expect(interval == Interval<CGFloat>({0, std::nextafter((CGFloat)1, (CGFloat)0)}))
          .to.beTruthy();
    });

    it(@"should return itself if it is closed", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::zeroToOne().closed();
      expect(interval == Interval<CGFloat>::zeroToOne()).to.beTruthy();
    });

    it(@"should return the correct closed interval if it is empty", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::oo({0, 0}).closed();
      expect(interval == Interval<CGFloat>(0)).to.beTruthy();

      interval = Interval<CGFloat>::oo({0, std::nextafter((CGFloat)0, (CGFloat)1)}).closed();
      expect(interval == Interval<CGFloat>(0)).to.beTruthy();
    });
  });

  context(@"NSUInteger interval", ^{
    it(@"should return the correct closed interval if it is open", ^{
      Interval<NSUInteger> interval = Interval<NSUInteger>::oo({0, 3}).closed();
      expect(interval == Interval<NSUInteger>({1, 2})).to.beTruthy();
    });

    it(@"should return the correct closed interval if it is left-open", ^{
      Interval<NSUInteger> interval = Interval<NSUInteger>::oc({0, 3}).closed();
      expect(interval == Interval<NSUInteger>({1, 3})).to.beTruthy();
    });

    it(@"should return the correct closed interval if it is right-open", ^{
      Interval<NSUInteger> interval = Interval<NSUInteger>::co({0, 3}).closed();
      expect(interval == Interval<NSUInteger>({0, 2})).to.beTruthy();
    });

    it(@"should return itself if it is closed", ^{
      Interval<NSUInteger> interval = Interval<NSUInteger>({0, 3}).closed();
      expect(interval == Interval<NSUInteger>({0, 3})).to.beTruthy();
    });

    it(@"should return the correct closed interval if it is empty", ^{
      Interval<NSUInteger> interval = Interval<NSUInteger>::oo({0, 0}).closed();
      expect(interval == Interval<NSUInteger>(0)).to.beTruthy();

      interval = Interval<NSUInteger>::oo({0, 1}).closed();
      expect(interval == Interval<NSUInteger>(0)).to.beTruthy();
    });
  });
});

context(@"value inclusion", ^{
  context(@"open interval", ^{
    it(@"should return correct results for containment queries of a CGFloat interval", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::oo({0.5, 1.5});
      expect(interval.contains(0.5)).to.beFalsy();
      expect(interval.contains(std::nextafter((CGFloat)0.5, (CGFloat)1.5))).to.beTruthy();
      expect(interval.contains(std::nextafter((CGFloat)1.5, (CGFloat)0.5))).to.beTruthy();
      expect(interval.contains(1.5)).to.beFalsy();
    });
  });

  context(@"left-open interval", ^{
    it(@"should return correct results for containment queries of a CGFloat interval", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::oc({0.5, 1.5});
      expect(interval.contains(0.5)).to.beFalsy();
      expect(interval.contains(std::nextafter((CGFloat)0.5, (CGFloat)1.5))).to.beTruthy();
      expect(interval.contains(std::nextafter((CGFloat)1.5, (CGFloat)0.5))).to.beTruthy();
      expect(interval.contains(1.5)).to.beTruthy();
    });
  });

  context(@"right-open interval", ^{
    it(@"should return correct results for containment queries of a CGFloat interval", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::co({0.5, 1.5});
      expect(interval.contains(0.5)).to.beTruthy();
      expect(interval.contains(std::nextafter((CGFloat)0.5, (CGFloat)1.5))).to.beTruthy();
      expect(interval.contains(std::nextafter((CGFloat)1.5, (CGFloat)0.5))).to.beTruthy();
      expect(interval.contains(1.5)).to.beFalsy();
    });
  });

  context(@"closed interval", ^{
    it(@"should return correct results for containment queries of a CGFloat interval", ^{
      Interval<CGFloat> interval({0.5, 1.5});
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
        Interval<CGFloat> interval({0, 1});
        Interval<CGFloat> anotherInterval = Interval<CGFloat>::oo({0, 1});
        expect(interval.intersects(anotherInterval)).to.beTruthy();
      });

      it(@"should compute that two NSInteger intervals with different boundaries intersect", ^{
        Interval<NSInteger> interval({0, 1});
        Interval<NSInteger> anotherInterval = Interval<NSInteger>::oo({0, 2});
        expect(interval.intersects(anotherInterval)).to.beTruthy();
      });

      it(@"should compute that two NSUInteger intervals with different boundaries intersect", ^{
        Interval<NSUInteger> interval({0, 1});
        Interval<NSUInteger> anotherInterval = Interval<NSUInteger>::oo({0, 2});
        expect(interval.intersects(anotherInterval)).to.beTruthy();
      });
    });
  });

  context(@"intersection computation", ^{
    context(@"CGFloat interval", ^{
      it(@"should compute the intersection of two equal intervals", ^{
        Interval<CGFloat> interval({0, 1});
        Interval<CGFloat> anotherInterval({0, 1});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();
      });

      it(@"should compute how two equal intervals with different boundary conditions intersect", ^{
        Interval<CGFloat> interval({0, 1});
        Interval<CGFloat> anotherInterval = Interval<CGFloat>::co({0, 1});
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = Interval<CGFloat>::oc({0, 1});
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = Interval<CGFloat>::oo({0, 1});
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();
      });

      it(@"should compute that two overlapping intervals intersect", ^{
        Interval<CGFloat> interval({0, 1});
        Interval<CGFloat> anotherInterval({-1, 0});
        expect(interval.intersectionWith(anotherInterval) ==
               Interval<CGFloat>({0, 0})).to.beTruthy();

        anotherInterval = Interval<CGFloat>({-1, 0.5});
        expect(interval.intersectionWith(anotherInterval) ==
               Interval<CGFloat>({0, 0.5})).to.beTruthy();

        anotherInterval = Interval<CGFloat>::oo({-1, 0.5});
        expect(interval.intersectionWith(anotherInterval) == Interval<CGFloat>::co({0, 0.5}))
            .to.beTruthy();

        anotherInterval = Interval<CGFloat>({-1, 2});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();

        anotherInterval = Interval<CGFloat>::oo({-1, 2});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();

        anotherInterval = Interval<CGFloat>({0.5, 2});
        expect(interval.intersectionWith(anotherInterval) ==
               Interval<CGFloat>({0.5, 1})).to.beTruthy();

        anotherInterval = Interval<CGFloat>::oo({0.5, 2});
        expect(interval.intersectionWith(anotherInterval) == Interval<CGFloat>::oc({0.5, 1}))
            .to.beTruthy();

        anotherInterval = Interval<CGFloat>({1, 2});
        expect(interval.intersectionWith(anotherInterval) == Interval<CGFloat>({1, 1}))
            .to.beTruthy();
      });

      it(@"should compute that two non-overlapping intervals do not intersect", ^{
        Interval<CGFloat> interval({0, 1});
        Interval<CGFloat> anotherInterval({-2, -1});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = Interval<CGFloat>::co({-1, 0});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = Interval<CGFloat>::oc({1, 2});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = Interval<CGFloat>({2, 3});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();
      });
    });

    context(@"NSInteger interval", ^{
      it(@"should compute the intersection of two equal intervals", ^{
        Interval<NSInteger> interval({0, 1});
        Interval<NSInteger> anotherInterval({0, 1});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();
      });

      it(@"should compute how two equal intervals with different boundary conditions intersect", ^{
        Interval<NSInteger> interval({0, 1});
        Interval<NSInteger> anotherInterval = Interval<NSInteger>::co({0, 1});
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = Interval<NSInteger>::oc({0, 1});
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = Interval<NSInteger>::oo({0, 1});
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();
      });

      it(@"should compute that two overlapping intervals intersect", ^{
        Interval<NSInteger> interval({0, 1});
        Interval<NSInteger> anotherInterval({-1, 0});
        expect(interval.intersectionWith(anotherInterval) ==
               Interval<NSInteger>({0, 0})).to.beTruthy();

        anotherInterval = Interval<NSInteger>({-1, 1});
        expect(interval.intersectionWith(anotherInterval) ==
               Interval<NSInteger>({0, 1})).to.beTruthy();

        anotherInterval = Interval<NSInteger>::oo({-1, 1});
        expect(interval.intersectionWith(anotherInterval) == Interval<NSInteger>::co({0, 1}))
            .to.beTruthy();

        anotherInterval = Interval<NSInteger>({-1, 2});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();

        anotherInterval = Interval<NSInteger>::oo({-1, 2});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();

        anotherInterval = Interval<NSInteger>({1, 2});
        expect(interval.intersectionWith(anotherInterval) ==
               Interval<NSInteger>({1, 1})).to.beTruthy();

        anotherInterval = Interval<NSInteger>::co({1, 2});
        expect(interval.intersectionWith(anotherInterval) ==
               Interval<NSInteger>({1, 1})).to.beTruthy();

        anotherInterval = Interval<NSInteger>({1, 2});
        expect(interval.intersectionWith(anotherInterval) ==
               Interval<NSInteger>({1, 1})).to.beTruthy();
      });

      it(@"should compute that two non-overlapping intervals do not intersect", ^{
        Interval<NSInteger> interval({0, 1});
        Interval<NSInteger> anotherInterval({-2, -1});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = Interval<NSInteger>::co({-1, 0});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = Interval<NSInteger>::oc({1, 2});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = Interval<NSInteger>({2, 3});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();
      });
    });

    context(@"NSUInteger interval", ^{
      it(@"should compute the intersection of two equal intervals", ^{
        Interval<NSInteger> interval({0, 1});
        Interval<NSInteger> anotherInterval({0, 1});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();
      });

      it(@"should compute how two equal intervals with different boundary conditions intersect", ^{
        Interval<NSInteger> interval({0, 1});
        Interval<NSInteger> anotherInterval = Interval<NSInteger>::co({0, 1});
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = Interval<NSInteger>::oc({0, 1});
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = Interval<NSInteger>::oo({0, 1});
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();
      });

      it(@"should compute that two overlapping intervals intersect", ^{
        Interval<NSInteger> interval({0, 1});
        Interval<NSInteger> anotherInterval({0, 0});
        expect(interval.intersectionWith(anotherInterval) == Interval<NSInteger>({0, 0}))
            .to.beTruthy();

        anotherInterval = Interval<NSInteger>({0, 1});
        expect(interval.intersectionWith(anotherInterval) == Interval<NSInteger>({0, 1}))
            .to.beTruthy();

        anotherInterval = Interval<NSInteger>::oo({0, 1});
        expect(interval.intersectionWith(anotherInterval) == anotherInterval).to.beTruthy();

        anotherInterval = Interval<NSInteger>({0, 2});
        expect(interval.intersectionWith(anotherInterval) == interval).to.beTruthy();

        anotherInterval = Interval<NSInteger>::oo({0, 2});
        expect(interval.intersectionWith(anotherInterval) == Interval<NSInteger>::oc({0, 1}))
            .to.beTruthy();

        anotherInterval = Interval<NSInteger>::oc({0, 2});
        expect(interval.intersectionWith(anotherInterval) == Interval<NSInteger>::oc({0, 1}))
            .to.beTruthy();

        anotherInterval = Interval<NSInteger>::co({0, 2});
        expect(interval.intersectionWith(anotherInterval) == Interval<NSInteger>({0, 1}))
            .to.beTruthy();

        anotherInterval = Interval<NSInteger>({1, 2});
        expect(interval.intersectionWith(anotherInterval) == Interval<NSInteger>({1, 1}))
            .to.beTruthy();
      });

      it(@"should compute that two non-overlapping intervals do not intersect", ^{
        Interval<NSInteger> interval({0, 1});
        Interval<NSInteger> anotherInterval = Interval<NSInteger>::oc({0, 0});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = Interval<NSInteger>::co({0, 0});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = Interval<NSInteger>::oc({1, 2});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();

        anotherInterval = Interval<NSInteger>({2, 3});
        expect(interval.intersectionWith(anotherInterval).isEmpty()).to.beTruthy();
      });
    });
  });
});

context(@"linear interpolation", ^{
  it(@"should return its minimum value for factor of 0, in case of open CGFloat interval", ^{
    Interval<CGFloat> interval = Interval<CGFloat>::oo({-1, 2});
    expect(*interval.valueAt(0)).to.equal(std::nextafter((CGFloat)-1, (CGFloat)2));
  });

  it(@"should return its minimum value for factor of 0, in case of open NSInteger interval", ^{
    Interval<NSInteger> interval = Interval<NSInteger>::oo({-1, 1});
    expect(*interval.valueAt(0)).to.equal(0);
  });

  it(@"should return its minimum value for factor of 0, in case of open NSUInteger interval", ^{
    Interval<NSUInteger> interval = Interval<NSUInteger>::oo({0, 2});
    expect(*interval.valueAt(0)).to.equal(1);
  });

  it(@"should return its maximum value for factor of 1, in case of open CGFloat interval", ^{
    Interval<CGFloat> interval = Interval<CGFloat>::oo({-1, 2});
    expect(*interval.valueAt(1)).to.equal(std::nextafter((CGFloat)2, (CGFloat)-1));
  });

  it(@"should return its maximum value for factor of 1, in case of open NSInteger interval", ^{
    Interval<NSInteger> interval = Interval<NSInteger>::oo({-1, 1});
    expect(*interval.valueAt(1)).to.equal(0);
  });

  it(@"should return its maximum value for factor of 1, in case of open NSUInteger interval", ^{
    Interval<NSUInteger> interval = Interval<NSUInteger>::oo({0, 2});
    expect(*interval.valueAt(1)).to.equal(1);
  });
});

context(@"length", ^{
  context(@"CGFloat interval", ^{
    it(@"should return correct length of a left-open interval", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::oc({0, 1});
      expect(interval.length()).to.equal(1 - std::nextafter((CGFloat)0, (CGFloat)1));
    });

    it(@"should return correct length of a right-open interval", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::co({0, 1});
      expect(interval.length()).to.equal(std::nextafter((CGFloat)1, (CGFloat)0));
    });

    it(@"should return correct length of an open interval", ^{
      Interval<CGFloat> interval = Interval<CGFloat>::oo({0, 1});
      expect(interval.length()).to.equal(std::nextafter((CGFloat)1, (CGFloat)0) -
                                         std::nextafter((CGFloat)0, (CGFloat)1));
    });
  });

  context(@"NSInteger interval", ^{
    it(@"should return correct length of a left-open interval", ^{
      Interval<NSInteger> interval = Interval<NSInteger>::oc({-2, 2});
      expect(interval.length()).to.equal(3);
    });

    it(@"should return correct length of a right-open interval", ^{
      Interval<NSInteger> interval = Interval<NSInteger>::co({-2, 2});
      expect(interval.length()).to.equal(3);
    });

    it(@"should return correct length of an open interval", ^{
      Interval<NSInteger> interval = Interval<NSInteger>::oo({-2, 2});
      expect(interval.length()).to.equal(2);
    });
  });

  context(@"NSUInteger interval", ^{
    it(@"should return correct length of a left-open interval", ^{
      Interval<NSUInteger> interval = Interval<NSUInteger>::oc({0, 4});
      expect(interval.length()).to.equal(3);
    });

    it(@"should return correct length of a right-open interval", ^{
      Interval<NSUInteger> interval = Interval<NSUInteger>::co({0, 4});
      expect(interval.length()).to.equal(3);
    });

    it(@"should return correct length of an open interval", ^{
      Interval<NSUInteger> interval = Interval<NSUInteger>::oo({0, 4});
      expect(interval.length()).to.equal(2);
    });
  });
});

context(@"clamped interval", ^{
  __block Interval<CGFloat> interval;

  context(@"clamping by empty interval", ^{
    it(@"should return empty optional", ^{
      expect(bool(Interval<CGFloat>(0).clampedTo(Interval<CGFloat>()))).to.beFalsy();
    });
  });

  context(@"open CGFloat interval", ^{
    beforeEach(^{
      interval = Interval<CGFloat>::oo({1.5, 2.5});
    });

    it(@"should return minimum if values of clamped interval are smaller than other interval", ^{
      expect(*Interval<CGFloat>({0, 1.5}).clampedTo(interval) == Interval<CGFloat>(*interval.min()))
          .to.beTruthy();
    });

    it(@"should return intersection if not empty", ^{
      expect(*Interval<CGFloat>({0, *interval.min()}).clampedTo(interval) ==
             Interval<CGFloat>::oc({1.5, *interval.min()})).to.beTruthy();
      expect(*Interval<CGFloat>({0, 2}).clampedTo(interval) == Interval<CGFloat>::oc({1.5, 2}))
          .to.beTruthy();
      expect(*Interval<CGFloat>({0, 3}).clampedTo(interval) == interval).to.beTruthy();
      expect(*interval.clampedTo(interval) == interval).to.beTruthy();
      expect(*Interval<CGFloat>({2, 3}).clampedTo(interval) == Interval<CGFloat>::co({2, 2.5}))
          .to.beTruthy();
      expect(*Interval<CGFloat>({*interval.max(), 3}).clampedTo(interval) ==
             Interval<CGFloat>::co({*interval.max(), 2.5})).to.beTruthy();
    });

    it(@"should return maximum if values of clamped interval are greater than other interval", ^{
      expect(*Interval<CGFloat>({2.5, 3}).clampedTo(interval) == Interval<CGFloat>(*interval.max()))
          .to.beTruthy();
    });
  });

  context(@"left-open CGFloat interval", ^{
    beforeEach(^{
      interval = Interval<CGFloat>::oc({1.5, 2.5});
    });

    it(@"should return minimum if values of clamped interval are smaller than other interval", ^{
      expect(*Interval<CGFloat>({0, 1.5}).clampedTo(interval) == Interval<CGFloat>(*interval.min()))
          .to.beTruthy();
    });

    it(@"should return intersection if not empty", ^{
      expect(*Interval<CGFloat>({0, *interval.min()}).clampedTo(interval) ==
             Interval<CGFloat>::oc({1.5, *interval.min()})).to.beTruthy();
      expect(*Interval<CGFloat>({0, 2}).clampedTo(interval) ==
             Interval<CGFloat>::oc({1.5, 2})).to.beTruthy();
      expect(*Interval<CGFloat>({0, 3}).clampedTo(interval) == interval).to.beTruthy();
      expect(*interval.clampedTo(interval) == interval).to.beTruthy();
      expect(*Interval<CGFloat>({2, 3}).clampedTo(interval) ==
             Interval<CGFloat>({2, 2.5})).to.beTruthy();
      expect(*Interval<CGFloat>({*interval.max(), 3}).clampedTo(interval) ==
             Interval<CGFloat>({*interval.max(), 2.5})).to.beTruthy();
    });

    it(@"should return maximum if values of clamped interval are greater than other interval", ^{
      expect(*Interval<CGFloat>({2.5, 3}).clampedTo(interval) == Interval<CGFloat>(*interval.max()))
          .to.beTruthy();
    });
  });

  context(@"right-open CGFloat interval", ^{
    beforeEach(^{
      interval = Interval<CGFloat>::co({1.5, 2.5});
    });

    it(@"should return minimum if values of clamped interval are smaller than other interval", ^{
      expect(*Interval<CGFloat>::oo({0, 1.5}).clampedTo(interval) ==
             Interval<CGFloat>(*interval.min())).to.beTruthy();
    });

    it(@"should return intersection if not empty", ^{
      expect(*Interval<CGFloat>({0, *interval.min()}).clampedTo(interval) ==
             Interval<CGFloat>({1.5, *interval.min()})).to.beTruthy();
      expect(*Interval<CGFloat>({0, 2}).clampedTo(interval) == Interval<CGFloat>({1.5, 2}))
          .to.beTruthy();
      expect(*Interval<CGFloat>({0, 3}).clampedTo(interval) == interval).to.beTruthy();
      expect(*interval.clampedTo(interval) == interval).to.beTruthy();
      expect(*Interval<CGFloat>({2, 3}).clampedTo(interval) ==
             Interval<CGFloat>::co({2, 2.5})).to.beTruthy();
      expect(*Interval<CGFloat>({*interval.max(), 3}).clampedTo(interval) ==
             Interval<CGFloat>::co({*interval.max(), 2.5})).to.beTruthy();
    });

    it(@"should return maximum if values of clamped interval are greater than other interval", ^{
      expect(*Interval<CGFloat>({2.5, 3}).clampedTo(interval) == Interval<CGFloat>(*interval.max()))
          .to.beTruthy();
    });
  });

  context(@"closed CGFloat interval", ^{
    beforeEach(^{
      interval = Interval<CGFloat>({1.5, 2.5});
    });

    it(@"should return minimum if values of clamped interval are smaller than other interval", ^{
      expect(*Interval<CGFloat>::oo({0, 1.5}).clampedTo(interval) ==
             Interval<CGFloat>(*interval.min())).to.beTruthy();
    });

    it(@"should return intersection if not empty", ^{
      expect(*Interval<CGFloat>({0, *interval.min()}).clampedTo(interval) ==
             Interval<CGFloat>({1.5, *interval.min()})).to.beTruthy();
      expect(*Interval<CGFloat>({0, 2}).clampedTo(interval) == Interval<CGFloat>({1.5, 2}))
          .to.beTruthy();
      expect(*Interval<CGFloat>({0, 3}).clampedTo(interval) == interval).to.beTruthy();
      expect(*interval.clampedTo(interval) == interval).to.beTruthy();
      expect(*Interval<CGFloat>({2, 3}).clampedTo(interval) == Interval<CGFloat>({2, 2.5}))
          .to.beTruthy();
      expect(*Interval<CGFloat>({*interval.max(), 3}).clampedTo(interval) ==
             Interval<CGFloat>({*interval.max(), 2.5})).to.beTruthy();
    });

    it(@"should return maximum if values of clamped interval are greater than other interval", ^{
      expect(*Interval<CGFloat>::oo({2.5, 3}).clampedTo(interval) ==
             Interval<CGFloat>(*interval.max())).to.beTruthy();
    });
  });
});

context(@"description", ^{
  it(@"should return a proper description of a CGFloat interval", ^{
    Interval<CGFloat> interval({0.5, 2});
    expect(interval.description()).to.equal(@"[0.5, 2]");
  });

  it(@"should return a proper description of a CGFloat interval with non-trivial values", ^{
    Interval<CGFloat> interval({1.234567, 2});
    expect(interval.description()).to.equal(@"[1.234567, 2]");
  });

  it(@"should return a proper description of an NSInteger interval", ^{
    Interval<NSInteger> interval({-1, 2});
    expect(interval.description()).to.equal(@"[-1, 2]");
  });

  it(@"should return a proper description of an NSUInteger interval", ^{
    Interval<NSUInteger> interval({0, 2});
    expect(interval.description()).to.equal(@"[0, 2]");
  });
});

context(@"mathematical operators", ^{
  it(@"should multiply with a numeric value on the left-hand side", ^{
    expect(2 * Interval<NSUInteger>::oc({2, 4}) == Interval<NSUInteger>::oc({4, 8})).to.beTruthy();
    expect(2 * Interval<CGFloat>::co({2, 4}) == Interval<CGFloat>::co({4, 8})).to.beTruthy();
    expect(0.5 * Interval<NSUInteger>::oo({2, 4}) == Interval<NSUInteger>::oo({1, 2}))
        .to.beTruthy();
    expect(0.5 * Interval<CGFloat>({2, 4}) == Interval<CGFloat>({1, 2})).to.beTruthy();
  });

  it(@"should multiply with a numeric value on the right-hand side", ^{
    expect(Interval<NSUInteger>::oc({2, 4}) * 2 == Interval<NSUInteger>::oc({4, 8})).to.beTruthy();
    expect(Interval<CGFloat>::co({2, 4}) * 2 == Interval<CGFloat>::co({4, 8})).to.beTruthy();
    expect(Interval<NSUInteger>::oo({2, 4}) * 0.5 == Interval<NSUInteger>::oo({1, 2}))
        .to.beTruthy();
    expect(Interval<CGFloat>({2, 4}) * 0.5 == Interval<CGFloat>({1, 2})).to.beTruthy();
  });

  it(@"should divide by a numeric value", ^{
    expect(Interval<NSUInteger>::oc({2, 4}) / 2 == Interval<NSUInteger>::oc({1, 2})).to.beTruthy();
    expect(Interval<CGFloat>::co({2, 4}) / 2 == Interval<CGFloat>::co({1, 2})).to.beTruthy();
    expect(Interval<NSUInteger>::oo({2, 4}) / 0.5 == Interval<NSUInteger>::oo({4, 8}))
    .to.beTruthy();
    expect(Interval<CGFloat>({2, 4}) / 0.5 == Interval<CGFloat>({4, 8})).to.beTruthy();
  });
});

context(@"interval from string", ^{
  context(@"CGFloat intervals", ^{
    it(@"should return correct open CGFloat interval for a given string", ^{
      Interval<CGFloat> interval = LTCGFloatIntervalFromString(@"(-0.25, 1.25)");
      expect(interval == Interval<CGFloat>::oo({-0.25, 1.25})).to.beTruthy();
    });

    it(@"should return correct left-open CGFloat interval for a given string", ^{
      Interval<CGFloat> interval = LTCGFloatIntervalFromString(@"(-0.5, 1.5]");
      expect(interval == Interval<CGFloat>::oc({-0.5, 1.5})).to.beTruthy();
    });

    it(@"should return correct right-open CGFloat interval for a given string", ^{
      Interval<CGFloat> interval = LTCGFloatIntervalFromString(@"[-0.75, 1.75)");
      expect(interval == Interval<CGFloat>::co({-0.75, 1.75})).to.beTruthy();
    });

    it(@"should return correct closed CGFloat interval for a given string", ^{
      Interval<CGFloat> interval = LTCGFloatIntervalFromString(@"[-1.0, 2.0]");
      expect(interval == Interval<CGFloat>({-1, 2})).to.beTruthy();
    });

    context(@"string with invalid format", ^{
      it(@"should return empty CGFloat intervals for given strings with invalid formats", ^{
        Interval<CGFloat> interval = LTCGFloatIntervalFromString(@"(-0.25)");
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
      Interval<NSInteger> interval = LTNSIntegerIntervalFromString(@"(-7, 8)");
      expect(interval == Interval<NSInteger>::oo({-7, 8})).to.beTruthy();
    });

    it(@"should return correct left-open NSInteger interval for a given string", ^{
      Interval<NSInteger> interval = LTNSIntegerIntervalFromString(@"(-6, 7]");
      expect(interval == Interval<NSInteger>::oc({-6, 7})).to.beTruthy();
    });

    it(@"should return correct right-open NSInteger interval for a given string", ^{
      Interval<NSInteger> interval = LTNSIntegerIntervalFromString(@"[-5, 6)");
      expect(interval == Interval<NSInteger>::co({-5, 6})).to.beTruthy();
    });

    it(@"should return correct closed NSInteger interval for a given string", ^{
      Interval<NSInteger> interval = LTNSIntegerIntervalFromString(@"[-4, 5]");
      expect(interval == Interval<NSInteger>({-4, 5})).to.beTruthy();
    });

    context(@"string with invalid format", ^{
      it(@"should return empty NSInteger intervals for given strings with invalid formats", ^{
        Interval<NSInteger> interval = LTNSIntegerIntervalFromString(@"(-4)");
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
      Interval<NSUInteger> interval = LTNSUIntegerIntervalFromString(@"(7, 8)");
      expect(interval == Interval<NSUInteger>::oo({7, 8})).to.beTruthy();
    });

    it(@"should return correct left-open NSUInteger interval for a given string", ^{
      Interval<NSUInteger> interval = LTNSUIntegerIntervalFromString(@"(6, 7]");
      expect(interval == Interval<NSUInteger>::oc({6, 7})).to.beTruthy();
    });

    it(@"should return correct right-open NSUInteger interval for a given string", ^{
      Interval<NSUInteger> interval = LTNSUIntegerIntervalFromString(@"[5, 6)");
      expect(interval == Interval<NSUInteger>::co({5, 6})).to.beTruthy();
    });

    it(@"should return correct closed NSUInteger interval for a given string", ^{
      Interval<NSUInteger> interval = LTNSUIntegerIntervalFromString(@"[4, 5]");
      expect(interval == Interval<NSUInteger>({4, 5})).to.beTruthy();
    });

    context(@"string with invalid format", ^{
      it(@"should return empty NSInteger intervals for given strings with invalid formats", ^{
        Interval<NSInteger> interval = LTNSIntegerIntervalFromString(@"(4)");
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
