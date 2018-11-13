// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

/// This matcher receives two one-channel uchar matrices, binarizes them with a middle-value (127)
/// threshold and then calculates the intersection over union ratio. The last is the number of
/// pixels that are non-zero in both matrices divided by the number of pixels that are non-zero in
/// at least one of them.
EXPMatcherInterface(_beCloseToMatIntersectionOverUnion, (NSValue *expected, id within));
EXPMatcherInterface(beCloseToMatIntersectionOverUnion, (NSValue *expected, id within));

#define beCloseToMatIntersectionOverUnion(expected, within) \
    _beCloseToMatIntersectionOverUnion((expected), EXPObjectify((within)))
