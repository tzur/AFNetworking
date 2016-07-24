// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNAttributeProvider.h"

#import <LTEngine/LTGPUStruct.h>

NS_ASSUME_NONNULL_BEGIN

/// Value class representing the format of attribute data returned by \c id<DVNAttributeProvider>
/// constructed from \c DVNMaxEdgeLengthAttributeProviderModel objects.
LTGPUStructDeclare(DVNMaxEdgeLengthAttributeProviderStruct,
                   float, maxEdgeLength);

/// Model of an \c id<DVNAttributeProvider> object providing the maximum edge length of given quads
/// as attributes. Calling \c attributeDataFromGeometryValues: on the attribute provider yields
/// \c LTAttributeData of the following form: the \c gpuStruct of the attribute data is the
/// \c DVNMaxEdgeLengthAttributeProviderStruct GPU struct. The \c data of the attribute data -
/// per quad - has the form <tt>{e, e, e, e, e, e}</tt>, \c where \c e is the maximum edge length
/// of the quad.
@interface DVNMaxEdgeLengthAttributeProviderModel : NSObject <DVNAttributeProviderModel>
@end

NS_ASSUME_NONNULL_END
