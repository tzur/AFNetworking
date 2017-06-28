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
@interface LABVariant : LTValueObject <NSSecureCoding>

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

/// Implementers of the protocol provides a set of variants that are active on the device via the
/// \c activeVariants property.
///
/// The source of the variants may be remote, so in order to fetch the latest variant data from
/// the remote resource, use the \c update and \c updateInBackground to fetch the latest data and
/// update \c activeVariants to its latest value.
///
/// @note If \c stabilizeUserExperienceAssignments was called, \c activeVariants may not change in
/// order to provide a stable user experience.
@protocol LABAssignmentsSource <NSObject>

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
/// yet fetched the data from a remote resource. Returns an empty set if there are no active
/// experiments.
///
/// @note This property is KVO-compliant, changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) NSSet<LABVariant *> *activeVariants;

/// Name which uniquely identifies the source.
@property (readonly, nonatomic) NSString *name;

@end

/// Implementers of this protocol provide info regarding all possible experiments, variants and
/// assignments from a specific experiments provider.
@protocol LABExperimentsSource <NSObject>

/// Signal returning an \c NSDictionary of all possible active and inactive experiments including
/// all their possible variants and completes. The dictionary's keys are experiment names, and the
/// values are sets of variant names.
///
/// The signal errs with \c LABErrorCodeFetchFailed if there was an error fetching the data.
///
/// @return RACSignal<NSDictionary <NSString *, NSSet<NSString *> *> *>
- (RACSignal *)fetchAllExperimentsAndVariants;

/// Signal returning the assignments for \c variant in \c experiment and completes.
///
/// The signal errs with \c LABErrorCodeVariantForExperimentNotFound if \c variant doesn't exist for
/// \c experiment, or \c LABErrorCodeFetchFailed if there was an error fetching the data.
///
/// @return RACSignal<NSDictionary<NSString *, id> *>
- (RACSignal *)fetchAssignmentsForExperiment:(NSString *)experiment
                                 withVariant:(NSString *)variant;

/// Name which uniquely identifies the source.
@property (readonly, nonatomic) NSString *name;

@end

NS_ASSUME_NONNULL_END
