// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABAssignmentsSource.h"

NS_ASSUME_NONNULL_BEGIN

/// Block returning a signal that send an <tt>NSDictionary<NSString *, id></tt> of assignments for
/// \c experiment and variant. To be used in LABFakeAssignmentsSource.
typedef RACSignal * _Nonnull(^LABFetchAssignmentsSignalBlock)(NSString *experiment,
                                                              NSString *variant);

/// Fake implementation of \c LABAssignmentsSource.
@interface LABFakeAssignmentsSource : NSObject <LABAssignmentsSource, LABExperimentsSource>

/// Updates the given \c variants. The keys of the given dictionary are experiment names and the
/// values are variant names. If a variant is already selected for one of the experiments, it is
/// replaced with the variant given in \c variants. If a variant is \c NSNull then the experiment
/// is deactivated.
- (void)updateActiveVariants:(NSDictionary<NSString *, id> *)variants;

/// Source name.
@property (readwrite, nonatomic) NSString *name;

/// All experiments this receiver can expose.
@property (strong, nonatomic, nullable)
    NSDictionary<NSString *, NSArray<LABVariant *> *> *allExperiments;

/// Signal returned when calling <tt>-[LABAssignmentsSource update]</tt>. Defaults to
/// <tt>[RACSignal empty]</tt>.
@property (strong, nonatomic) RACSignal *updateSignal;

/// Signal returned when calling <tt>-[LABAssignmentsSource updateInBackground]</tt>. Defaults to
/// <tt>[RACSignal return:@(UIBackgroundFetchResultNoData)]</tt>.
@property (strong, nonatomic) RACSignal *backgroundUpdateSignal;

/// Signal returned when calling <tt>-[LABAssignmentsSource fetchAllExperimentsAndVariants]</tt>.
/// Defaults to a signal that returns the data as available in \c allExperiments.
@property (strong, nonatomic) RACSignal *fetchAllExperimentsAndVariantsSignal;

/// Block that returns a signal to return for the call
/// <tt>-[LABAssignmentsSource fetchAssignmentsForExperiment:withVariant:]</tt>. Defaults to a
/// a block that returns a signal that sends the assignments for the variant and experiment as in
/// \c allExperiments.
@property (strong, nonatomic) LABFetchAssignmentsSignalBlock fetchAssignmentsSignalBlock;

/// Amount of calls to the \c stabilizeUserExperienceAssignments method of this receiver.
@property (readonly, nonatomic) NSUInteger stabilizeUserExperienceAssignmentsRequestedCount;

/// Amount of calls to the \c update method of this receiver.
@property (readonly, nonatomic) NSUInteger updateRequestedCount;

/// Amount of calls to the \c updateInBackground method of this receiver.
@property (readonly, nonatomic) NSUInteger updateInBackgroundRequestedCount;

@end

NS_ASSUME_NONNULL_END
