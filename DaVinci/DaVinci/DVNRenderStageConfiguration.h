// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

@protocol DVNAttributeProviderModel;

/// Value class representing the configuration of the render stage of the \c DVNPipeline. The
/// configuration consists of the source code of the vertex and fragment shaders used by the
/// pipeline, as well as two mappings, one mapping the names of <tt>sampler uniform</tt> variables
/// of the fragment shader to corresponding textures and one mapping the names of primitive
/// \c uniform variables of the shaders to corresponding \c NSValue objects.
@interface DVNRenderStageConfiguration : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c vertexSource and \c fragmentSource.
- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource;

/// Initializes with the given \c vertexSource, \c fragmentSource, \c auxiliaryTextures, and
/// \c uniforms. The keys of the given \c auxiliaryTextures mapping should correspond to the names
/// of the sampler uniforms of the given \c fragmentSource.
- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                   auxiliaryTextures:(NSDictionary<NSString *, LTTexture *> *)auxiliaryTextures
                            uniforms:(NSDictionary<NSString *, NSValue *> *)uniforms
    NS_DESIGNATED_INITIALIZER;

/// Returns a new instance equal to the receiver, with the exception of the given
/// \c auxiliaryTextures and \c uniforms.
- (instancetype)copyWithAuxiliaryTextures:(NSDictionary<NSString *, LTTexture *> *)textures
                                 uniforms:(NSDictionary<NSString *, NSValue *> *)uniforms;

/// Source code to be executed by the vertex shader used by the \c DVNPipeline.
@property (readonly, nonatomic) NSString *vertexSource;

/// Source code to be executed by the fragment shader used by the \c DVNPipeline.
@property (readonly, nonatomic) NSString *fragmentSource;

/// Mapping of shader sampler uniform names to textures.
@property (readonly, nonatomic) NSDictionary<NSString *, LTTexture *> *auxiliaryTextures;

/// Mapping of shader uniform names to values.
@property (readonly, nonatomic) NSDictionary<NSString *, NSValue *> *uniforms;

@end

NS_ASSUME_NONNULL_END
