// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKNeuralNetworkTypeDefinitions.h"

NS_ASSUME_NONNULL_BEGIN

/// Returns a pair of boolean values. The first value is \c YES iff the given \c activationType
/// needs the \c alpha parameter for initialization. The second value is \c YES iff the given
/// \c activationType needs the \c beta parameter for initialization.
std::pair<BOOL, BOOL> PNKActivationNeedsAlphaBetaParameters(pnk::ActivationType activationType);

NS_ASSUME_NONNULL_END
