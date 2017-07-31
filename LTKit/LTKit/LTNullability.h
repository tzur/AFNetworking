// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus

namespace lt {

/// Returns \c object if it's not \c nil, otherwise terminates the app.
template <typename T>
static inline T _Nonnull nn(T _Nullable object) noexcept {
#if defined(DEBUG) && DEBUG
  LTAssert(object, @"Nullable object can not be converted to nonnull because its value is nil");
#else
  if (!object) {
    LogError(@"Nullable object can not be converted to nonnull because its value is nil");
  }
#endif
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
  // We cannot explicitly cast, as this generates another error:
  // error: explicit ownership qualifier on cast result has no effect.
  // Since this is just compiler sugar, it doesn't matter.
  return object;
#pragma clang diagnostic pop
}

/// Returns \c object if it's not \c nil, otherwise returns \c defaultValue, which must not be
/// \c nil.
template <typename T>
static inline T _Nonnull nn(T _Nullable object, T _Nonnull defaultValue) noexcept {
#if defined(DEBUG) && DEBUG
  LTParameterAssert(defaultValue, @"Nullable defaultValue can not be converted to nonnull because "
                    "its value is nil");
#else
  if (!defaultValue) {
    LogError(@"Nullable defaultValue can not be converted to nonnull because its value is nil");
  }
#endif
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
  // We cannot explicitly cast, as this generates another error:
  // error: explicit ownership qualifier on cast result has no effect.
  // Since this is just compiler sugar, it doesn't matter.
  return object ?: defaultValue;
#pragma clang diagnostic pop
}

} // namespace lt

#endif

NS_ASSUME_NONNULL_END
