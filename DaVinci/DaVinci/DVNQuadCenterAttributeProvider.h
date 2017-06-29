// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTGPUStruct.h>

#import "DVNAttributeProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Value class representing the format of attribute data returned by \c id<DVNAttributeProvider>
/// constructed from \c DVNQuadCenterAttributeProviderModel objects.
LTGPUStructDeclare(DVNQuadCenterAttributeProviderStruct,
                   LTVector2, quadCenter);

/// Model of an \c id<DVNAttributeProvider> object providing the center of given quads as
/// attributes. Calling \c attributeDataFromGeometryValues: on the attribute provider yields
/// \c LTAttributeData of the following form: the \c gpuStruct of the attribute data is the
/// \c DVNQuadCenterAttributeProviderStruct GPU struct. The \c data of the attribute data - per
/// quad - has the form <tt>{{center}, {center}, {center}, {center}, {center}, {center}}</tt>,
/// \c where \c center equals the \c LTVector2 representation of the center of the quad.
@interface DVNQuadCenterAttributeProviderModel : NSObject <DVNAttributeProviderModel>
@end

NS_ASSUME_NONNULL_END
