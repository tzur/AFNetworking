// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Group name of shared tests for objects conforming to the \c DVNAttributeProviderModel protocol.
extern NSString * const kDVNAttributeProviderExamples;

/// Dictionary key to the \c id<DVNAttributeProviderModel> object to test.
extern NSString * const kDVNAttributeProviderExamplesModel;

/// Dictionary key to an <tt>NSArray<LTQuad *> *</tt> object used to construct a
/// \c dvn::GeometryValues object provided to the \c attributeDataFromGeometryValues: method of the
/// \c id<DVNAttributeProvider> constructed from the model provided via
/// \c kDVNAttributeProviderExamplesModel.
extern NSString * const kDVNAttributeProviderExamplesInputQuads;

/// Dictionary key to an <tt>NSArray<NSNumber *> *</tt> object used to construct a
/// \c dvn::GeometryValues object provided to the \c attributeDataFromGeometryValues: method of the
/// \c id<DVNAttributeProvider> constructed from the model provided via
/// \c kDVNAttributeProviderExamplesModel. Must be of the same size as the collection provided via
/// \c kDVNAttributeProviderExamplesInputQuads.
extern NSString * const kDVNAttributeProviderExamplesInputIndices;

/// Dictionary key to an \c LTSampleValues object used to construct a \c dvn::GeometryValues object
/// provided to the \c attributeDataFromGeometryValues: method of the \c id<DVNAttributeProvider>
/// constructed from the model provided via \c kDVNAttributeProviderExamplesModel. Must contain
/// values with the same count as the collection provided via
/// \c kDVNAttributeProviderExamplesInputIndices.
extern NSString * const kDVNAttributeProviderExamplesInputSample;

/// Dictionary key to an \c NSData object expected as part of the result of a) the
/// \c attributeDataFromGeometryValues: method of the \c id<DVNAttributeProvider> constructed from
/// the model provided via \c kDVNAttributeProviderExamplesModel, when calling the method with the
/// data accessible via \c kDVNAttributeProviderExamplesInputQuads,
/// \c kDVNAttributeProviderExamplesInputIndices, and \c kDVNAttributeProviderExamplesInputSample,
/// and b) the \c sampleAttributeData method.
extern NSString * const kDVNAttributeProviderExamplesExpectedData;

/// Dictionary key to an \c LTGPUStruct object expected as part of the result of a) the
/// \c attributeDataFromGeometryValues: method of the \c id<DVNAttributeProvider> constructed from
/// the model provided via \c kDVNAttributeProviderExamplesModel, when calling the method with the
/// data accessible via \c kDVNAttributeProviderExamplesInputQuads,
/// \c kDVNAttributeProviderExamplesInputIndices, and \c kDVNAttributeProviderExamplesInputSample,
/// and b) the \c sampleAttributeData method.
extern NSString * const kDVNAttributeProviderExamplesExpectedGPUStruct;
