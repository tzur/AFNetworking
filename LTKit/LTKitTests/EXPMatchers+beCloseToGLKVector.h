// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

EXPMatcherInterface(_beCloseToGLKVectorWithin, (id expected, id within));
EXPMatcherInterface(beCloseToGLKVectorWithin, (id expected, id within));

#define beCloseToGLKVector(expected) _beCloseToGLKVectorWithin(EXPObjectify((expected)), nil)
#define beCloseToGLKVectorWithin(expected, range) _beCloseToGLKVectorWithin(EXPObjectify((expected)), EXPObjectify((range)))
