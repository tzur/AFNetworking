// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTCircularPatchDrawer.h"

#import "LTArrayBuffer.h"
#import "LTCircularMeshModel.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTIndicesArray.h"
#import "LTProgram.h"
#import "LTProgramFactory.h"
#import "LTRectMapping.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTCircularPatchVsh.h"
#import "LTShaderStorage+LTCircularPatchFsh.h"
#import "LTVertexArray.h"

/// Struct containing vertex position and texcoord.
LTGPUStructMake(LTCircularPatchDrawerVertex,
                LTVector2, position,
                LTVector2, texcoord);

LTGPUStructMake(LTCircularPatchDrawerColor,
                LTVector4, color);

/// Vector containing vertices position and texcoord values.
typedef std::vector<LTCircularPatchDrawerVertex> LTCircularPatchDrawerVertices;

/// Vector containing vertices color values.
typedef std::vector<LTCircularPatchDrawerColor> LTCircularPatchDrawerColors;

@interface LTTextureDrawer ()

/// Program to use when drawing the rect.
@property (strong, nonatomic) LTProgram *program;

/// Context holding the geometry and program.
@property (strong, nonatomic) LTDrawingContext *context;

/// Mapping between uniform name and its attached texture.
@property (strong, nonatomic) NSMutableDictionary *uniformToTexture;

@end

@interface LTCircularPatchDrawer ()

/// Circular mesh model holding the normalized vertices positions. The model is lazily instantiated
/// as it is called indirectly by \c initWithProgram:sourceTexture: initializer of the super of this
/// class.
@property (strong, readwrite, nonatomic) LTCircularMeshModel *circularMeshModel;

/// Elements buffer containing the indices used for drawing the mesh (triangles).
@property (strong, nonatomic) LTIndicesArray *indicesArray;

/// Array buffer containing membrane color data per vertex.
@property (strong, nonatomic) LTArrayBuffer *membraneColorArrayBuffer;

@end

@implementation LTCircularPatchDrawer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithProgramFactory:(id<LTProgramFactory>)programFactory
                         sourceTexture:(LTTexture *)sourceTexture {
  LTParameterAssert(programFactory);

  if (self = [super initWithProgram:[self createProgramWithFactory:programFactory]
                      sourceTexture:sourceTexture]) {
    self.indicesArray = [self createIndicesArray];
    self[[LTCircularPatchFsh alpha]] = @(self.defaultAlpha);
    self.program[[LTCircularPatchFsh isCircularPatchModeHeal]] = @NO;
  }
  return self;
}

- (LTProgram *)createProgramWithFactory:(id<LTProgramFactory>)programFactory {
  return [programFactory programWithVertexSource:[LTCircularPatchVsh source]
                                  fragmentSource:[LTCircularPatchFsh source]];
}

- (LTDrawingContext *)createDrawingContext {
  LTVertexArray *vertexArray = [self createVertexArray];
  LTDrawingContext *context = [[LTDrawingContext alloc] initWithProgram:self.program
                                                            vertexArray:vertexArray
                                                       uniformToTexture:self.uniformToTexture];
  return context;
}

- (LTVertexArray *)createVertexArray {
  LTVertexArrayElement *vertexElement = [self createVertexArrayElement];
  LTVertexArrayElement *membraneColorElement = [self createMembraneColorArrayElement];
  NSArray *attributes =
      [vertexElement.attributeToField.allKeys
       arrayByAddingObjectsFromArray:membraneColorElement.attributeToField.allKeys];

  LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithAttributes:attributes];
  [vertexArray addElement:vertexElement];
  [vertexArray addElement:membraneColorElement];
  
  return vertexArray;
}

- (LTVertexArrayElement *)createVertexArrayElement {
  LTArrayBuffer *vertexArrayBuffer = [self createVertexArrayBuffer];
  return [[LTVertexArrayElement alloc] initWithStructName:@"LTCircularPatchDrawerVertex"
                                              arrayBuffer:vertexArrayBuffer
                                             attributeMap:@{@"position": @"position",
                                                            @"texcoord": @"texcoord"}];
}

- (LTVertexArrayElement *)createMembraneColorArrayElement {
  LTCircularPatchDrawerColors colorsForBuffer = [self defaultMembraneColors];
  [self updateMembraneColorArrayBufferWithColors:colorsForBuffer];
  return [[LTVertexArrayElement alloc] initWithStructName:@"LTCircularPatchDrawerColor"
                                              arrayBuffer:self.membraneColorArrayBuffer
                                             attributeMap:@{@"color": @"color"}];
}

- (LTCircularPatchDrawerColors)defaultMembraneColors {
  LTCircularPatchDrawerColor color({.color = LTVector4(0, 0, 0, 1)});
  return LTCircularPatchDrawerColors(self.circularMeshModel.numberOfVertices, color);
}

- (void)updateMembraneColorArrayBufferWithColors:(LTCircularPatchDrawerColors &)colors {
  NSUInteger length = colors.size() * sizeof(LTCircularPatchDrawerColor);
  NSData *data = [NSData dataWithBytesNoCopy:&colors[0] length:length freeWhenDone:NO];
  [self.membraneColorArrayBuffer setData:data];
}

