// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Group name of shared tests for objects conforming to the \c DVNTexCoordProviderModel protocol.
extern NSString * const kDVNTexCoordProviderExamples;

/// Dictionary key to the \c id<DVNTexCoordProviderModel> object to test.
extern NSString * const kDVNTexCoordProviderExamplesModel;

/// Dictionary key to an <tt>NSArray<LTQuad *> *</tt> object used as parameter of the
/// \c textureMapQuadsForQuads: method of the \c id<DVNTexCoordProvider> constructed from the model
/// provided via \c kDVNTexCoordProviderExamplesModel.
extern NSString * const kDVNTexCoordProviderExamplesInputQuads;

/// Dictionary key to an <tt>NSArray<LTQuad *> *</tt> object expected as result of the
/// \c textureMapQuadsForQuads: method of the \c id<DVNTexCoordProvider> constructed from the model
/// provided via \c kDVNTexCoordProviderExamplesModel, when calling the method with the quads
/// accessible via \c kDVNTexCoordProviderExamplesInputQuads. Must be of the same size as the
/// collection provided via \c kDVNTexCoordProviderExamplesInputQuads.
extern NSString * const kDVNTexCoordProviderExamplesExpectedQuads;

/// Dictionary key to an <tt>NSArray<LTQuad *> *</tt> object used as parameter of the
/// \c textureMapQuadsForQuads: method of the \c id<DVNTexCoordProvider> constructed from the model
/// provided via \c kDVNTexCoordProviderExamplesModel. Is used after performing a single call to
/// aforementioned \c textureMapQuadsForQuads: method with the quads accessible via
/// \c kDVNTexCoordProviderExamplesInputQuads.
extern NSString * const kDVNTexCoordProviderExamplesAdditionalInputQuads;

/// Dictionary key to an <tt>NSArray<LTQuad *> *</tt> object expected as result of the
/// \c textureMapQuadsForQuads: method of the \c id<DVNTexCoordProvider> constructed from the model
/// provided via \c kDVNTexCoordProviderExamplesModel, when calling the method with the quads
/// accessible via \c kDVNTexCoordProviderExamplesAdditionalInputQuads. Is used after performing a
/// single call to aforementioned \c textureMapQuadsForQuads: method with the quads accessible via
/// \c kDVNTexCoordProviderExamplesInputQuads. Must be of the same size as the collection provided
/// via \c kDVNTexCoordProviderExamplesAdditionalInputQuads.
extern NSString * const kDVNTexCoordProviderExamplesAdditionalExpectedQuads;
