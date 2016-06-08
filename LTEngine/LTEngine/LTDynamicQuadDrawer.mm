// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTDynamicQuadDrawer.h"

#import "LTAttributeData.h"
#import "LTDynamicDrawer.h"
#import "LTGLContext.h"
#import "LTGPUStruct.h"

/// GPU struct holding the position and texture coordinate of a triangulated quad. Notice that the
/// \c position attribute is an \c LTVector3, meaning the \c z coordinate can be used by the shader.
/// This allows some GPUs to optimize the drawing of overlapping triangles, and drawing only the top
/// one.
LTGPUStructMake(LTDynamicQuadDrawerVertex,
                LTVector3, position,
                LTVector2, texcoord);

NSString * const kLTQuadDrawerUniformProjection = @"projection";
NSString * const kLTQuadDrawerAttributePosition = @"position";
NSString * const kLTQuadDrawerAttributeTexCoord = @"texcoord";
NSString * const kLTQuadDrawerSamplerUniformTextureMap = @"sourceTexture";
NSString * const kLTQuadDrawerGPUStructName = @"LTDynamicQuadDrawerVertex";

@interface LTDynamicQuadDrawer ()

/// GPU struct determining the format of the attributes required by any vertex shader executed by
/// this instance.
@property (readonly, nonatomic) LTGPUStruct *gpuStruct;

/// Internally used drawer.
@property (readonly, nonatomic) LTDynamicDrawer *drawer;

@end

@implementation LTDynamicQuadDrawer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                          gpuStructs:(NSOrderedSet<LTGPUStruct *> *)gpuStructs {
  LTParameterAssert(vertexSource);
  LTParameterAssert(fragmentSource);
  LTParameterAssert(gpuStructs);

  if (self = [super init]) {
    _gpuStruct = [[LTGPUStructRegistry sharedInstance] structForName:kLTQuadDrawerGPUStructName];
    gpuStructs =
        [NSOrderedSet orderedSetWithArray:[gpuStructs.array arrayByAddingObject:_gpuStruct]];
    _drawer =
        [[LTDynamicDrawer alloc] initWithVertexSource:vertexSource fragmentSource:fragmentSource
                                           gpuStructs:gpuStructs];
  }
  return self;
}

#pragma mark -
#pragma mark Rendering
#pragma mark -

- (void)drawQuads:(const std::vector<lt::Quad> &)quads
  textureMapQuads:(const std::vector<lt::Quad> &)textureMapQuads
    attributeData:(NSArray<LTAttributeData *> *)attributeData
          texture:(LTTexture *)texture
auxiliaryTextures:(NSDictionary<NSString *, LTTexture *> *)uniformsToAuxiliaryTextures
         uniforms:(NSDictionary<NSString *, NSValue *> *)uniforms {
  LTParameterAssert(quads.size() == textureMapQuads.size(),
                    @"Number of quads (%lu) must equal number of texture map quads (%lu)",
                    (unsigned long)quads.size(), (unsigned long)textureMapQuads.size());
  LTParameterAssert(attributeData);
  LTParameterAssert(texture);
  LTParameterAssert(!uniformsToAuxiliaryTextures[kLTQuadDrawerSamplerUniformTextureMap],
                    @"Dictionary (%@) must not contain key of uniform of texture used for texture "
                    "mapping (%@).", uniformsToAuxiliaryTextures,
                    kLTQuadDrawerSamplerUniformTextureMap);
  LTParameterAssert(uniforms);

  if (!quads.size()) {
    return;
  }

  attributeData = [attributeData arrayByAddingObject:[self attributeDataForQuads:quads
                                                                 textureMapQuads:textureMapQuads]];

  NSDictionary<NSString *, LTTexture *> *uniformsToTextures =
      [self mappingAugmentedWithTexture:texture fromMapping:uniformsToAuxiliaryTextures];

  uniforms = [self uniformsFromUniforms:uniforms];

  [self.drawer drawWithAttributeData:attributeData samplerUniformsToTextures:uniformsToTextures
                            uniforms:uniforms];
}

