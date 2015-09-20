// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTMeshDrawer.h"

#import "LTArrayBuffer.h"
#import "LTCGExtensions.h"
#import "LTDevice.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGPUStruct.h"
#import "LTIndicesArray.h"
#import "LTProgram.h"
#import "LTProgramFactory.h"
#import "LTRectMapping.h"
#import "LTShaderStorage+LTMeshDrawerVsh.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTTexture.h"
#import "LTVertexArray.h"

LTGPUStructMake(LTMeshDrawerVertex,
                LTVector2, position,
                LTVector2, texcoord);

@interface LTTextureDrawer ()

/// Program to use when drawing the rect.
@property (strong, nonatomic) LTProgram *program;

/// Context holding the geometry and program.
@property (strong, nonatomic) LTDrawingContext *context;

/// Mapping between uniform name and its attached texture.
@property (strong, nonatomic) NSMutableDictionary *uniformToTexture;

@end

@interface LTMeshDrawer ()

/// Mesh displacement texture used to alter the mesh vertices.
@property (readonly, nonatomic) LTTexture *meshTexture;

/// Elements buffer containing the indices used for drawing the mesh (triangles).
@property (strong, nonatomic) LTIndicesArray *indicesArray;

/// Elements buffer containing the indices used for drawing the mesh wireframe (lines).
@property (strong, nonatomic) LTIndicesArray *wireframeIndicesArray;

@end

@implementation LTMeshDrawer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                          meshTexture:(LTTexture *)meshTexture {
  return [self initWithSourceTexture:sourceTexture meshTexture:meshTexture
                      fragmentSource:[LTPassthroughShaderFsh source]];
}

- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                          meshTexture:(LTTexture *)meshTexture
                       fragmentSource:(NSString *)fragmentSource {
  LTParameterAssert(meshTexture.channels > 1);
  LTParameterAssert(meshTexture.precision == LTTexturePrecisionHalfFloat);
  if (self = [super initWithProgram:[self createProgramWithFragmentSource:fragmentSource]
                      sourceTexture:sourceTexture
                  auxiliaryTextures:@{[LTMeshDrawerVsh meshTexture]: meshTexture}]) {
    self.indicesArray = [self createIndicesArray];
  }
  return self;
}

- (LTProgram *)createProgramWithFragmentSource:(NSString *)fragmentSource {
  LTBasicProgramFactory *factory = [[LTBasicProgramFactory alloc] init];
  return [factory programWithVertexSource:[LTMeshDrawerVsh source]
                           fragmentSource:fragmentSource];
}

- (LTDrawingContext *)createDrawingContext {
  LTVertexArray *vertexArray = [self createVertexArray];
  LTDrawingContext *context = [[LTDrawingContext alloc] initWithProgram:self.program
                                                            vertexArray:vertexArray
                                                       uniformToTexture:self.uniformToTexture];
  return context;
}

- (LTVertexArray *)createVertexArray {
  LTArrayBuffer *arrayBuffer = [self createArrayBuffer];
  LTVertexArray *vertexArray = [[LTVertexArray alloc]
                                initWithAttributes:@[@"position", @"texcoord"]];
  LTVertexArrayElement *element = [self createVertexArrayElementWithArrayBuffer:arrayBuffer];
  [vertexArray addElement:element];
  
  return vertexArray;
}

- (LTVertexArrayElement *)createVertexArrayElementWithArrayBuffer:(LTArrayBuffer *)arrayBuffer {
  return [[LTVertexArrayElement alloc]
          initWithStructName:@"LTMeshDrawerVertex"
          arrayBuffer:arrayBuffer
          attributeMap:@{@"position": @"position",
                         @"texcoord": @"texcoord"}];
}

- (LTArrayBuffer *)createArrayBuffer {
  NSUInteger cols = self.meshTexture.size.width;
  NSUInteger rows = self.meshTexture.size.height;
  std::vector<LTMeshDrawerVertex> vertexData(rows * cols);
  CGSize size = CGSizeMake(cols - 1, rows - 1);
  for (NSUInteger i = 0, idx = 0; i < rows; ++i) {
    for (NSUInteger j = 0; j < cols; ++j, ++idx) {
      LTVector2 vertex(j / size.width, i / size.height);
      vertexData[idx] = {.position = vertex, .texcoord = vertex};
    }
  }
  
  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                             usage:LTArrayBufferUsageStaticDraw];
  NSData *data = [NSData dataWithBytesNoCopy:&vertexData[0]
                                      length:vertexData.size() * sizeof(LTMeshDrawerVertex)
                                freeWhenDone:NO];
  [arrayBuffer setData:data];
  return arrayBuffer;
}

