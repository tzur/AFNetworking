// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

EXPMatcherInterface(_beCloseToCATransform3DWithin, (id expected, id within));
EXPMatcherInterface(beCloseToCATransform3DWithin, (id expected, id within));

#define beCloseToCATransform3D(expected) \
    _beCloseToCATransform3DWithin(EXPObjectify([NSValue valueWithCATransform3D:expected]), nil)
#define beCloseToCATransform3DWithin(expected, range) \
    _beCloseToCATransform3DWithin(EXPObjectify([NSValue valueWithCATransform3D:expected]), \
                                  EXPObjectify((range)))
