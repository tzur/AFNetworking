// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class DVNBrushRenderModel, DVNPipelineConfiguration, LTTexture;

/// Protocol to be implemented by objects constructing \c DVNPipelineConfiguration objects from a
/// given \c DVNBrushRenderModel object and a mapping defined as follows:
///
/// The keys of the mapping are the keys of the properties of the \c DVNBrushModel object which hold
/// the URLs to the images required by the constructed model. The values of the mapping are the
/// aforementioned images themselves.
///
/// @important The parameterized object processed by the \c DVNPipeline configured with the
/// \c DVNPipelineConfiguration retrievable from this object is assumed to provide mappings with
/// locations in floating-point pixel units of the brush stroke geometry coordinate system, as
/// defined by \c DVNBrushModel.
///
/// @important The geometry constructible from the \c DVNPipelineConfiguration retrievable from this
/// object is given in normalized floating-point pixel units of the render target.
@protocol DVNBrushRenderConfigurationProvider <NSObject>

/// Returns the configuration of a \c DVNPipeline object constructed according to the given
/// \c model, with the textures of the given \c textureMapping. The keys of the given
/// \c textureMapping must be contained by the \c imageURLPropertyKeys of the \c brushModel of the
/// given \c model. Calls to this method do not modify the properties or the content of the
/// \c LTTexture objects in the given \c textureMapping.
///
/// @note The receiver does not retain the given \c textureMapping but might cache the given
/// \c model, for increased performance.
- (DVNPipelineConfiguration *)configurationForModel:(DVNBrushRenderModel *)model
    withTextureMapping:(NSDictionary<NSString *, LTTexture *> *)textureMapping;

@end

/// General provider of brush render configurations.
@interface DVNBrushRenderConfigurationProvider : NSObject <DVNBrushRenderConfigurationProvider>
@end

NS_ASSUME_NONNULL_END
