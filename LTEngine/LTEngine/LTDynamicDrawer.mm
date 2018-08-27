// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTDynamicDrawer.h"

#import "LTArrayBuffer.h"
#import "LTAttributeData.h"
#import "LTDrawingContext.h"
#import "LTGLContext.h"
#import "LTGPUStruct.h"
#import "LTIndicesData.h"
#import "LTProgram.h"
#import "LTVertexArray.h"

@interface LTDynamicDrawer ()

/// Ordered collection of array buffers each of which contains the data of a single attribute.
@property (readonly, nonatomic) NSArray<LTArrayBuffer *> *arrayBuffers;

/// Context holding geometry attibutes and program.
@property (readonly, nonatomic) LTDrawingContext *context;

/// Mapping of uniform names to values, cached for refraining from unnecessary interaction with
/// OpenGL.
@property (readonly, nonatomic) NSMutableDictionary<NSString *, NSValue *> *cachedUniforms;

/// Maximum number of uniform names allowed to be cached at any given time.
@property (readonly, nonatomic) NSUInteger maximumNumberOfCachedUniforms;

/// Array buffer for storing indices which are used for drawing with the
/// \c drawWithAttributeData:indices:samplerUniformsToTextures:uniforms method.
@property (readonly, nonatomic) LTArrayBuffer *indicesArrayBuffer;

/// Object holding most recently used indices.
@property (strong, nonatomic) LTIndicesData *cachedIndices;

/// Indices array for storing mesh indices which are used for drawing with the
/// \c drawWithAttributeData:indices:samplerUniformsToTextures:uniforms method. Contains
/// \c indicesArrayBuffer as its \c arrayBuffer.
@property (strong, nonatomic) LTIndicesArray *indicesArray;

@end

@implementation LTDynamicDrawer

@synthesize maximumNumberOfCachedUniforms = _maximumNumberOfCachedUniforms;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                          gpuStructs:(NSOrderedSet<LTGPUStruct *> *)gpuStructs {
  if (self = [super init]) {
    [self validateGPUStructs:gpuStructs];
    _gpuStructs = gpuStructs;
    _arrayBuffers = [self buffers];
    _context = [self drawingContextWithVertexSource:vertexSource fragmentSource:fragmentSource];
    _cachedUniforms = [NSMutableDictionary dictionary];
    _indicesArrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeElement
                                                        usage:LTArrayBufferUsageDynamicDraw];
  }
  return self;
}

- (void)validateGPUStructs:(NSOrderedSet<LTGPUStruct *> *)gpuStructs {
  LTParameterAssert(gpuStructs.count, @"At least one GPU struct must be provided");

  NSMutableSet<NSString *> *allAttributes = [NSMutableSet set];

  for (LTGPUStruct *gpuStruct in gpuStructs) {
    NSSet<NSString *> *attributes = [NSSet setWithArray:gpuStruct.fields.allKeys];
    LTParameterAssert(![allAttributes intersectsSet:attributes],
                      @"GPU struct (%@) contains fields (%@) already encountered", gpuStruct,
                      gpuStruct.fields.allKeys);
    [allAttributes unionSet:attributes];
  }
}

- (NSMutableArray<LTArrayBuffer *> *)buffers {
  NSUInteger numberOfArrayBuffers = self.gpuStructs.count;

  NSMutableArray<LTArrayBuffer *> *arrayBuffers =
      [NSMutableArray arrayWithCapacity:numberOfArrayBuffers];

  for (NSUInteger i = 0; i < numberOfArrayBuffers; ++i) {
    [arrayBuffers addObject:[[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                          usage:LTArrayBufferUsageDynamicDraw]];
  }

  return arrayBuffers;
}

- (LTDrawingContext *)drawingContextWithVertexSource:(NSString *)vertexSource
                                      fragmentSource:(NSString *)fragmentSource {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:vertexSource
                                                fragmentSource:fragmentSource];

  LTVertexArray *vertexArray = [self newVertexArray];
  return [[LTDrawingContext alloc] initWithProgram:program vertexArray:vertexArray
                                  uniformToTexture:@{}];
}

- (LTVertexArray *)newVertexArray {
  NSMutableSet<LTVertexArrayElement *> *elements =
      [NSMutableSet setWithCapacity:self.gpuStructs.count];

  [self.gpuStructs enumerateObjectsUsingBlock:^(LTGPUStruct *gpuStruct, NSUInteger i, BOOL *) {
    NSDictionary<NSString *, NSString *> *attributeMap =
        [NSDictionary dictionaryWithObjects:gpuStruct.fields.allKeys
                                    forKeys:gpuStruct.fields.allKeys];
    [elements addObject:[[LTVertexArrayElement alloc] initWithStructName:gpuStruct.name
                                                             arrayBuffer:self.arrayBuffers[i]
                                                            attributeMap:attributeMap]];
  }];

  return [[LTVertexArray alloc] initWithElements:[elements copy]];
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)drawWithAttributeData:(NSArray<LTAttributeData *> *)attributeData
    samplerUniformsToTextures:(NSDictionary<NSString *, LTTexture *> *)samplerUniformsToTextures
                     uniforms:(NSDictionary<NSString *, NSValue *> *)uniforms {
  [self validateAttributeData:attributeData validateTriangularity:YES];
  [self updateWithAttributeData:attributeData samplerUniformsToTextures:samplerUniformsToTextures
                     andUniform:uniforms];
  [self.context drawWithMode:LTDrawingContextDrawModeTriangles];
}