- (LTIndicesArray *)createIndicesArray {
  GLuint cols = self.meshTexture.size.width;
  GLuint rows = self.meshTexture.size.height;
  std::vector<GLuint> indicesData((rows - 1) * (cols - 1) * 6);
  for (GLuint i = 0, idx = 0; i < rows - 1; ++i) {
    for (GLuint j = 0; j < cols - 1; ++j) {
      GLuint topLeft = i * cols + j;
      GLuint topRight = i * cols + j + 1;
      GLuint bottomLeft = (i + 1) * cols + j;
      GLuint bottomRight = (i + 1) * cols + j + 1;
      indicesData[idx++] = topLeft;
      indicesData[idx++] = topRight;
      indicesData[idx++] = bottomRight;
      indicesData[idx++] = bottomRight;
      indicesData[idx++] = bottomLeft;
      indicesData[idx++] = topLeft;
    }
  }
  
  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeElement
                                                             usage:LTArrayBufferUsageStaticDraw];
  NSData *data = [NSData dataWithBytesNoCopy:&indicesData[0]
                                      length:indicesData.size() * sizeof(GLuint)
                                freeWhenDone:NO];
  [arrayBuffer setData:data];
  return [[LTIndicesArray alloc] initWithType:LTIndicesBufferTypeInteger arrayBuffer:arrayBuffer];
}

- (LTIndicesArray *)createWireframeIndicesArray {
  GLuint cols = self.meshTexture.size.width;
  GLuint rows = self.meshTexture.size.height;
  std::vector<GLuint> indicesData((rows - 1) * (cols - 1) * 8);
  for (GLuint i = 0, idx = 0; i < rows - 1; ++i) {
    for (GLuint j = 0; j < cols - 1; ++j) {
      GLuint topLeft = i * cols + j;
      GLuint topRight = i * cols + j + 1;
      GLuint bottomLeft = (i + 1) * cols + j;
      GLuint bottomRight = (i + 1) * cols + j + 1;
      indicesData[idx++] = topLeft;
      indicesData[idx++] = topRight;
      indicesData[idx++] = topRight;
      indicesData[idx++] = bottomRight;
      indicesData[idx++] = bottomRight;
      indicesData[idx++] = bottomLeft;
      indicesData[idx++] = bottomLeft;
      indicesData[idx++] = topLeft;
    }
  }
  
  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeElement
                                                             usage:LTArrayBufferUsageStaticDraw];
  NSData *data = [NSData dataWithBytesNoCopy:&indicesData[0]
                                      length:indicesData.size() * sizeof(GLuint)
                                freeWhenDone:NO];
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
    self.program[[LTMeshDrawerVsh modelview]] = $(modelview);
    
    CGSize textureSize = [(LTTexture *)self.uniformToTexture[kLTSourceTextureUniform] size];
    GLKMatrix3 texture = LTTextureMatrix3ForRect(sourceRect, textureSize);
    self.program[[LTMeshDrawerVsh texture]] = $(texture);

    LTVector2 scale((targetRect.size / size) / (sourceRect.size / textureSize));
    if ([LTGLContext currentContext].renderingToScreen) {
      scale.y *= -1;
    }
    self.program[[LTMeshDrawerVsh meshDisplacementScale]] = $(scale);
    
    [self.meshTexture executeAndPreserveParameters:^{
      self.meshTexture.magFilterInterpolation = LTTextureInterpolationNearest;
      self.meshTexture.minFilterInterpolation = LTTextureInterpolationNearest;
      if (self.drawWireframe) {
        [self.context drawElements:self.wireframeIndicesArray
                          withMode:LTDrawingContextDrawModeLines];
      } else {
        [self.context drawElements:self.indicesArray withMode:LTDrawingContextDrawModeTriangles];
      }
    }];
  }];
}

- (void)framebufferWithSize:(CGSize)size drawBlock:(LTVoidBlock)block {
  LTParameterAssert(block);
  
  // In case of a screen framebuffer, we're using a flipped projection matrix so the original order
  // of the vertices will generate a back-faced polygon, as the test is performed on the projected
  // coordinates. Therefore we use the clockwise front facying polygon mode when drawing to a
  // \c LTScreenFbo.
  BOOL screenTarget = [LTGLContext currentContext].renderingToScreen;
  self.program[[LTMeshDrawerVsh projection]] = screenTarget ?
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

- (LTTexture *)meshTexture {
  return self.uniformToTexture[[LTMeshDrawerVsh meshTexture]];
}

- (CGRect)meshRect {
  return CGRectFromSize(self.meshTexture.size);
}

- (LTIndicesArray *)wireframeIndicesArray {
  if (!_wireframeIndicesArray) {
    _wireframeIndicesArray = [self createWireframeIndicesArray];
  }
  return _wireframeIndicesArray;
}

@end
