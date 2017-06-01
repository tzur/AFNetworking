// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

@protocol LABAssignmentsSource;

/// Contains an assignment (key-value pair resulting from a variant) and its originating variant,
/// experiment and source.
///
/// Since assignment data can be changed over time, the protocol groups this information in order to
/// capture the value and its origins in a specific point in time.
@protocol LABAssignment <NSObject>

/// Assignment value.
@property (readonly, nonatomic) id value;

/// Assignment key.
@property (readonly, nonatomic) NSString *key;

/// Variant of the experiment where the assignment originated from.
@property (readonly, nonatomic) NSString *variant;

/// Experiment where the assignment originated from.
@property (readonly, nonatomic) NSString *experiment;

/// Name of the source that provided the assignment.
@property (readonly, nonatomic) NSString *sourceName;

/// The revision of the active assignments.
@property (readonly, nonatomic) NSUUID activeAssignmentsRevisionID;

@end

/// Implementers of this protocol provide access to assignments (key and value pairs) and report
/// their usage to an analytics service.
@protocol LABAssignmentsManager <NSObject>

/// Hints that any assignments affecting user experience should not be changed from this point on,
/// in order to provide a stable user experience.
///
/// This method should be called before showing major user experience elements that are affected by
/// the assignments, but after sufficient time has passed in order to allow fetching assignment
/// data from remote resources.
///
/// @note Calling this method does not guarantee that such assignments will not change.
- (void)stabilizeUserExperienceAssignments;

/// Reports to the analytics module that an assignment has affected the user experience. This method
/// should not be called when the assignment has been used, but rather when the effects of the
/// assignment were noticed by the user.
///
/// @example An assignment defines the number of seconds before a pop-up screen is shown. This
/// method must be called when the pop-up screen has been shown and not when the timer was
/// configured to use the value of the assignment.
- (void)reportAssignmentAffectedUser:(id<LABAssignment>)assignment;

/// Updates the \c activeAssignments with the latest assignments. The returned signal completes when
/// the update completes successfully or errs with \c LABErrorCodeAssignmentUpdateFailed on failure.
///
/// Values are sent on the main thread.
///
/// @return RACSignal<>
- (RACSignal *)updateActiveAssignments;

/// Updates the \c activeAssignments with the latest assignments in the background. The returned
/// signal completes when the update completes successfully or errs with
/// \c LABErrorCodeAssignmentUpdateFailed on failure.
///
/// The API is meant to be used from the
/// <tt>-[UIApplicationDelegate application:performFetchWithCompletionHandler:]</tt> callback.
///
/// The signal returns a single \c UIBackgroundFetchResult wrapped in \c NSNumber and completes. The
/// signal does not err. Values are sent on the main thread.
///
/// @return RACSignal<NSNumber *>
- (RACSignal *)updateActiveAssignmentsInBackground;

/// All the currently active assignments. Maps assignment keys to objects containing the assignment
/// value and associated data.
///
/// @note This property is KVO-compliant, changes are delivered on the main thread.
@property (readonly, nonatomic) NSDictionary<NSString *, id<LABAssignment>> *activeAssignments;

@end

/// Default implementation for \c LABAssignmentsManager. Provides assignments from several
/// \c LABAssignmentsSource objects.
///
/// This class acts as a multiplexer and demultiplexer of the \c LABAssignmentsSource objects
/// meaning it forwards all the method calls to the all the \c sources and returns the merged
/// result. The \c activeAssignments property is a merged results of the \c activeAssignments
/// property of all the underlying sources.
///
/// @attention If different sources have assignments with the same key (conflicting assignments) the
/// behavior for the conflicting experiments is undefined.
@interface LABAssignmentsManager : NSObject <LABAssignmentsManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c sources.
- (instancetype)initWithAssignmentSources:(NSArray<id<LABAssignmentsSource>> *)sources
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
