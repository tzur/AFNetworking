// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABTweakCollectionsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class LABDebugSource;

/// Tweak collections provider that exposes tweaks according to the experiments and sources of an
/// \c LABDebugSource. A collection is provided for each underlying source of \c debugSource. Each
/// tweak in a collection is associated with one experiment and has the following possible values:
///
///  1. "Inactive" - Default value of the tweak. When selected, the experiment becomes inactive.
///  2. All available variants. When a variant is selected it activates that variant in the debug
///  source.
///
/// The Tweaks in a collection are ordered by experiment name. The possible values for a tweak are
/// sorted by variant name, instead of \c "Inactive" which is always last.
///
/// @note Implements \c updateCollections, which in turn updates the \c debugSource.
@interface LABDebugSourceTweakCollectionsProvider : NSObject <LABTweakCollectionsProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c debugSource for exposing experiments tweaks and controling experiment
/// variants.
- (instancetype)initWithDebugSource:(LABDebugSource *)debugSource NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
