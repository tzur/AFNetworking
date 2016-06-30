// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPResponse;

/// Holds an instantaneous progress information about a single HTTP task.
@interface FBRHTTPTaskProgress : NSObject <NSCopying>

/// Initialize a progress object for a yet to be started task with \c progress set to \c 0.
- (instancetype)init;

/// Initializes an active task progress object with the given \c progress value. \c progress must be
/// in the range \c [0, 1] otherwise an \c NSInvalidArgumentException is raised.
- (instancetype)initWithProgress:(double)progress NS_DESIGNATED_INITIALIZER;

/// Initializes a completed task progress object with the given \c response object.
- (instancetype)initWithResponse:(FBRHTTPResponse *)response NS_DESIGNATED_INITIALIZER;

/// Fraction of the overall work completed by the task. Value of \c 0 indicates that the task hasn't
/// started, a value of \c 1 indicates that the task has completed.
@property (readonly, nonatomic) double progress;

/// HTTP server response for this task or \c nil if the task is yet to complete.
@property (readonly, nonatomic, nullable) FBRHTTPResponse *response;

/// \c YES if the task has started.
@property (readonly, nonatomic) BOOL hasStarted;

/// \c YES if the task has completed.
@property (readonly, nonatomic) BOOL hasCompleted;

@end

NS_ASSUME_NONNULL_END