- (LTAttributeData *)attributeDataForQuads:(const std::vector<lt::Quad> &)quads
                           textureMapQuads:(const std::vector<lt::Quad> &)textureMapQuads {
  NSUInteger numberOfQuads = quads.size();

  LTParameterAssert(numberOfQuads);
  LTParameterAssert(textureMapQuads.size() == numberOfQuads);

  std::vector<LTDynamicQuadDrawerVertex> attributes;
  attributes.reserve(numberOfQuads);
  CGFloat z = 0;

  for (NSUInteger i = 0; i < numberOfQuads; ++i) {
    lt::Quad targetQuad = quads[i];
    lt::Quad textureMapQuad = textureMapQuads[i];

    CGPoint v0 = targetQuad.v0();
    CGPoint v1 = targetQuad.v1();
    CGPoint v2 = targetQuad.v2();
    CGPoint v3 = targetQuad.v3();

    CGPoint t0 = textureMapQuad.v0();
    CGPoint t1 = textureMapQuad.v1();
    CGPoint t2 = textureMapQuad.v2();
    CGPoint t3 = textureMapQuad.v3();

    attributes.push_back({.position = LTVector3(v0.x, v0.y, z),
                          .texcoord = LTVector2(t0.x, t0.y)});
    attributes.push_back({.position = LTVector3(v1.x, v1.y, z),
                          .texcoord = LTVector2(t1.x, t1.y)});
    attributes.push_back({.position = LTVector3(v2.x, v2.y, z),
                          .texcoord = LTVector2(t2.x, t2.y)});
    attributes.push_back({.position = LTVector3(v0.x, v0.y, z),
                          .texcoord = LTVector2(t0.x, t0.y)});
    attributes.push_back({.position = LTVector3(v2.x, v2.y, z),
                          .texcoord = LTVector2(t2.x, t2.y)});
    attributes.push_back({.position = LTVector3(v3.x, v3.y, z),
                          .texcoord = LTVector2(t3.x, t3.y)});

    z += 1.0 / numberOfQuads;
  }

  NSData *data = [NSData dataWithBytes:&attributes[0]
                                length:attributes.size() * sizeof(attributes[0])];
  return [[LTAttributeData alloc] initWithData:data inFormatOfGPUStruct:self.gpuStruct];
}

- (NSDictionary<NSString *, LTTexture *> *)
    mappingAugmentedWithTexture:(LTTexture *)texture
    fromMapping:(NSDictionary<NSString *, LTTexture *> *)mapping {
  NSMutableDictionary<NSString *, LTTexture *> *mutableMapping = [mapping mutableCopy];
  mutableMapping[kLTQuadDrawerSamplerUniformTextureMap] = texture;
  return [mutableMapping copy];
}

/// Orthographic projection matrix to be used for rendering.
static const GLKMatrix4 kProjection = GLKMatrix4MakeOrtho(0, 1, 0, 1, -1, 1);

/// Orthographic projection matrix to be used when rendering to the default framebuffer. In this
/// case, a flipped projection matrix must be used in order to generate clockwise front-facing
/// triangles, as the test is performed on the projected coordinates.
static const GLKMatrix4 kDefaultFramebufferProjection = GLKMatrix4MakeOrtho(0, 1, 1, 0, -1, 1);

/// Mapping of required shader uniform names to default values.
static const NSDictionary<NSString *, NSValue *> *kDefaultUniforms = @{
  kLTQuadDrawerUniformProjection: $(kProjection)
};

/// Mapping of required shader uniform names to default values, for usage with default framebuffer.
static const NSDictionary<NSString *, NSValue *> *kDefaultUniformsForDefaultFramebuffer = @{
  kLTQuadDrawerUniformProjection: $(kDefaultFramebufferProjection)
};

- (NSDictionary<NSString *, NSValue *> *)
    uniformsFromUniforms:(NSDictionary<NSString *, NSValue *> *)uniforms {
  NSMutableDictionary<NSString *, NSValue *> *mutableUniforms =
      [LTGLContext currentContext].renderingToScreen ?
      [kDefaultUniformsForDefaultFramebuffer mutableCopy] : [kDefaultUniforms mutableCopy];
  [mutableUniforms addEntriesFromDictionary:uniforms];
  return [mutableUniforms copy];
}

@end
