// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

namespace lt {

/// Struct representing a primitive scalar interval from a value \c a to a value \c b. The interval
/// can be open, half-closed, or closed. The template parameter \c T must be of a primitive scalar
/// type.
template <typename T>
class Interval {
public:
  /// Types of end point inclusion indicating whether an end point of the interval is included.
  enum EndpointInclusion {
    /// Indicates that the end point is not included in the interval.
    Open,
    /// Indicates that the end point is included in the interval.
    Closed
  };

  /// Returns an empty interval.
  Interval() noexcept : minValue(0), maxValue(0),
      minEndpointInclusion(Open), maxEndpointInclusion(Open) {}

  /// Initializes with the given \c values, the \c minEndpointInclusion indicating whether the
  /// minimum end point of the interval is included, and the \c maxEndpointInclusion indicating
  /// whether the maximum end point of the interval is included.
  Interval(std::pair<T, T> values, EndpointInclusion minEndpointInclusion,
           EndpointInclusion maxEndpointInclusion) noexcept :
      minValue(std::min(values.first, values.second)),
      maxValue(std::max(values.first, values.second)),
      minEndpointInclusion(minEndpointInclusion), maxEndpointInclusion(maxEndpointInclusion) {}

  /// Initializes with the given \c values and the \c endpointInclusion indicating whether the end
  /// points of the interval are included.
  Interval(std::pair<T, T> values, EndpointInclusion endpointInclusion) noexcept :
      minValue(std::min(values.first, values.second)),
      maxValue(std::max(values.first, values.second)),
      minEndpointInclusion(endpointInclusion), maxEndpointInclusion(endpointInclusion) {}

  /// Returns \c true if this interval contains the given \c value.
  bool contains(T value) const {
    return (minEndpointIncluded() ? value >= minValue : value > minValue) &&
        (maxEndpointIncluded() ? value <= maxValue : value < maxValue);
  }

  /// Minimum value of this interval.
  T min() const {
    return minValue;
  };

  /// Maximum value of this interval.
  T max() const {
    return maxValue;
  }

  /// \c true if the minimum endpoint of this interval belongs to the interval.
  bool minEndpointIncluded() const {
    return minEndpointInclusion == Closed;
  }

  /// \c true if the maximum endpoint of this interval belongs to the interval.
  bool maxEndpointIncluded() const {
    return maxEndpointInclusion == Closed;
  }

private:
  /// Minimum value of this interval.
  T minValue;
  /// Maximum value of this interval.
  T maxValue;
  /// \c true if the minimum endpoint of this interval belongs to the interval.
  EndpointInclusion minEndpointInclusion;
  /// \c true if the maximum endpoint of this interval belongs to the interval.
  EndpointInclusion maxEndpointInclusion;
};

} // namespace lt
