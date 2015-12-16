// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

// Adds \c lt::hash template specializations for \c std value types. References:
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

} // namespace detail

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

} // namespace lt
