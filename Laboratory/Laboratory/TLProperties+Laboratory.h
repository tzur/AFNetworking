// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "TLProperties.h"

NS_ASSUME_NONNULL_BEGIN

/// Category providing easy access to objects required by this library.
@interface TLProperties (Laboratory)

/// Returns the variation ID of the given \c variations in the give \c experiments. Returns \c nil
/// if \c variation does not exist in \c experiment, or if \c experiment does not exist.
- (nullable NSString *)lab_variationsIDForVariation:(NSString *)variation
                                       inExperiment:(NSString *)experiment;

/// Returns the experiment ID for the given \c experiment. Returns \c nil if the experiment doesn't
/// exist.
- (nullable NSString *)lab_experimentIDForExperiment:(NSString *)experiment;

/// Dictionary mapping the experiments running on the device to their selected variation.
@property (readonly, nonatomic)
    NSDictionary<NSString *, NSString *> *lab_runningExperimentsAndVariations;

/// Dictionary mapping all possible experiments to all their variations.
@property (readonly, nonatomic)
    NSDictionary<NSString *, NSSet<NSString *> *> *lab_allExperimentsAndVariations;

/// Currently active dynamic variables.
@property (readonly, nonatomic) NSDictionary<NSString *, id> *lab_dynamicVariables;

@end

NS_ASSUME_NONNULL_END
