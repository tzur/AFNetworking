// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Reason used by \c LABAssignmentsManager when informing its delegate that an assignment affected
/// the user by adding it to the \c activeAssignments of the manager.
extern NSString * const kLABAssignmentAffectedUserReasonActivatedForDevice;

/// Reason used by \c LABAssignmentsManager when informing its delegate that an assignment affected
/// the user by removing it to the \c activeAssignments of the manager.
extern NSString * const kLABAssignmentAffectedUserReasonDeactivatedForDevice;

/// Reason to use when reporting that an assignment affected a user by initiating a long-running
/// business logic.
extern NSString * const kLABAssignmentAffectedUserReasonInitiated;

/// Reason to use when reporting that an assignment affected a user by displaying its effects.
extern NSString * const kLABAssignmentAffectedUserReasonDisplayed;

@protocol LABAssignmentsSource, LABStorage;

/// Contains an assignment (key-value pair resulting from a variant) and its originating variant,
/// experiment and source.
///
/// Since assignment data can be changed over time, the object groups this information in order to
/// capture the value and its origins in a specific point in time.
@interface LABAssignment : LTValueObject <NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;

/// Initiliazes with the given parameters.
- (instancetype)initWithValue:(id)value key:(NSString *)key variant:(NSString *)variant
                   experiment:(NSString *)experiment sourceName:(NSString *)sourceName
    NS_DESIGNATED_INITIALIZER;

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

/// Reports to the analytics module that an assignment has affected the user experience using a
/// certain \c reason. An example of reason is "displayed".
///
/// @example An assignment defines the number of seconds before a pop-up screen is shown. This
/// method can be called with an \c kLABAssignmentAffectedUserReasonInitiated reason when a timer
/// was configured to show the pop-up and with \c kLABAssignmentAffectedUserReasonDisplayed reason
/// when the pop-up screen has been shown.
- (void)reportAssignmentAffectedUser:(LABAssignment *)assignment reason:(NSString *)reason;

/// Updates the \c activeAssignments with the latest assignments. The returned hot signal completes
/// when the update completes successfully or errs with \c LABErrorCodeAssignmentUpdateFailed on
/// failure.
///
/// Values are sent on the main thread.
///
/// @return RACSignal<>
- (RACSignal *)updateActiveAssignments;

/// Updates the \c activeAssignments with the latest assignments in the background. The returned hot
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

/// All currently active assignments.
///
/// @note This property is KVO-compliant, changes are delivered on the main thread.
@property (readonly, nonatomic) NSDictionary<NSString *, LABAssignment *> *activeAssignments;

@end

@class LABAssignmentsManager;

/// Implementers of this protocol are notified of changes to active assignments and assignments
/// affecting the user.
@protocol LABAssignmentsManagerDelegate <NSObject>

/// Notifies the delegate that an \c assignment affected user experience using \c reason under
/// the supervision of \c assignmentsManager. \c kLABAssignmentAffectedUserReasonActivatedForDevice
/// and \c kLABAssignmentAffectedUserReasonDeactiveForDevice are used to as \c reason indicate that
/// \c assignment was added or removed from the \c activeAssignments property of
/// \c assignmentsManager, respectively.
- (void)assignmentsManager:(LABAssignmentsManager *)assignmentsManager
   assignmentDidAffectUser:(LABAssignment *)assignment reason:(NSString *)reason;

@end

/// Default implementation for \c LABAssignmentsManager. Provides assignments from several
/// \c LABAssignmentsSource objects.
///
/// This class acts as a multiplexer and demultiplexer of the \c LABAssignmentsSource objects
/// meaning it forwards all the method calls to the all the \c sources and returns the merged
/// result. The \c activeAssignments property is a merged results of the \c activeVariants property
/// of all the underlying sources.
///
/// @attention If different sources have assignments with the same key (conflicting assignments) the
/// behavior for the conflicting experiments is undefined.
@interface LABAssignmentsManager : NSObject <LABAssignmentsManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c sources, \c delegate and default user defaults storage.
/// \c delegate is held weakly and used to report changes to \c activeAssignments and assignments
/// affecting the user.
///
/// @note All instances initialized with this initializer have a shared state.
- (instancetype)initWithAssignmentSources:(NSArray<id<LABAssignmentsSource>> *)sources
                                 delegate:(id<LABAssignmentsManagerDelegate>)delegate;

/// Initializes with the given \c sources, \c delegate and \c storage. \c delegate is held weakly
/// and used to report changes to \c activeAssignments and assignments affecting the user.
/// \c storage is used for persisting the \c activeAssignments, and informing of its changes.
- (instancetype)initWithAssignmentSources:(NSArray<id<LABAssignmentsSource>> *)sources
                                 delegate:(id<LABAssignmentsManagerDelegate>)delegate
                                  storage:(id<LABStorage>)storage
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
