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
@interface PTNProgress : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a \c PTNProgress object with the resulting value.
- (instancetype)initWithResult:(id<NSObject>)result NS_DESIGNATED_INITIALIZER;

/// Initializes a \c PTNProgress object with the current \c progress in [0, 1].
- (instancetype)initWithProgress:(NSNumber *)progress NS_DESIGNATED_INITIALIZER;

/// Value in [0, 1] that reports the current progress. If \c progress is \c nil, \c value must be
/// set to the resulting value.
@property (readonly, nonatomic, nullable) NSNumber *progress;

/// Result produced by the operation.
@property (readonly, nonatomic, nullable) id<NSObject> result;

@end

NS_ASSUME_NONNULL_END
