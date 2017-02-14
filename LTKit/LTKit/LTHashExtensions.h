// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

// Adds \c std::hash template specializations for selected \c std value types and structs.
// References:
// http://stackoverflow.com/questions/7222143/unordered-map-hash-function-c
// http://stackoverflow.com/questions/7110301/generic-hash-for-tuples-in-unordered-map-unordered-set

namespace lt {

#ifdef __LP64__
/// 64-bit hash function borrowed from Boost.
template <class T>
inline void hash_combine(std::size_t &seed, const T &v) {
  std::hash<T> hasher;
  uint64_t k = hasher(v);
  const uint64_t m = UINT64_C(0xc6a4a7935bd1e995);
  const int r = 47;

  k *= m;
  k ^= k >> r;
  k *= m;

  seed ^= k;
  seed *= m;

  // Completely arbitrary number, to prevent 0's from hashing to 0.
  seed += 0xe6546b64;
}
#else
/// 32-bit hash function borrowed from Boost.
template <class T>
inline void hash_combine(std::size_t &seed, const T &v) {
  std::hash<T> hasher;
  seed ^= hasher(v) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
}
#endif

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

} // namespace lt

#pragma mark -
#pragma mark CGPoint
#pragma mark -

template <>
struct ::std::hash<CGPoint> {
  inline size_t operator()(CGPoint p) const {
    size_t seed = 0;
    lt::hash_combine(seed, p.x);
    lt::hash_combine(seed, p.y);
    return seed;
  }
};

#pragma mark -
#pragma mark CGSize
#pragma mark -

template <>
struct ::std::hash<CGSize> {
  inline size_t operator()(CGSize s) const {
    size_t seed = 0;
    lt::hash_combine(seed, s.width);
    lt::hash_combine(seed, s.height);
    return seed;
  }
};

#pragma mark -
#pragma mark CGRect
#pragma mark -

template <>
struct ::std::hash<CGRect> {
  inline size_t operator()(CGRect r) const {
    size_t seed = 0;
    lt::hash_combine(seed, r.origin.x);
    lt::hash_combine(seed, r.origin.y);
    lt::hash_combine(seed, r.size.width);
    lt::hash_combine(seed, r.size.height);
    return seed;
  }
};

#pragma mark -
#pragma mark CGAffineTransform
#pragma mark -

template <>
struct ::std::hash<CGAffineTransform> {
  inline size_t operator()(CGAffineTransform t) const {
    size_t seed = 0;
    lt::hash_combine(seed, t.a);
    lt::hash_combine(seed, t.b);
    lt::hash_combine(seed, t.c);
    lt::hash_combine(seed, t.d);
    lt::hash_combine(seed, t.tx);
    lt::hash_combine(seed, t.ty);
    return seed;
  }
};

#pragma mark -
#pragma mark GLKMatrix2
#pragma mark -

template <>
struct ::std::hash<GLKMatrix2> {
  inline size_t operator()(GLKMatrix2 t) const {
    size_t seed = 0;
    lt::hash_combine(seed, t.m00);
    lt::hash_combine(seed, t.m01);
    lt::hash_combine(seed, t.m10);
    lt::hash_combine(seed, t.m11);
    return seed;
  }
};

#pragma mark -
#pragma mark GLKMatrix3
#pragma mark -

template <>
struct ::std::hash<GLKMatrix3> {
  inline size_t operator()(GLKMatrix3 t) const {
    size_t seed = 0;
    lt::hash_combine(seed, t.m00);
    lt::hash_combine(seed, t.m01);
    lt::hash_combine(seed, t.m02);
    lt::hash_combine(seed, t.m10);
    lt::hash_combine(seed, t.m11);
    lt::hash_combine(seed, t.m12);
    lt::hash_combine(seed, t.m20);
    lt::hash_combine(seed, t.m21);
    lt::hash_combine(seed, t.m22);
    return seed;
  }
};

#pragma mark -
#pragma mark GLKMatrix4
#pragma mark -

template <>
struct ::std::hash<GLKMatrix4> {
  inline size_t operator()(GLKMatrix4 t) const {
    size_t seed = 0;
    lt::hash_combine(seed, t.m00);
    lt::hash_combine(seed, t.m01);
    lt::hash_combine(seed, t.m02);
    lt::hash_combine(seed, t.m03);
    lt::hash_combine(seed, t.m10);
    lt::hash_combine(seed, t.m11);
    lt::hash_combine(seed, t.m12);
    lt::hash_combine(seed, t.m13);
    lt::hash_combine(seed, t.m20);
    lt::hash_combine(seed, t.m21);
    lt::hash_combine(seed, t.m22);
    lt::hash_combine(seed, t.m23);
    lt::hash_combine(seed, t.m30);
    lt::hash_combine(seed, t.m31);
    lt::hash_combine(seed, t.m32);
    lt::hash_combine(seed, t.m33);
    return seed;
  }
};

