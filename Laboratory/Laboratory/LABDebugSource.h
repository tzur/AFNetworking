// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABAssignmentsSource.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTStorage;

/// Implementers of this protocol provide info about an experiment - its name, available variants,
/// and the current active variant and its assignments. This info is used by the \c LABDebugSource
/// to expose experiments for debug purposes.
@protocol LABDebugExperiment <NSObject>

/// Experiment name.
@property (readonly, nonatomic) NSString *name;

/// Variants available for the experiment.
@property (readonly, nonatomic) NSSet<NSString *> *variants;

/// \c YES if there is a selected variant for the experiment.
@property (readonly, nonatomic) BOOL isActive;

/// Currently active variant. \c nil if no variant is active.
@property (readonly, nonatomic, nullable) LABVariant *activeVariant;

@end

/// Debug source allows the exposure of all possible experiments from multiple sources and allows
/// manual setting of the active experiments and variants. This source is to be used in
/// non-production builds in order to check correctness of experiment configurations and their
/// interaction with the application and one another.
///
/// Activation requests of variants for the available \c allExperiments is persistent until a
/// different variant for experiment is activated or until the experiments is deactivated.
///
/// Active experiments are exposed only if they are in \c allExperiments and
/// \c variantActivationRequests.
///
/// @attention Using this source may lead to activation of intersecting experiments, i.e.
/// experiments which would otherwise not be active in the same application session.
@interface LABDebugSource : NSObject <LABAssignmentsSource>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c sources and user defaults storage. \c sources are used to fetch experiment
/// models.
- (instancetype)initWithSources:(NSArray<id<LABExperimentsSource>> *)sources;

/// Initializes with \c sources and \c storage. \c sources are used to fetch experiment models.
/// \c storage is used to store the latest \c allExperiments.
- (instancetype)initWithSources:(NSArray<id<LABExperimentsSource>> *)sources
                        storage:(id<LTStorage>)storage NS_DESIGNATED_INITIALIZER;

/// Activates \c variant of \c experiment from \c source. The activation is done synchronously.
/// Returns a hot signal that sends \c YES if \c variant is active for \c experiment and \c NO if
/// the activation cannot be made because \c experiment or \c variant is unavailable. Completes if
/// a the receiver was requested to activate the same \c experiment for \c source with a different
/// variant or if \c experiment was deactivated.
///
/// @return RACSignal<NSNumber *>
///
/// @note the returned signal sends values on an arbitrary thread.
- (RACSignal *)activateVariant:(NSString *)variant ofExperiment:(NSString *)experiment
                      ofSource:(NSString *)source;

/// Deactivates \c experiment from \c source. The deactivation is done synchronously. Once this
/// method returns \c allExperiments, \c variantActivationRequests and \c activeVariants will
/// reflect the changes.
- (void)deactivateExperiment:(NSString *)experiment ofSource:(NSString *)source;

/// Resets all variant activation requests.
- (void)resetVariantActivations;

/// All available experiments and their activity state, as stated in \c variantActivationRequests.
/// Maps between a source name to a set of all its available experiments. If an experiment is
/// active, then its active variant must be in \c activeVariants.
///
/// @note This property is KVO-compliant, changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic)
    NSDictionary<NSString *, NSSet<id<LABDebugExperiment>> *> *allExperiments;

/// All latest variant activation requests that were made using
/// \c activateVariant:ofExperiment:ofSource:. and activation request for a different variant for
/// the same experiment and source ovverides a previous one. A deactivation removes an experiment
/// from this dictionary.
@property (readonly, nonatomic)
    NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *variantActivationRequests;

@end

NS_ASSUME_NONNULL_END
