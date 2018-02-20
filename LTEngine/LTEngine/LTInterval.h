// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <experimental/optional>

namespace lt {

/// Struct representing a primitive scalar interval from a value \c a to a value \c b. The interval
/// can be open, half-closed, or closed. The template parameter \c T must be of a primitive scalar
/// type.
template <typename T>
class Interval {
  static_assert(std::is_integral<T>::value || std::is_floating_point<T>::value,
                "Interval class is only available for primitive scalar types");

public:
  /// Types of end point inclusion indicating whether an end point of the interval is included.
  enum EndpointInclusion {
    /// Indicates that the end point is not included in the interval.
    Open,
    /// Indicates that the end point is included in the interval.
    Closed
  };

  /// Returns an empty interval.
  Interval() noexcept : _inf(0), _sup(0), _infInclusion(Open), _supInclusion(Open) {}

  /// Initializes with the given \c values, the \c infInclusion indicating whether the infimum of
  /// the interval is included, and the \c supInclusion indicating whether the supremum of the
  /// interval is included.
  Interval(std::pair<T, T> values, EndpointInclusion infInclusion,
           EndpointInclusion supInclusion) noexcept :
      _inf(std::min(values.first, values.second)), _sup(std::max(values.first, values.second)),
      _infInclusion(infInclusion), _supInclusion(supInclusion) {}

  /// Initializes with the given \c values and the \c endpointInclusion indicating whether the end
  /// points of the interval are included.
  Interval(std::pair<T, T> values, EndpointInclusion endpointInclusion) noexcept :
      _inf(std::min(values.first, values.second)), _sup(std::max(values.first, values.second)),
      _infInclusion(endpointInclusion), _supInclusion(endpointInclusion) {}

  /// Initializes with the given \c values and closed end points.
  Interval(std::pair<T, T> values) noexcept :
      _inf(std::min(values.first, values.second)), _sup(std::max(values.first, values.second)),
      _infInclusion(Closed), _supInclusion(Closed) {}

  /// Initializes with the given \c value as single interval value and closed end points.
  Interval(T value) noexcept :
      _inf(value), _sup(value), _infInclusion(Closed), _supInclusion(Closed) {}

  /// Return a hash value for this interval.
  size_t hash() const {
    return std::hash<T>()(_inf) ^ std::hash<T>()(_sup) ^
        std::hash<T>()(_infInclusion) ^ std::hash<T>()(_supInclusion);
  }

  /// Returns \c true if this interval is empty.
  bool isEmpty() const {
    if (_inf == _sup) {
      return !infIncluded() || !supIncluded();
    } else if (!infIncluded() && !supIncluded()) {
      return std::is_integral<T>::value ? _inf + 1 == _sup : std::nextafter(_inf, _sup) == _sup;
    }
    return false;
  }

  /// Returns \c true if this interval contains the given \c value.
  bool contains(T value) const {
    return (infIncluded() ? value >= _inf : value > _inf) &&
        (supIncluded() ? value <= _sup : value < _sup);
  }

  /// Returns \c true if this interval intersects with the given \c interval.
  bool intersects(lt::Interval<T> interval) const {
    return !intersectionWith(interval).isEmpty();
  }

  /// Returns a new interval constituting the intersection between this interval and the given
  /// \c interval.
  lt::Interval<T> intersectionWith(lt::Interval<T> interval) const {
    T inf = std::max(_inf, interval._inf);
    T sup = std::min(_sup, interval._sup);

    if (inf > sup) {
      return Interval();
    }

    EndpointInclusion infInclusion = contains(inf) && interval.contains(inf) ? Closed : Open;
    EndpointInclusion supInclusion = contains(sup) && interval.contains(sup) ? Closed : Open;
    return Interval({inf, sup}, infInclusion, supInclusion);
  }

  /// Returns the infimum of this interval.
  T inf() const {
    return _inf;
  };

  /// Returns the supremum of this interval.
  T sup() const {
    return _sup;
  }

  /// Returns the minimum value of this interval. Note that the minimum value equals the value
  /// returned by the \c inf() method iff the interval is closed w.r.t the infimum. If this interval
  /// is empty, an empty optional is returned.
  std::experimental::optional<T> min() const {
    if (isEmpty()) {
      return std::experimental::nullopt;
    }
    if (infIncluded()) {
      return _inf;
    }
    // Note that no overflow is possible since _inf is guaranteed to be smaller than _sup for a
    // non-empty interval.
    return std::is_integral<T>::value ? _inf + 1 : std::nextafter(_inf, _sup);
  };

  /// Returns the maximum value of this interval. Note that the maximum value equals the value
  /// returned by the \c sup() method iff the interval is closed w.r.t the supremum. If this
  /// interval is empty, an empty optional is returned.
  std::experimental::optional<T> max() const {
    if (isEmpty()) {
      return std::experimental::nullopt;
    }
    if (supIncluded()) {
      return _sup;
    }
    // Note that no overflow is possible since _sup is guaranteed to be greater than _inf for a
    // non-empty interval.
    return std::is_integral<T>::value ? _sup - 1 : std::nextafter(_sup, _inf);
  }

