// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Represents an instantaneous progress information about some task that eventually yields some
/// result. The type of the result produced by the task and carried by the progress object is
/// generic and is determined by the \c ResultType template variable.
@interface LTProgress<ResultType : id<NSObject>> : NSObject <NSCopying>

/// Initialize a progress object with \c progress set to \c 0.
- (instancetype)init;

/// Initializes an active task progress object with the given \c progress value. \c progress must be
/// in the range \c [0, 1] otherwise an \c NSInvalidArgumentException is raised.
- (instancetype)initWithProgress:(double)progress NS_DESIGNATED_INITIALIZER;

/// Initializes a completed task progress object with the given \c result object. \c result must
/// not be \c nil.
- (instancetype)initWithResult:(ResultType)result NS_DESIGNATED_INITIALIZER;

/// Fraction of the overall work completed by the task, in the range \c [0, 1].
@property (readonly, nonatomic) double progress;

/// Final result yielded by the task or \c nil if the task is yet to complete.
@property (readonly, nonatomic, nullable) ResultType result;

@end

NS_ASSUME_NONNULL_END
