// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

@class LTParameterizedObjectType;

/// Group name of shared tests for objects conforming to the \c DVNSplineRendering protocol.
extern NSString * const kDVNSplineRenderingExamples;

/// Dictionary key to the \c LTTexture to be used as render target.
extern NSString * const kDVNSplineRenderingExamplesTexture;

/// Dictionary key to a mock of an \c id<DVNSplineRenderingDelegate> object.
extern NSString * const kDVNSplineRenderingExamplesDelegateMock;

/// Dictionary key to a strict mock of an \c id<DVNSplineRenderingDelegate> object.
extern NSString * const kDVNSplineRenderingExamplesStrictDelegateMock;

/// Dictionary key to an \c id<DVNSplineRendering> object without a delegate.
extern NSString * const kDVNSplineRenderingExamplesRendererWithoutDelegate;

/// Dictionary key to an \c id<DVNSplineRendering> object whose delegate is the mock returned by
/// \c kDVNSplineRenderingExamplesDelegateMock.
extern NSString * const kDVNSplineRenderingExamplesRendererWithDelegate;

/// Dictionary key to an \c id<DVNSplineRendering> object whose delegate is the strict mock returned
/// by \c kDVNSplineRenderingExamplesStrictDelegateMock.
extern NSString * const kDVNSplineRenderingExamplesRendererWithStrictDelegate;

/// Dictionary key to an \c LTParameterizedObjectType.
extern NSString * const kDVNSplineRenderingExamplesType;

/// Dictionary key to an \c NSArray containing an insufficient number of \c LTSplineControlPoint
/// objects to perform a rendering, given the \c LTParameterizedObjectType retrievable via
/// \c kDVNSplineRenderingExamplesType.
extern NSString * const kDVNSplineRenderingExamplesInsufficientControlPoints;

/// Dictionary key to an \c NSArray containing a number of \c LTSplineControlPoint objects that
/// suffice to perform a rendering, given the \c LTParameterizedObjectType retrievable via
/// \c kDVNSplineRenderingExamplesType.
extern NSString * const kDVNSplineRenderingExamplesControlPoints;

/// Dictionary key to an <tt>NSArray<LTSplineControlPoint *></tt> providing additional control
/// points.
extern NSString * const kDVNSplineRenderingExamplesAdditionalControlPoints;

/// Dictionary key to a \c DVNPipelineConfiguration.
extern NSString * const kDVNSplineRenderingExamplesPipelineConfiguration;

/// Convenient method that returns a dictionary with keys
/// \c kDVNSplineRenderingExamplesInsufficientControlPoints,
/// \c kDVNSplineRenderingExamplesControlPoints,
/// \c kDVNSplineRenderingExamplesAdditionalControlPoints and
/// \c kDVNSplineRenderingExamplesPipelineConfiguration, each of which maps to a respective test
/// object for the given \c type.
NSDictionary<NSString *, id> *DVNTestDictionaryForType(LTParameterizedObjectType *type);
