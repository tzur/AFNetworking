// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Group name of shared tests for objects conforming to the \c NSObject protocol. The shared tests
/// check whether the objects correctly implement the \c isEqual: and \c hash methods.
extern NSString * const kLTEqualityExamples;

/// Dictionary key to the object whose implementation of the \c NSObject protocol is to test.
extern NSString * const kLTEqualityExamplesObject;

/// Dictionary key to an object equal but not identical to the one provided via
/// \c kLTEqualityExamplesObject.
extern NSString * const kLTEqualityExamplesEqualObject;

/// Dictionary key to \c NSArray of objects of the same class as the one provided via
/// \c kLTEqualityExamplesObject but different from that object and different from each other.
extern NSString * const kLTEqualityExamplesDifferentObjects;
