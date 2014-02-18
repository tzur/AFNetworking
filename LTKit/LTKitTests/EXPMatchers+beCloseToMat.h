// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

EXPMatcherInterface(_beCloseToMatWithin, (NSValue *expected, id within));
EXPMatcherInterface(beCloseToMatWithin, (NSValue *expected, id within));

#define beCloseToMat(expected) _beCloseToMatWithin((expected), nil)
#define beCloseToMatWithin(expected, range) _beCloseToMatWithin((expected), EXPObjectify((range)))
