// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ophir Abitbol.

EXPMatcherInterface(_beCloseToGLKMatrixWithin, (NSValue *expected, id within));
EXPMatcherInterface(beCloseToGLKMatrixWithin, (NSValue *expected, id within));

#define beCloseToGLKMatrix(expected) _beCloseToGLKMatrixWithin(expected, nil)
#define beCloseToGLKMatrixWithin(expected, range) _beCloseToGLKMatrixWithin(expected, \
                                                                            EXPObjectify((range)))
