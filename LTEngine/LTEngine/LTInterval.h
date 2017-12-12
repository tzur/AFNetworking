// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

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

  /// Returns the linearly interpolated value for parametric value \c t. In particular, the minimum
  /// of this interval is returned for \c t equalling \c 0 and the maximum of this interval is
  /// returned for \c t equalling \c 1. If this interval is empty, an assertion is raised.
  double valueAt(double t) const {
    LTParameterAssert(!isEmpty(), @"Trying to interpolate non-existing values of empty interval %@",
                      description());

    // No overflow possible since non-empty intervals always allow incrementing (/decrementing) of
    // their infimum (/supremum) by a single step.
    T min = _inf;
    T max = _sup;

    if (!infIncluded()) {
      min = std::is_integral<T>::value ? _inf + 1 : std::nextafter(_inf, _sup);
    }
    if (!supIncluded()) {
      max = std::is_integral<T>::value ? _sup - 1 : std::nextafter(_sup, _inf);
    }
    return (1 - t) * min + t * max;
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
    stream << (infIncluded() ? "[" : "(");
    stream << _inf;
    stream << ", ";
    stream << _sup;
    stream << (supIncluded() ? "]" : ")");
    return [NSString stringWithUTF8String:stream.str().c_str()];
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
