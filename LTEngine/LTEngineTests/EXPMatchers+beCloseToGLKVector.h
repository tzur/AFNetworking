// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

EXPMatcherInterface(_beCloseToGLKVectorWithin, (id expected, id length, id within));
EXPMatcherInterface(beCloseToGLKVectorWithin, (id expected, id length, id within));

#define beCloseToGLKVector(expected) _beCloseToGLKVectorWithin(EXPObjectify((expected)), \
    EXPObjectify(sizeof(expected) / sizeof(expected.x)), nil)
#define beCloseToGLKVectorWithin(expected, range) \
    _beCloseToGLKVectorWithin(EXPObjectify((expected)), \
                              EXPObjectify(sizeof(expected) / sizeof(expected.x)), \
                              EXPObjectify((range)))
