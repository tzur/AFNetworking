// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNAttributeProvider.h"

#import <LTEngine/LTGPUStruct.h>

NS_ASSUME_NONNULL_BEGIN

/// Value class representing the format of attribute data returned by \c id<DVNAttributeProvider>
/// constructed from \c DVNQuadTransformAttributeProviderModel objects. The GPU struct represents
/// the \c transform of a processed quad. \c rowX equals <tt>GLKMatrix3GetRow(transform, x)</tt>,
/// where <tt>x in {1, 2, 3}</tt> and \c transform is the transform of the quad (or its inverse,
/// according to the initialization value of `DVNQuadTransformAttributeProviderModel`).
LTGPUStructDeclare(DVNQuadTransformAttributeProviderStruct,
                   GLKVector3, row0,
                   GLKVector3, row1,
                   GLKVector3, row2);

/// Model of an \c id<DVNAttributeProvider> object providing the \c transform of each \c quad in the
/// processed \c dvn::GeometryValues as a attribute data. Calling
/// \c attributeDataFromGeometryValues: on the attribute provider yields \c LTAttributeData of the
/// following form: the \c gpuStruct of the attribute data is the
/// \c DVNQuadTransformAttributeProviderStruct GPU struct. The \c data of the attribute data - per
/// quad - has the form <tt>{{transform}, {transform}, {transform}, {transform}, {transform},
/// {transform}}</tt>, \c where \c transform corresponds to the \c transform() (inverse of
/// \c transform()) of the \c lt::Quad struct of the respective quad, if \c isInverse that is given
/// upon initialization is \c NO (\c YES).
@interface DVNQuadTransformAttributeProviderModel : NSObject <DVNAttributeProviderModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c isInverse.
- (instancetype)initWithIsInverse:(BOOL)isInverse NS_DESIGNATED_INITIALIZER;

/// If \c YES, the \c data of the attribute data - per quad - returned from
/// \c attributeDataFromGeometryValues: is populated with the inverse of the \c transform() of the
/// quad.
@property (readonly, nonatomic) BOOL isInverse;

@end

NS_ASSUME_NONNULL_END
