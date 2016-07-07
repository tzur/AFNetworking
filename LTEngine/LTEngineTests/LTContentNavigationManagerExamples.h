// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Group name of shared tests for objects conforming to the \c LTContentNavigationManager protocol.
extern NSString * const kLTContentNavigationManagerExamples;

/// Dictionary key to the object to test. The object must conform to both the
/// \c LTContentInteractionManager and the \c LTContentLocationProvider protocols.
extern NSString * const kLTContentNavigationManager;

/// Dictionary key to \c NSValue encapsulating a reachable \c CGRect to be used for zooming.
extern NSString * const kLTContentNavigationManagerReachableRect;

/// Dictionary key to \c NSValue encapsulating an unreachable \c CGRect to be used for zooming.
extern NSString * const kLTContentNavigationManagerUnreachableRect;

/// Dictionary key to \c NSValue encapsulating the \c CGRect representing the visible content rect
/// after zooming to the unreachable rectangle.
extern NSString * const kLTContentNavigationManagerExpectedRect;

/// Dictionary key to another object of the class to test. The object must conform to both the
/// \c LTContentInteractionManager and the \c LTContentLocationProvider protocols.
extern NSString * const kAnotherLTContentNavigationManager;