  /// Returns the linearly interpolated value for parametric value \c t. In particular, the minimum
  /// of this interval is returned for \c t equalling \c 0 and the maximum of this interval is
  /// returned for \c t equalling \c 1. If this interval is empty, an empty optional is returned.
  std::experimental::optional<double> valueAt(double t) const {
    if (isEmpty()) {
      return std::experimental::nullopt;
    }
    // No overflow possible since non-empty intervals always allow incrementing (/decrementing) of
    // their infimum (/supremum) by a single step.
    return (1 - t) * *min() + t * *max();
  }

  /// Returns the parametric value for the given value \c x, i.e. the value \c t s.t.
  /// <tt>valueAt(t)</tt> equals \c x (up to deviations caused by numeric imprecisions). If this
  /// interval is empty or the interval contains only a single value, an empty optional is returned.
  std::experimental::optional<double> parametricValue(T x) const {
    if (isEmpty()) {
      return std::experimental::nullopt;
    }
    CGFloat minimum = *min();
    CGFloat maximum = *max();
    if (minimum == maximum) {
      return std::experimental::nullopt;
    } else {
      return ((double)x - minimum) / (maximum - minimum);
    }
  }

  /// Returns the length of this interval.
  T length() const {
    return isEmpty() ? 0 : *max() - *min();
  }

  /// Returns the given value \c x clamped to this interval, i.e. the returned value is \c x if this
  /// interval contains \c x, and the value contained by this interval closest to \c x, otherwise.
  /// If this interval is empty, an empty optional is returned.
  std::experimental::optional<T> clamp(T x) const {
    if (isEmpty()) {
      return std::experimental::nullopt;
    }
    if (contains(x)) {
      return x;
    }
    CGFloat minimum = *min();
    return x < minimum ? minimum : *max();
  }

  /// Returns \c true if the infimum of this interval belongs to the interval.
  bool infIncluded() const {
    return _infInclusion == Closed;
  }

  /// Returns \c true if the supremum of this interval belongs to the interval.
  bool supIncluded() const {
    return _supInclusion == Closed;
  }

  /// Returns a string representation of this interval.
  NSString *description() const {
    std::stringstream stream;
    stream.precision((std::numeric_limits<T>::digits10 + 1));
    stream << (infIncluded() ? "[" : "(");
    stream << _inf;
    stream << ", ";
    stream << _sup;
    stream << (supIncluded() ? "]" : ")");
    return [NSString stringWithUTF8String:stream.str().c_str()];
  }

  /// Casts this interval to the interval with the given type \c S.
  template <typename S>
  explicit operator lt::Interval<S>() const {
    return lt::Interval<S>({_inf, _sup},
                           _infInclusion == Closed ?
                               lt::Interval<S>::Closed : lt::Interval<S>::Open,
                           _supInclusion == Closed ?
                               lt::Interval<S>::Closed : lt::Interval<S>::Open);
  }

private:
  /// Infimum of this interval.
  T _inf;
  /// Supremum of this interval.
  T _sup;
  /// \c true if the infimum of this interval belongs to the interval.
  EndpointInclusion _infInclusion;
  /// \c true if the supremum of this interval belongs to the interval.
  EndpointInclusion _supInclusion;
};

} // namespace lt

template <typename T>
constexpr bool operator==(lt::Interval<T> lhs, lt::Interval<T> rhs) {
  return lhs.inf() == rhs.inf() && lhs.sup() == rhs.sup() &&
      lhs.infIncluded() == rhs.infIncluded() && lhs.supIncluded()== rhs.supIncluded();
}

template <typename T>
constexpr bool operator!=(lt::Interval<T> lhs, lt::Interval<T> rhs) {
  return !(lhs == rhs);
}

/// Returns a \c CGFloat interval for the given \c string. The \c string is assumed to be in the
/// format <tt>@"(%g, %g)"</tt> for an open interval, <tt>@"(%g, %g]"</tt> for a left-open interval,
/// <tt>@"[%g, %g)"</tt> for a right-open interval, and <tt>@"[%g, %g]"</tt> for a closed interval.
/// In case an invalid format is given, \c lt::Interval<CGFloat>() is returned.
lt::Interval<CGFloat> LTCGFloatIntervalFromString(NSString *string);

/// Returns an \c NSInteger interval for the given \c string. The \c string is assumed to be in the
/// format <tt>@"(%ld, %ld)"</tt> for an open interval, <tt>@"(%ld, %ld]"</tt> for a left-open
/// interval, <tt>@"[%ld, %ld)"</tt> for a right-open interval, and <tt>@"[%ld, %ld]"</tt> for a
/// closed interval. In case an invalid format is given, \c lt::Interval<CGFloat>() is returned.
lt::Interval<NSInteger> LTNSIntegerIntervalFromString(NSString *string);

/// Returns an \c NSUInteger interval for the given \c string. The \c string is assumed to be in the
/// format <tt>@"(%lu, %lu)"</tt> for an open interval, <tt>@"(%lu, %lu]"</tt> for a left-open
/// interval, <tt>@"[%lu, %lu)"</tt> for a right-open interval, and <tt>@"[%lu, %lu]"</tt> for a
/// closed interval. In case an invalid format is given, \c lt::Interval<CGFloat>() is returned.
lt::Interval<NSUInteger> LTNSUIntegerIntervalFromString(NSString *string);
