// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/LTValueObject.h>

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

/// Contains a variant, its assignments and its originating experiment.
@interface LABVariant : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c name, \c assignments and \c experiment.
- (instancetype)initWithName:(NSString *)name
                 assignments:(NSDictionary<NSString *, id> *)assignments
                  experiment:(NSString *)experiment NS_DESIGNATED_INITIALIZER;

/// Variant name.
@property (readonly, nonatomic) NSString *name;

/// Variant assignments.
@property (readonly, nonatomic) NSDictionary<NSString *, id> *assignments;

/// Experiment this variant was selected for.
@property (readonly, nonatomic) NSString *experiment;

@end

/// Implementers of this protocol manage assignments, variants and experiments.
/// A source provides a set of experiments, and a device can participate in all or in a subset of
/// them. The set of experiments the current device is participating in is called the active
/// experiments. When a device participates in an experiment, a variant will be selected for that
/// experiment by the source, providing the selected variants via the \c activeVariants property.
///
/// @note A source may store its data remotely, that means the data will not be always available.
/// In such cases, the signals/properties can return \c nil. Once the data is fetched, the signals
/// will send new values, and properties will have new values.
@protocol LABAssignmentsSource <NSObject>

/// Signal returning an \c NSSet containing all possible active and non-active experiments and
/// completes.
///
/// The signal errs with \c LABErrorCodeFetchFailed if there was an error fetching the data.
///
/// @return RACSignal<NSSet<NSString *> *>
- (RACSignal *)fetchAllExperiments;

/// Signal returning the possible variants for the given \c experiment. \c experiment should be
/// either one returned from the \c activeVariants property or from the \c fetchAllExperiments
/// method. The returned signal sends the current possible variants and continues to send values as
/// the list of possible variants changes. If \c experiment no longer exists, the signal errs with
/// \c LABErrorCodeExperimentNotFound. The signal errs with \c LABErrorCodeExperimentNotFound if
/// \c experiment does not exist.
///
/// @return RACSignal<NSSet<NSString *> *>
- (RACSignal *)fetchVariantsForExperiment:(NSString *)experiment;

/// Signal returning the assignments for \c variant in \c experiment and completes.
///
/// The signal errs with \c LABErrorCodeVariantForExperimentNotFound if \c variant doesn't exist for
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
/// If new information was received from the remote resource, the property \c activeVariants may
/// change.
///
/// @return RACSignal<>
- (RACSignal *)update;

/// Updates the source with the latest data from a remote resource. The API is meant to be used from
/// the <tt>-[UIApplicationDelegate application:performFetchWithCompletionHandler:]</tt> callback.
///
/// If new information was received from the remote resource, the property \c activeVariants may
/// change.
///
/// The signal returns \c UIBackgroundFetchResult wrapped in an \c NSNumber and completes. The
/// signal doesn't err.
///
/// @return RACSignal<NSNumber *>
- (RACSignal *)updateInBackground;

@required

/// Returns all selected variants for the active experiments. Returns \c nil if the source has not
/// yet fetched the data from a remote resource. Returns an empty array if there are no active
/// experiments.
///
/// @note This property is KVO-compliant, changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) NSSet<LABVariant *> *activeVariants;

/// Name which uniquely identifies the source.
@property (readonly, nonatomic) NSString *name;

@end

NS_ASSUME_NONNULL_END
