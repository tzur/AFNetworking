// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Shift count to replicate the sign bit into all bits.
static const NSUInteger kLTSignReplicateShiftCount = sizeof(int32_t) * CHAR_BIT - 1;

/// Returns a bitmask with the number of lower \c bitCount bits set to 1. \c bitCount must be in the
/// range [0, 31].
NS_INLINE uint32_t LTBitMask(uint32_t bitCount) {
  return (1U << bitCount) - 1;
}

/// Returns an unsigned representation of \c value. This is not a 2-complement representation, but
/// the following holds: \c LTSignedToUnsigned(LTUnsignedToSigned(x)) = x and
/// \c LTUnsignedToSigned(LTSignedToUnsigned(x)) = x. Additionally, the number of bits required to
/// represent \c value equals to the number of bits required to represent \c
/// LTSignedToUnsigned(value), regardless of its sign.
NS_INLINE uint32_t LTSignedToUnsigned(int32_t value) __attribute__((no_sanitize("shift"))) {
  return (value << 1) ^ (value >> kLTSignReplicateShiftCount);
}

/// Returns a signed representation of \c value. This is not a 2-complement representation, but
/// the following holds: \c LTSignedToUnsigned(LTUnsignedToSigned(x)) = x and
/// \c LTUnsignedToSigned(LTSignedToUnsigned(x)) = x. Additionally, the number of bits required to
/// represent \c value equals to the number of bits required to represent \c
/// LTUnsignedToSigned(value), regardless of its sign.
NS_INLINE int32_t LTUnsignedToSigned(uint32_t value) {
  return (value >> 1) ^ (-((int32_t)(value & 1)));
}

/// Returns 0 if \c condition is not positive, otherwise \c value.
NS_INLINE int32_t LTCancelValue(int32_t value, int32_t condition) {
  return value & (-condition >> kLTSignReplicateShiftCount);
}

/// Returns the zero-based index of the most significant bit that is equal to 1. If \c value is
/// \c 0, the returned value is undefined.
NS_INLINE uint32_t LTBitScanReversed(uint32_t value) __attribute__((no_sanitize("builtin"))) {
  return __builtin_clz(value) ^ kLTSignReplicateShiftCount;
}

/// Minimal number of bits required for storing \c value, which must be in the range [0, INT32_MAX].
/// Values outside this range will produce an undefined result.
NS_INLINE uint32_t LTNumberOfBits(uint32_t value) {
  return LTCancelValue(1 + LTBitScanReversed(value), value);
}
