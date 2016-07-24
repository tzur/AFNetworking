// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNAttributeProvider.h"

#import <LTEngine/LTGPUStruct.h>

NS_ASSUME_NONNULL_BEGIN

/// Value class representing the format of attribute data returned by \c id<DVNAttributeProvider>
/// constructed from \c DVNQuadAttributeProviderModel objects.
LTGPUStructDeclare(DVNQuadAttributeProviderStruct,
                   LTVector2, quadVertex0,
                   LTVector2, quadVertex1,
                   LTVector2, quadVertex2,
                   LTVector2, quadVertex3);

/// Model of an \c id<DVNAttributeProvider> object providing the vertices of given quads as
/// attributes. Calling \c attributeDataFromGeometryValues: on the attribute provider yields
/// \c LTAttributeData of the following form: the \c gpuStruct of the attribute data is the
/// \c DVNQuadAttributeProviderStruct GPU struct. The \c data of the attribute data - per quad - has
/// the form <tt>{{v0, v1, v2, v3}, {v0, v1, v2, v3}, {v0, v1, v2, v3}, {v0, v1, v2, v3},
/// {v0, v1, v2, v3}, {v0, v1, v2, v3}}</tt>, \c where \c vx corresponds to the appropriate vertex
/// of the quad.
@interface DVNQuadAttributeProviderModel : NSObject <DVNAttributeProviderModel>
@end

NS_ASSUME_NONNULL_END
