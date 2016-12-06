// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Group name of shared tests for objects conforming to the \c DVNGeometryProviderModel protocol.
extern NSString * const kDVNGeometryProviderExamples;

/// Dictionary key to the \c id<DVNGeometryProviderModel> object to test.
extern NSString * const kDVNGeometryProviderExamplesModel;

/// Dictionary key to an \c id<LTSampleValues> object used as parameter of the
/// \c valuesFromSamples:end: method of the \c id<DVNGeometryProvider> constructed from the model
/// provided via \c kDVNGeometryProviderExamplesModel.
extern NSString * const kDVNGeometryProviderExamplesSamples;

/// Group name of shared tests for objects conforming to the \c DVNGeometryProviderModel protocol
/// and provide deterministic geometry.
extern NSString * const kDVNDeterministicGeometryProviderExamples;

/// Dictionary key to an <tt>NSArray<LTQuad *> *</tt> object expected as part of the result of the
/// \c valuesFromSamples:end: method of the \c id<DVNGeometryProvider> constructed from the model
/// provided via \c kDVNGeometryProviderExamplesModel, when calling the method with the samples
/// accessible via \c kDVNGeometryProviderExamplesSamples and value \c NO for the \c end parameter
/// of the method. Must be of the same size as the collection provided via
/// \c kDVNGeometryProviderExamplesExpectedIndices.
extern NSString * const kDVNGeometryProviderExamplesExpectedQuads;

/// Dictionary key to a boxed \c std::vector<NSUInteger> object expected as part of the result of
/// the \c valuesFromSamples:end: method of the \c id<DVNGeometryProvider> constructed from the
/// model provided via \c kDVNGeometryProviderExamplesModel, when calling the method with the
/// samples accessible via \c kDVNGeometryProviderExamplesSamples and value \c NO for the \c end
/// parameter of the method. Must be of the same size as the collection provided via
/// \c kDVNGeometryProviderExamplesExpectedQuads.
extern NSString * const kDVNGeometryProviderExamplesExpectedIndices;
