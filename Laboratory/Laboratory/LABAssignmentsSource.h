// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

/// Glossary:
///
/// Assignment - Key and value pair that represents a behavioral property of the app where
/// the key that property and the value defines the chosen behavior for that property.
///
/// Variant (of an experiment) - A set of assignments.
///
/// Experiment - A set of assignment keys, and one or more variants. In an experiment, all
/// assignments of all the variants must have the exact set of keys as the experiment they're in.
///
/// Implementers of this protocol manage assignments, variants and experiments.
/// A source provides a set of experiments, and a device can participate in all or in a subset of
/// them. The set of experiments the current device is participating in is called the active
/// experiments. When a device participates in an experiment, a variant will be selected for that
/// experiment by the source, providing the assignments of that variant via the \c activeAssignments
/// property.
///
/// @note A source may store its data remotely, that means the data will not be always available.
/// In such cases, the signals/properties can return \c nil. Once the data is fetched, the signals
/// will send new values, and properties will have new values.
@protocol LABAssignmentsSource <NSObject>

/// Signal returning the possible variants for the given \c experiment. \c experiment should be one
/// of the experiments from the \c allExperiments property. The returned signal sends the current
/// possible variants and continues to send values as the list of possible variants changes. If
/// \c experiment no longer exists, the signal errs with \c LABErrorCodeExperimentNotFound. If
/// \c experiment does not exist, the signal will err with \c LABErrorCodeExperimentNotFound.
///
/// @return RACSignal<NSArray<NSString *> *>
- (RACSignal *)variantsForExperiment:(NSString *)experiment;

/// Signal returning the active experiment that assigned the given \c assignmentKey.
/// \c assignmentKey should be one of the keys in the \c activeAssignments property. The returned
/// signal sends the current value and continues to send values as the value changes, if the
/// assignment no longer exists, the signal errs with \c LABErrorCodeAssignmentKeyNotFound. If
/// \c assignmentKey does not exist for any active experiment, the signal will err with
/// \c LABErrorCodeAssignmentKeyNotFound.
///
/// @return RACSignal<NSString *>
- (RACSignal *)experimentForAssignment:(NSString *)assignmentKey;

/// Signal returning the assignments for \c variant in \c experiment and completes.
///
/// The signal errs with \c LABErrorCodeSourceUpdateFailed if \c variant doesn't exist for
/// \c experiment, or there was an error fetching the data.
///
/// @return RACSignal<NSDictionary<NSString *, id> *>
- (RACSignal *)fetchAssignmentsForExperiment:(NSString *)experiment
                                 withVariant:(NSString *)variant;

@optional

/// Hints that any assignments affecting user experience should not be changed from this point on,
/// in order to provide a stable user experience.
///
/// @note Calling this method does not guarantee that such assignments will not change.
- (void)stabilizeUserExperienceAssignments;

/// Updates the source with the latest data from a remote resource. The returned signal completes
/// when the update completes successfully or errs with \c LABErrorCodeSourceUpdateFailed if the
/// update fails.
///
/// If new information was received from the remote resource, the properties \c activeAssignments,
/// \c activeExperimentsAndVariants and \c allExperiments may change.
///
/// @return RACSignal<>
- (RACSignal *)update;

/// Updates the source with the latest data from a remote resource. The API is meant to be used from
/// the <tt>-[UIApplicationDelegate application:performFetchWithCompletionHandler:]</tt> callback.
///
/// If new information was received from the remote resource, the properties \c activeAssignments,
/// \c activeExperimentsAndVariants and \c allExperiments may change.
///
/// The signal returns \c UIBackgroundFetchResult wrapped in an \c NSNumber and completes. The
/// signal doesn't err.
///
/// @return RACSignal<NSNumber *>
- (RACSignal *)updateInBackground;

@required

/// Returns all the assignments derived from the active experiments. The dictionary maps assignments
/// keys to assignment values. Returns \c nil if the source has not yet fetched the data from a
/// remote resource. Returns an empty dictionary if there are no acitve assignments.
///
/// @note This property is KVO-compliant, changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) NSDictionary<NSString *, id> *activeAssignments;

/// Returns mapping of active experiments to their selected variants. Returns \c nil if the source
/// has not yet fetched the data from a remote resource. Returns an empty dictionary if there are
/// not active experiments.
///
/// @note This property is KVO-compliant, changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable)
    NSDictionary<NSString *, NSString *> *activeExperimentsAndVariants;

/// Returns the active and non-active experiments of this source or \c nil if the source has no
/// data.
///
/// @note This property is KVO-compliant, changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) NSArray<NSString *> *allExperiments;

/// Name which uniquely identifies the source.
@property (readonly, nonatomic) NSString *name;

@end

NS_ASSUME_NONNULL_END
