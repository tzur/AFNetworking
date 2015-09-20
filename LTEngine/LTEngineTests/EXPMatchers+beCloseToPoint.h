// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

EXPMatcherInterface(_beCloseToPointWithin, (id expected, id within));
EXPMatcherInterface(beCloseToPointWithin, (id expected, id within));

#define beCloseToPoint(expected) _beCloseToPointWithin(EXPObjectify((expected)), nil)
#define beCloseToPointWithin(expected, range) _beCloseToPointWithin(EXPObjectify((expected)), EXPObjectify((range)))