- (LTArrayBuffer *)createVertexArrayBuffer {
  LTCircularPatchDrawerVertices vertexData(self.circularMeshModel.numberOfVertices);
  const LTVector2s meshVertices = self.circularMeshModel.vertices;
  for (LTCircularPatchDrawerVertices::size_type index = 0; index < meshVertices.size(); ++index) {
    LTVector2 vertex = meshVertices[index];
    LTVector2 normalizedPosition = LTVector2(vertex.x + 1, vertex.y + 1) / 2;
    vertexData[index] = {.position = normalizedPosition, .texcoord = normalizedPosition};
  }
  
  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                             usage:LTArrayBufferUsageStaticDraw];
  NSUInteger length = vertexData.size() * sizeof(LTCircularPatchDrawerVertex);
  [arrayBuffer setData:[NSData dataWithBytesNoCopy:&vertexData[0] length:length freeWhenDone:NO]];
  return arrayBuffer;
}

- (LTIndicesArray *)createIndicesArray {
  GLuints indices = self.circularMeshModel.indices;
  std::vector<GLuint> indicesData(indices.size());
  for (GLuints::size_type index = 0; index < indices.size(); ++index) {
    indicesData[index] = indices[index];
  }
  
  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeElement
                                                             usage:LTArrayBufferUsageStaticDraw];
  NSData *data = [NSData dataWithBytesNoCopy:&indicesData[0]
                                      length:(indicesData.size() * sizeof(GLuint)) freeWhenDone:NO];
  [arrayBuffer setData:data];
  return [[LTIndicesArray alloc] initWithType:LTIndicesBufferTypeInteger arrayBuffer:arrayBuffer];
}

#pragma mark -
#pragma mark Draw
#pragma mark -

- (void)drawRect:(CGRect)targetRect inFramebuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect {
  [fbo bindAndDraw:^{
    [self drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
  }];
}

- (void)drawRect:(CGRect)targetRect inFramebufferWithSize:(CGSize)size fromRect:(CGRect)sourceRect {
  [self framebufferWithSize:size drawBlock:^{
    GLKMatrix4 modelview = LTMatrix4ForRect(targetRect);
    self.program[[LTCircularPatchVsh modelview]] = $(modelview);
    GLKMatrix3 texture = GLKMatrix3Identity;
    self.program[[LTCircularPatchVsh texture]] = $(texture);
  
    CGSize textureSize = [(LTTexture *)self.uniformToTexture[kLTSourceTextureUniform] size];
    LTRotatedRect *rotatedRect = [LTRotatedRect rect:sourceRect withAngle:-self.rotation];
    GLKMatrix3 sourceModelview = LTTextureMatrix3ForRotatedRect(rotatedRect, textureSize);
    GLKMatrix3 targetModelview = LTTextureMatrix3ForRect(targetRect, textureSize);
    self.program[[LTCircularPatchVsh sourceModelview]] = $(sourceModelview);
    self.program[[LTCircularPatchVsh targetModelview]] = $(targetModelview);
    [self.context drawElements:self.indicesArray withMode:LTDrawingContextDrawModeTriangles];
  }];
}

- (void)framebufferWithSize:(CGSize)size drawBlock:(LTVoidBlock)block {
  LTParameterAssert(block);
  
  // In case of a screen framebuffer, we're using a flipped projection matrix so the original order
  // of the vertices will generate a back-faced polygon, as the test is performed on the projected
  // coordinates. Therefore we use the clockwise front facying polygon mode when drawing to a
  // \c LTScreenFbo.
  BOOL screenTarget = [LTGLContext currentContext].renderingToScreen;
  self.program[[LTCircularPatchVsh projection]] = screenTarget ?
      $(GLKMatrix4MakeOrtho(0, size.width, size.height, 0, -1, 1)) :
      $(GLKMatrix4MakeOrtho(0, size.width, 0, size.height, -1, 1));
  
  [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
    context.clockwiseFrontFacingPolygons = screenTarget;
    block();
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(CGFloat, rotation, Rotation, -CGFLOAT_MAX, CGFLOAT_MAX, 0);

LTPropertyWithoutSetter(CGFloat, alpha, Alpha, 0, 1, 1);
- (void)setAlpha:(CGFloat)alpha {
  [self _verifyAndSetAlpha:alpha];
  self.program[[LTCircularPatchFsh alpha]] = @(alpha);
}

- (LTCircularMeshModel *)circularMeshModel {
  if (!_circularMeshModel) {
    _circularMeshModel = [[LTCircularMeshModel alloc] init];
  }
  return _circularMeshModel;
}

- (void)setCircularPatchMode:(LTCircularPatchMode)circularPatchMode {
  _circularPatchMode = circularPatchMode;
  self.program[[LTCircularPatchFsh isCircularPatchModeHeal]] =
      @(circularPatchMode == LTCircularPatchModeHeal);
}

- (void)setMembraneColors:(const LTVector4s &)membraneColors {
  LTParameterAssert(membraneColors.size() == self.circularMeshModel.numberOfVertices);

  LTCircularPatchDrawerColors colorsForBuffer(self.circularMeshModel.numberOfVertices);
  for (LTCircularPatchDrawerColors::size_type index = 0; index < colorsForBuffer.size(); ++index) {
    colorsForBuffer[index] = {.color = membraneColors[index]};
  }
  [self updateMembraneColorArrayBufferWithColors:colorsForBuffer];
}

- (LTArrayBuffer *)membraneColorArrayBuffer {
  if (!_membraneColorArrayBuffer) {
    _membraneColorArrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                              usage:LTArrayBufferUsageDynamicDraw];
  }
  return _membraneColorArrayBuffer;
}

@end
