// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/LTValueObject.h>

#import "LABAssignmentsSource.h"

NS_ASSUME_NONNULL_BEGIN

@class LTRandom;

@protocol LABExperimentsTokenProvider, LTKeyValuePersistentStorage;

/// Configuration of a variant for \c LABLocalSource. A variant is a set of assignments for an
/// experiment. The keys of the assignments must match those of the experiment the variant is
/// related to. Each variant has a \c probabilityWeight, which is used to decide which variant to
/// randomly assign to the experiment.
///
/// A variant is assigned randomly for an experiment using a discrete distribution, defined by the
/// \c probabilityWeight properties of all variants associated with the experiment.
///
/// For example, if an experiment has variants "A", "B", "C", with \c probabilityWeight of 1, 1 and
/// 2, accordingly, then variant "C" has twice the more chance of being assigned than either
/// variants "A" or "B".
///
/// @see -[LTRandom randomUnsignedIntegerWithWeights:].
@interface LABLocalVariant : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the \c name of the variant, \c probabilityWeight to affect the probability
/// of this variant to be selected, and the \c assignments for this variant.
- (instancetype)initWithName:(NSString *)name probabilityWeight:(NSUInteger)probabilityWeight
                 assignments:(NSDictionary<NSString *, id> *)assignments NS_DESIGNATED_INITIALIZER;

/// Variant name.
@property (readonly, nonatomic) NSString *name;

/// Receivers' weight in the discrete distribution.
@property (readonly, nonatomic) NSUInteger probabilityWeight;

/// Keys and values describing the variant, each key-value pair describes a certain behavior in the
/// application.
@property (readonly, nonatomic) NSDictionary<NSString *, id> *assignments;

@end

/// Defines the lower bound (exclusive) and upper bound (inclusive) of \c LABExperimentsToken that
/// specifies when an experiment is active. When a \c LABExperimentsToken falls in the range of an
/// experiment the experiment is active.
typedef std::pair<double, double> LABExperimentsTokenRange;

/// A set of variants, that when an experiment is active, one of them will be randomly selected to
/// be used.
///
/// An experiment is only active if the experiments token given to \c LABLocalSource is in the range
/// given in \c activeTokenRange.
@interface LABLocalExperiment : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the \c name of the experiment, the \c keys all the variants need to provide,
/// the \c variants of the experiments, and the \c activeTokenRange for this experiment.
///
/// @attention All variants must have \c assignments keys equal to \c keys in their assignments.
/// \c variants must contain at least one object.
///
/// @note There must be at least one variant with a positive \c probabilityWeight.
- (instancetype)initWithName:(NSString *)name keys:(NSArray<NSString *> *)keys
                    variants:(NSArray<LABLocalVariant *> *)variants
            activeTokenRange:(LABExperimentsTokenRange)activeTokenRange
    NS_DESIGNATED_INITIALIZER;

/// Returns a local experiment with variant for each field of the given \c enumClass, each variant
/// has \c probabilityWeight of 1, so the variants are uniformly distributed. The experiment
/// name is \c name. The experiment has only one key which is \c name. The possible values for the
/// key is the enum's fields.
///
/// The given \c activeTokenRange is used in the created experiment.
///
/// @note \c enumClass must conform to LTEnum.
+ (instancetype)experimentFromEnum:(Class)enumClass withName:(NSString *)name
                  activeTokenRange:(LABExperimentsTokenRange)activeTokenRange;

/// Experiment name.
@property (readonly, nonatomic) NSString *name;

/// All keys assigned by this experiment.
@property (readonly, nonatomic) NSArray<NSString *> *keys;

/// Range that defines whether this experiment is active. The experiment is active when the
/// \c LABExperimentsToken is in the range (activeTokenRange.first, activeTokenRange.second].
@property (readonly, nonatomic) LABExperimentsTokenRange activeTokenRange;

/// Variants for this experiment.
@property (readonly, nonatomic) NSDictionary<NSString *, LABLocalVariant *> *variants;

@end

/// Assignments source containing pre-configured experiments.
///
/// The configuration must specify all the experiments, their active probability range used to
/// decide whether the experiment is active, the variants for each experiment, the probability for
/// each variant and the assignments for each variant.
///
/// On first run, the active experiments are determined by testing whether the experiments token
/// provided by \c experimentsTokenProvider is in \c activeTokenRange. For each active experiment a
/// variant is randomly selected. The selected variant for each experiment is stored using
/// \c storage. The experiments activity is also stored in \c storage. Note that the assignments
/// themselves are not stored. On subsequent runs, the selected variants for each experiment are
/// persistent as long as the experiment and the its selected variant are in \c experiments.
///
/// If a stored experiment is not in \c experiments, any decision about that experiment is deleted.
///
/// If a stored variant does not exist in \c experiments, the experiment will be treated as new. Its
/// activity and its selected variant are determined again.
///
/// If the \c activeTokenRange is different than when the experiment activity was stored, the new
/// \c activeTokenRange does not take effect.
///
/// This class implements the \c stabilizeUserExperienceAssignments methods. After this method is
/// called, new experiments will not be exposed.
@interface LABLocalSource : NSObject <LABAssignmentsSource, LABExperimentsSource>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c experiments data to expose and \c experimentsTokenProvider to
/// decide whether an experiment is active. The default \c NSUserDefaults is used as \c storage, and
/// a new instance of \c LTRandom is used as \c random.
- (instancetype)initWithExperiments:(NSArray<LABLocalExperiment *> *)experiments
           experimentsTokenProvider:(id<LABExperimentsTokenProvider>)experimentsTokenProvider;

/// Initializes with the given \c experiments data to expose, \c experimentsTokenProvider to decide
/// whether an experiment is active, \c storage to store the selected variants to and \c random to
/// randomly select variants.
- (instancetype)initWithExperiments:(NSArray<LABLocalExperiment *> *)experiments
           experimentsTokenProvider:(id<LABExperimentsTokenProvider>)experimentsTokenProvider
                            storage:(id<LTKeyValuePersistentStorage>)storage
                             random:(LTRandom *)random
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
