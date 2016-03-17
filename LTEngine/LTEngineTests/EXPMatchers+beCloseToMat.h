// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

EXPMatcherInterface(_beCloseToMatWithin, (NSValue *expected, id within));
EXPMatcherInterface(beCloseToMatWithin, (NSValue *expected, id within));

/// Uses \c 1 as maximum allowed deviation.
#define beCloseToMat(expected) _beCloseToMatWithin((expected), nil)

/// Uses the given \c range as maximum allowed deviation.
#define beCloseToMatWithin(expected, range) _beCloseToMatWithin((expected), EXPObjectify((range)))
