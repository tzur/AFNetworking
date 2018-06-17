// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

EXPMatcherInterface(_beCloseToMatNormalizedHamming, (NSValue *expected, id within));
EXPMatcherInterface(beCloseToMatNormalizedHamming, (NSValue *expected, id within));

/// Uses the given \c within as maximum allowed Normalized Hamming Distance. The Normalized Hamming
/// Distance is the number of pixels that are differet between the \c expected matrix and the
/// \c actual matrix divided by the total number of pixels in any of these matrices.
#define beCloseToMatNormalizedHamming(expected, within) \
    _beCloseToMatNormalizedHamming((expected), EXPObjectify((within)))
