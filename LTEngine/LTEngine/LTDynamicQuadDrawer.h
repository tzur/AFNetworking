// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuad.h"

NS_ASSUME_NONNULL_BEGIN

@class LTAttributeData, LTGPUStruct, LTTexture;

/// Name of <tt>uniform mat4</tt> variable required to exist in any vertex shader source used as
/// initialization parameter of an \c LTDynamicQuadDrawer object, providing access to the projection
/// matrix used by the corresponding shader.
///
/// <tt>GLKMatrix4MakeOrtho(0, 1, 0, 1, -1, 1)</tt> is used as default value if
/// <tt>[LTGLContext currentContext].renderingToScreen is \c NO, and
/// <tt>GLKMatrix4MakeOrtho(0, 1, 1, 0, -1, 1)</tt>, otherwise.
extern NSString * const kLTQuadDrawerUniformProjection;

/// Name of <tt>attribute vec4</tt> variable required to exist in any vertex shader source used as
/// initialization parameter of an \c LTDynamicQuadDrawer object, providing access to the vertex
/// position used by the corresponding shader. The vertex position is given in homogeneous
/// coordinates and is computed from the corresponding quad in the \c quads provided to the drawer.
extern NSString * const kLTQuadDrawerAttributePosition;

/// Name of <tt>attribute vec3</tt> variable required to exist in any vertex shader source used as
/// initialization parameter of an \c LTDynamicQuadDrawer object, providing access to the texture
/// coordinate position used by the corresponding shader, in homogeneous coordinates. The texture
/// coordinate position is computed from the corresponding quad in the \c textureMapQuads provided
/// to the drawer. It is the responsibility of the fragment shader to divide by the \c z coordinate
/// in order to return from homogeneous UV space to regular UV space.
extern NSString * const kLTQuadDrawerAttributeTexCoord;

/// Name of <tt>uniform sampler2D</tt> variable required to exist in any fragment shader used as
/// initialization parameter of an \c LTDynamicQuadDrawer object, providing access to the texture
/// used for texture-mapping of the rendered quadrilaterals.
extern NSString * const kLTQuadDrawerSamplerUniformTextureMap;

/// Name of GPU struct used internally by \c LTDynamicQuadDrawer objects. Must not be used as name
/// of GPU struct provided as initialization parameter of such objects.
extern NSString * const kLTQuadDrawerGPUStructName;

/// Immutable object for rendering ordered collections of quadrilateral geometry in 2D space with
/// associated attributes, using a fixed OpenGL program constructed upon initialization. Each
/// quadrilateral is texture-mapped with values retrieved from a quadrilateral region of a given
/// texture. The geometry is rendered into an already bound framebuffer. The geometry is allowed to
/// overlap.
///
/// @important This class assumes that the quadrilateral geometry is rendered with an orthographic
/// projection perpendicular to the plane in which the geometry resides. Vertex shaders using an
/// additional projection and/or a modelview matrix which do not have the aforementioned properties
/// must zero out the z-coordinate of the vertex position before multiplying the position with the
/// matrices. Note that this adaptation does only work if no z-buffer is used during rendering.
@interface LTDynamicQuadDrawer : NSObject

/// Initializes with the given \c vertexSource, \c fragmentSource, and \c gpuStructs.
///
/// The given \c vertexSource must contain:
/// - a uniform variable with name \c kLTQuadDrawerUniformProjection,
/// - an attribute variable with name \c kLTQuadDrawerAttributePosition of type \c vec4,
/// - as well as an attribute variable with name \c kLTQuadDrawerAttributeTexCoord of type \c vec3.
///
/// The given \c fragmentSource must contain a sampler uniform with name
/// \c kLTQuadDrawerSamplerUniformTextureMap.
///
/// The given \c gpuStructs must not contain any field with the name
/// \c kLTQuadDrawerAttributePosition or \c kLTQuadDrawerAttributeTexCoord. In addition, none of the
/// given \c gpuStructs must have the name \c kLTQuadDrawerGPUStructName.
- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                          gpuStructs:(NSOrderedSet<LTGPUStruct *> *)gpuStructs;

/// Draws the given \c quads, given in normalized coordinates, onto the currently bound framebuffer.
///
/// The drawing is performed in a single draw call, drawing two triangles per quad. For a quad with
/// vertices \c v0, \c v1, \c v2, the first triangle has vertices \c v0', \c v1', and \c v2', while
/// the second triangle has vertices \c v0', \c v2', and \c v3', where \c vx' is the point, in
/// four-dimensional, homogeneous coordinates, projected onto \c vx in the fragment shader. The
/// z-coordinate is equal for every vertex of a quad, and increases in steps of
/// <tt>1.0 / quads.size()<\tt> per quad. For the first quad of the given \c quads the z-coordinate
/// \c 0 is used.
///
/// For each quad in the given \c quads, the given \c texture is sampled using the corresponding
/// quad of the \c textureMapQuads, creating the corresponding texture mapping. Hence, the
/// \c size() of the \c quads must equal the \c size() of the \c textureMapQuads.
///
/// @param quads Quads to render.
///
/// @param textureMapQuads Quads whose vertices determine the normalized texture coordinates for the
/// corresponding vertices of the rendered quads.
///
/// @param attributeData Attribute data used as input to the vertex shader executed in this render
/// pass, in addition to the one constructed from the given \c quads and \c textureMapQuads. Must be
/// in the exact format of the \c gpuStructs given upon initialization, i.e. a) the number of
/// elements in the \c attributeData must correspond to the number of elements in the \c gpuStructs
/// given upon initialization, and b) the \c gpuStruct of every element in the \c attributeData must
/// equal the corresponding struct of the \c gpuStructs provided upon initialization. In addition,
/// the data must be given in the following format (relative to the format of a quad): for each quad
/// with vertices \c v0, \c v1, \c v2, and \c v3, there must be six entries, one for each vertex
/// \c v0, \c v1, \c v2, \c v0, \c v2, \c v3 (in this order) of the drawn triangles.
///
/// @param uniformsToAuxiliaryTextures Mapping of <tt>sampler uniform<\tt> variable names used by
/// the shaders provided upon initialization to corresponding textures.
///
/// @param uniforms Mapping of \c uniform variable names used by the shaders provided upon
/// initialization to corresponding values. Must not contain an entry for key
/// \c kLTQuadDrawerUniformProjection.
///
/// @important This object assumes the existence of a valid render target. Hence, a framebuffer must
/// be bound before calling this method.
- (void)drawQuads:(const std::vector<lt::Quad> &)quads
  textureMapQuads:(const std::vector<lt::Quad> &)textureMapQuads
    attributeData:(NSArray<LTAttributeData *> *)attributeData
          texture:(LTTexture *)texture
auxiliaryTextures:(NSDictionary<NSString *, LTTexture *> *)uniformsToAuxiliaryTextures
         uniforms:(NSDictionary<NSString *, NSValue *> *)uniforms;

/// Unique identifier of source code this instance was initialized with.
@property (readonly, nonatomic) NSString *sourceIdentifier;

/// GPU structs provided upon initialization.
@property (readonly, nonatomic) NSOrderedSet<LTGPUStruct *> *initialGPUStructs;

/// GPU structs determining the format of the attributes of the vertex shader executed by this
/// instance, including the GPU struct with name \c kLTQuadDrawerGPUStructName additionally used by
/// this instance.
@property (readonly, nonatomic) NSOrderedSet<LTGPUStruct *> *gpuStructs;

@end

NS_ASSUME_NONNULL_END
