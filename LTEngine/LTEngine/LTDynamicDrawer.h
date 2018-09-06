// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTAttributeData, LTGPUStruct, LTIndicesData, LTTexture;

/// Immutable object for drawing triangular geometry by invocating single OpenGLES draw calls, using
/// a fixed OpenGLES program and changing attribute data. The drawer is optimized for attribute data
/// dynamically changing in both size and content between consecutive draw calls. The drawer is
/// independent of the render target; hence, a framebuffer must be bound before performing draw
/// calls with this object.
@interface LTDynamicDrawer : NSObject

/// Initializes with the given \c vertexSource, \c fragmentSource and the given \c gpuStructs.
///
/// @param vertexSource Source of vertex shader used by the returned object.
///
/// @param fragmentSource Source of fragment shader used by the returned object.
///
/// @param gpuStructs Orderered set of GPU structs determining the fixed format in which attribute
/// data must be provided to the returned object. The names of the fields in the given \c gpuStructs
/// must be different from each other and must equal the set of attribute names occuring in the
/// \c vertexSource. The given \c gpuStructs must contain at least one element.
- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                          gpuStructs:(NSOrderedSet<LTGPUStruct *> *)gpuStructs;

/// Performs a single draw call to OpenGLES, using the given \c attributeData,
/// \c uniformToTextureMapping and \c uniforms.
///
/// @param attributeData Attribute data used as input to the vertex shader executed in this
/// render pass. Must be in the exact format of the \c gpuStructs given upon initialization, i.e.
/// a) the number of elements in the \c attributeData must correspond to the number of elements in
/// the \c gpuStructs given upon initialization, and b) the \c gpuStruct of every element in the
/// \c attributeData must equal the corresponding struct of the \c gpuStructs provided upon
/// initialization. In addition, the number of bytes of the binary \c data of every element in the
/// given \c attributeData must be equal and the number of vertices encoded by every element must be
/// divisible by \c 3, since this object renders triangular geometry. The geometry provided via the
/// attribute data is assumed to be counter-clockwise front-facing.
///
/// @param samplerUniformsToTextures Mapping of <tt>sampler uniform<\tt> variable names used by the
/// shaders provided upon initialization to corresponding textures.
///
/// @param uniforms Mapping of \c uniform variable names used by the shaders provided upon
/// initialization to corresponding values.
///
/// @important This object assumes the existence of a valid render target. Hence, a framebuffer must
/// be bound before calling this method.
- (void)drawWithAttributeData:(NSArray<LTAttributeData *> *)attributeData
    samplerUniformsToTextures:(NSDictionary<NSString *, LTTexture *> *)samplerUniformsToTextures
                     uniforms:(NSDictionary<NSString *, NSValue *> *)uniforms;

/// Performs a single draw call to OpenGLES, using the given \c attributeData, \c indices,
/// \c uniformToTextureMapping and \c uniforms.
///
/// @param attributeData Attribute data used as input to the vertex shader executed in this
/// render pass. Must be in the exact format of the \c gpuStructs given upon initialization, i.e.
/// a) the number of elements in the \c attributeData must correspond to the number of elements in
/// the \c gpuStructs given upon initialization, and b) the \c gpuStruct of every element in the
/// \c attributeData must equal the corresponding struct of the \c gpuStructs provided upon
/// initialization. In addition, the number of bytes of the binary \c data of every element in the
/// given \c attributeData must be equal.
///
/// @param indices Object providing the indices of the elements of \c attributeData to be used for
/// drawing. The \c count property of this object must be divisible by \c 3.
///
/// @param samplerUniformsToTextures Mapping of <tt>sampler uniform<\tt> variable names used by the
/// shaders provided upon initialization to corresponding textures.
///
/// @param uniforms Mapping of \c uniform variable names used by the shaders provided upon
/// initialization to corresponding values.
///
/// @important This object assumes the existence of a valid render target. Hence, a framebuffer must
/// be bound before calling this method.
- (void)drawWithAttributeData:(NSArray<LTAttributeData *> *)attributeData
                      indices:(LTIndicesData *)indices
    samplerUniformsToTextures:(NSDictionary<NSString *, LTTexture *> *)samplerUniformsToTextures
                     uniforms:(NSDictionary<NSString *, NSValue *> *)uniforms;

/// Unique identifier of source code provided upon initialization.
@property (readonly, nonatomic) NSString *sourceIdentifier;

/// GPU structs provided upon initialization, determining the format of the attributes of the vertex
/// shader executed by this instance.
@property (readonly, nonatomic) NSOrderedSet<LTGPUStruct *> *gpuStructs;

@end

NS_ASSUME_NONNULL_END
