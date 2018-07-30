// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Value class which transfers a progress or a result in a mutually exclusive manner. This tries to
/// mimic a Swift enum that looks like:
///
/// @code
/// enum PTNProgress<T> {
///   case Result(T)
///   case Progress(Double)
/// }
/// @endcode
@interface PTNProgress<__covariant ResultType : id<NSObject>> : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a \c PTNProgress object with the resulting value.
- (instancetype)initWithResult:(ResultType)result NS_DESIGNATED_INITIALIZER;

/// Initializes a \c PTNProgress object with the current \c progress in [0, 1].
- (instancetype)initWithProgress:(NSNumber *)progress NS_DESIGNATED_INITIALIZER;

/// Returns an initialized \c PTNProgress object with the resulting value.
+ (instancetype)progressWithResult:(ResultType)result;

/// Returns an initialized \c \c PTNProgress object with the given \c progress in [0, 1].
+ (instancetype)progressWithProgress:(NSNumber *)progress;

/// Returns a new progress object with the result of running \c block on \c result if \c result is
/// not \c nil. If \c result is nil, returns a progress object with the same \c progress value.
- (PTNProgress *)map:(NS_NOESCAPE id(^)(ResultType object))block;

/// Value in [0, 1] that reports the current progress. If \c progress is \c nil, \c value must be
/// set to the resulting value.
@property (readonly, nonatomic, nullable) NSNumber *progress;

/// Result produced by the operation.
@property (readonly, nonatomic, nullable) ResultType result;

@end

NS_ASSUME_NONNULL_END
