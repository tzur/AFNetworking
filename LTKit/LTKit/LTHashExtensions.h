// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

// Adds \c lt::hash template specializations for selected \c std value types and structs.
// References:
// http://stackoverflow.com/questions/7222143/unordered-map-hash-function-c
// http://stackoverflow.com/questions/7110301/generic-hash-for-tuples-in-unordered-map-unordered-set

namespace lt {

/// Default hash function which falls back to \c std::hash.
template <typename T>
struct hash {
  inline size_t operator()(const T &t) const {
    return std::hash<T>()(t);
  }
};

namespace detail {

/// Hash function borrowed from Boost.
template <class T>
inline void hash_combine(std::size_t &seed, const T &v) {
  lt::hash<T> hasher;
  seed ^= hasher(v) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
}

/// Template for calculating the combined hash value of the elements in an iterator range.
///
/// @see http://www.boost.org/doc/libs/1_35_0/doc/html/boost/hash_range_id420926.html
template <class It>
inline void hash_range(std::size_t &seed, It first, It last) {
  while (first != last) {
    hash_combine(seed, *first);
    ++first;
  }
}

} // namespace detail

#pragma mark -
#pragma mark CGPoint
#pragma mark -

template <>
struct hash<CGPoint> {
  inline size_t operator()(CGPoint p) const {
    size_t seed = 0;
    detail::hash_combine(seed, p.x);
    detail::hash_combine(seed, p.y);
    return seed;
  }
};

#pragma mark -
#pragma mark CGSize
#pragma mark -

template <>
struct hash<CGSize> {
  inline size_t operator()(CGSize s) const {
    size_t seed = 0;
    detail::hash_combine(seed, s.width);
    detail::hash_combine(seed, s.height);
    return seed;
  }
};

#pragma mark -
#pragma mark std::pair
#pragma mark -

/// Hash specialization for \c std::pair.
template <typename T, typename U>
struct hash<std::pair<T, U>> {
  inline size_t operator()(const std::pair<T, U> &v) const {
    size_t seed = 0;
    detail::hash_combine(seed, v.first);
    detail::hash_combine(seed, v.second);
    return seed;
  }
};

#pragma mark -
#pragma mark std::tuple
#pragma mark -

namespace detail {

/// Recursive template for performing hash on \c std::tuple.
template <class T, size_t Index = std::tuple_size<T>::value - 1>
struct TupleHash {
  static void apply(size_t &seed, const T &tuple) {
    TupleHash<T, Index - 1>::apply(seed, tuple);
    detail::hash_combine(seed, std::get<Index>(tuple));
  }
};

/// Template base case for hashing \c std::tuple.
template <class T>
struct TupleHash<T, 0> {
  static void apply(size_t &seed, const T &tuple) {
    lt::detail::hash_combine(seed, std::get<0>(tuple));
  }
};

} // namespace detail

/// Hash specialization for \c std::tuple.
template <typename ... T>
struct hash<std::tuple<T...>> {
  inline size_t operator()(const std::tuple<T...> &t) const {
    size_t seed = 0;
    detail::TupleHash<std::tuple<T...>>::apply(seed, t);
    return seed;
  }
};

#pragma mark -
#pragma mark std::vector
#pragma mark -

/// Hash specialization for \c std::vector.
template <typename T>
struct hash<std::vector<T>> {
  inline size_t operator()(const std::vector<T> &v) const {
    size_t seed = 0;
    detail::hash_range(seed, v.begin(), v.end());
    return seed;
  }
};

#pragma mark -
#pragma mark std::array
#pragma mark -

namespace detail {

/// Recursive template for performing hash on \c std::array.
template <class T, size_t Index>
struct ArrayHash {
  static void apply(size_t &seed, const T &array) {
    ArrayHash<T, Index - 1>::apply(seed, array);
    detail::hash_combine(seed, std::get<Index - 1>(array));
  }
};

/// Template base case for hashing \c std::array.
template <class T>
struct ArrayHash<T, 1> {
  static void apply(size_t &seed, const T &array) {
    lt::detail::hash_combine(seed, std::get<0>(array));
  }
};

} // namespace detail

/// Hash specialization for \c std::array.
template <typename T, size_t N>
struct hash<std::array<T, N>> {
  inline size_t operator()(const std::array<T, N> &a) const {
    size_t seed = 0;
    detail::ArrayHash<std::array<T, N>, N>::apply(seed, a);
    return seed;
  }
};

} // namespace lt