- (void)validateAttributeData:(NSArray<LTAttributeData *> *)attributeData
        validateTriangularity:(BOOL)validateTriangularity {
  LTParameterAssert(self.gpuStructs.count == attributeData.count,
                    @"Number of GPU structs must be identical for each render pass");
  for (NSUInteger i = 0; i < self.gpuStructs.count; ++i) {
    LTAttributeData *data = attributeData[i];
    LTParameterAssert([self.gpuStructs[i] isEqual:data.gpuStruct]);
    if (validateTriangularity) {
      LTParameterAssert((data.data.length / data.gpuStruct.size) % 3 == 0,
                        @"Attribute data #%lu (length:%lu) does not provide data for triangular "
                        "geometry", (unsigned long)i, (unsigned long)data.data.length);
    }
  }
}

- (void)updateWithAttributeData:(NSArray<LTAttributeData *> *)attributeData
      samplerUniformsToTextures:(NSDictionary<NSString *, LTTexture *> *)samplerUniformsToTextures
                     andUniform:(NSDictionary<NSString *, NSValue *> *)uniforms {
  [self updateDrawingContextWithMapping:samplerUniformsToTextures];
  [self updateProgramWithUniforms:uniforms];
  [self updateArrayBufferWithAttributeData:attributeData];
}

- (void)drawWithAttributeData:(NSArray<LTAttributeData *> *)attributeData
                      indices:(LTIndicesData *)indices
    samplerUniformsToTextures:(NSDictionary<NSString *, LTTexture *> *)samplerUniformsToTextures
                     uniforms:(NSDictionary<NSString *, NSValue *> *)uniforms {
  LTParameterAssert(indices.count % 3 == 0, @"Indices data (length:%lu) does not provide data for "
                    "triangular geometry", (unsigned long)indices.count);
  [self validateAttributeData:attributeData validateTriangularity:NO];
  [self updateWithAttributeData:attributeData samplerUniformsToTextures:samplerUniformsToTextures
                     andUniform:uniforms];
  [self updateIndicesArrayWithIndices:indices];
  [self.context drawElements:self.indicesArray withMode:LTDrawingContextDrawModeTriangles];
}

- (void)updateIndicesArrayWithIndices:(LTIndicesData *)indices {
  if ([indices isEqual:self.cachedIndices]) {
    return;
  }

  self.cachedIndices = indices;
  [self.indicesArrayBuffer setData:indices.data];
  self.indicesArray = [[LTIndicesArray alloc] initWithType:indices.type
                                               arrayBuffer:self.indicesArrayBuffer];
}

#pragma mark -
#pragma mark Sampler uniform updating
#pragma mark -

- (void)updateDrawingContextWithMapping:(NSDictionary<NSString *, LTTexture *> *)mapping {
  [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *uniform, LTTexture *texture, BOOL *) {
    [self.context attachUniform:uniform toTexture:texture];
  }];
}
#pragma mark -
#pragma mark Uniform updating
#pragma mark -

- (void)updateProgramWithUniforms:(NSDictionary<NSString *, NSValue *> *)uniforms {
  [uniforms enumerateKeysAndObjectsUsingBlock:^(NSString *uniform, NSValue *value, BOOL *) {
    NSValue *cachedValue = [self cachedValueForValue:value uniform:uniform];
    if (![cachedValue isEqualToValue:value]) {
      [self.program setUniform:uniform withValue:value];
    }
  }];
}

- (nullable NSValue *)cachedValueForValue:(NSValue *)value uniform:(NSString *)uniform {
  NSValue *cachedValue = self.cachedUniforms[uniform];

  if ([cachedValue isEqualToValue:value]) {
    return cachedValue;
  }

  self.cachedUniforms[uniform] = value;
  if (self.cachedUniforms.count > self.maximumNumberOfCachedUniforms) {
    [self.cachedUniforms removeObjectForKey:self.cachedUniforms.allKeys.firstObject];
    LTAssert(self.cachedUniforms.count <= self.maximumNumberOfCachedUniforms,
             @"Number of cached uniforms (%lu) expected to not exceed maximum number of cached "
             "uniforms (%lu)", (unsigned long)self.cachedUniforms.count,
             (unsigned long)self.maximumNumberOfCachedUniforms);
  }

  return cachedValue;
}

#pragma mark -
#pragma mark Array buffer updating
#pragma mark -

- (void)updateArrayBufferWithAttributeData:(NSArray<LTAttributeData *> *)attributeData {
  [attributeData enumerateObjectsUsingBlock:^(LTAttributeData *data, NSUInteger i, BOOL *) {
      [self.arrayBuffers[i] setData:data.data];
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (LTProgram *)program {
  return self.context.program;
}

- (NSUInteger)maximumNumberOfCachedUniforms {
  if (!_maximumNumberOfCachedUniforms) {
    LTGLContext *context = [LTGLContext currentContext];
    LTAssert(context, @"No current OpenGL context set");
    return context.maxNumberOfVertexUniforms + context.maxNumberOfFragmentUniforms;
  }
  return _maximumNumberOfCachedUniforms;
}

- (NSString *)sourceIdentifier {
  return self.context.program.sourceIdentifier;
}

@end