#pragma mark -
#pragma mark CATransform3D
#pragma mark -

template <>
struct ::std::hash<CATransform3D> {
  inline size_t operator()(CATransform3D t) const {
    size_t seed = 0;

    lt::hash_combine(seed, t.m11);
    lt::hash_combine(seed, t.m12);
    lt::hash_combine(seed, t.m13);
    lt::hash_combine(seed, t.m14);
    lt::hash_combine(seed, t.m21);
    lt::hash_combine(seed, t.m22);
    lt::hash_combine(seed, t.m23);
    lt::hash_combine(seed, t.m24);
    lt::hash_combine(seed, t.m31);
    lt::hash_combine(seed, t.m32);
    lt::hash_combine(seed, t.m33);
    lt::hash_combine(seed, t.m34);
    lt::hash_combine(seed, t.m41);
    lt::hash_combine(seed, t.m42);
    lt::hash_combine(seed, t.m43);
    lt::hash_combine(seed, t.m44);

    return seed;
  }
};

#pragma mark -
#pragma mark std::pair
#pragma mark -

/// Hash specialization for \c std::pair.
template <typename T, typename U>
struct ::std::hash<std::pair<T, U>> {
  inline size_t operator()(const std::pair<T, U> &v) const {
    size_t seed = 0;
    lt::hash_combine(seed, v.first);
    lt::hash_combine(seed, v.second);
    return seed;
  }
};

#pragma mark -
#pragma mark std::tuple
#pragma mark -

namespace lt {
namespace detail {

/// Recursive template for performing hash on \c std::tuple.
template <class T, size_t Index = std::tuple_size<T>::value - 1>
struct TupleHash {
  static void apply(size_t &seed, const T &tuple) {
    TupleHash<T, Index - 1>::apply(seed, tuple);
    lt::hash_combine(seed, std::get<Index>(tuple));
  }
};

/// Template base case for hashing \c std::tuple.
template <class T>
struct TupleHash<T, 0> {
  static void apply(size_t &seed, const T &tuple) {
    lt::hash_combine(seed, std::get<0>(tuple));
  }
};

} // namespace detail
} // namespace lt

/// Hash specialization for \c std::tuple.
template <typename ... T>
struct ::std::hash<std::tuple<T...>> {
  inline size_t operator()(const std::tuple<T...> &t) const {
    size_t seed = 0;
    lt::detail::TupleHash<std::tuple<T...>>::apply(seed, t);
    return seed;
  }
};

#pragma mark -
#pragma mark std::vector
#pragma mark -

/// Hash specialization for \c std::vector.
template <typename T>
struct ::std::hash<std::vector<T>> {
  inline size_t operator()(const std::vector<T> &v) const {
    size_t seed = 0;
    lt::hash_range(seed, v.begin(), v.end());
    return seed;
  }
};

#pragma mark -
#pragma mark std::array
#pragma mark -

namespace lt {
namespace detail {

/// Recursive template for performing hash on \c std::array.
template <class T, size_t Index>
struct ArrayHash {
  static void apply(size_t &seed, const T &array) {
    ArrayHash<T, Index - 1>::apply(seed, array);
    lt::hash_combine(seed, std::get<Index - 1>(array));
  }
};

/// Template base case for hashing \c std::array.
template <class T>
struct ArrayHash<T, 1> {
  static void apply(size_t &seed, const T &array) {
    lt::hash_combine(seed, std::get<0>(array));
  }
};

} // namespace detail
} // namespace lt

/// Hash specialization for \c std::array.
template <typename T, size_t N>
struct ::std::hash<std::array<T, N>> {
  inline size_t operator()(const std::array<T, N> &a) const {
    size_t seed = 0;
    lt::detail::ArrayHash<std::array<T, N>, N>::apply(seed, a);
    return seed;
  }
};

#pragma mark -
#pragma mark Objective-C objects
#pragma mark -

/// Creates an \c std::hash specialization for the given Objective-C \c CLASS.
#define LTObjectiveCHashMake(CLASS) \
  template <> \
  struct ::std::hash<CLASS *> { \
    inline size_t operator()(CLASS *object) const { \
      static_assert(sizeof(size_t) == sizeof(NSUInteger), \
          "size_t size must be equal to NSUInteger size"); \
      return [object hash]; \
    } \
  }

LTObjectiveCHashMake(NSArray);
LTObjectiveCHashMake(NSDate);
LTObjectiveCHashMake(NSDictionary);
LTObjectiveCHashMake(NSNumber);
LTObjectiveCHashMake(NSString);
LTObjectiveCHashMake(NSValue);
