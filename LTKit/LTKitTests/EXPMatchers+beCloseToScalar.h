// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

EXPMatcherInterface(_beCloseToScalarWithin, (NSValue *expected, id within));
EXPMatcherInterface(beCloseToScalarWithin, (NSValue *expected, id within));

#define beCloseToScalar(expected) _beCloseToScalarWithin((expected), nil)
#define beCloseToScalarWithin(expected, range) _beCloseToScalarWithin((expected), \
                                                                      EXPObjectify((range)))
