// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCropDrawer.h"

#import <array>

#import "LTArrayBuffer.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGPUStruct.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture.h"
#import "LTVertexArray.h"

/// Holds the position and texture coordinate of each of the rect's corners.
LTGPUStructMake(LTCropDrawerVertex,
                LTVector2, position,
                LTVector2, texcoord);

@interface LTCropDrawer ()

/// Texture used as input for the drawer.
@property (strong, nonatomic) LTTexture *texture;

/// Program to use when drawing the rect.
@property (strong, nonatomic) LTProgram *program;

/// Context holding the geometry and program.
@property (strong, nonatomic) LTDrawingContext *context;

/// Array buffer holding the geometry.
@property (strong, nonatomic) LTArrayBuffer *arrayBuffer;

@end

@implementation LTCropDrawer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithTexture:(LTTexture *)texture {
  LTParameterAssert(texture);
  if (self = [super init]) {
    self.texture = texture;
    [self createProgram];
    [self createDrawingContext];
  }
  return self;
}

- (void)createProgram {
  self.program = [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                          fragmentSource:[LTPassthroughShaderFsh source]];
  self.program[[LTPassthroughShaderVsh modelview]] = $(GLKMatrix4Identity);
  self.program[[LTPassthroughShaderVsh texture]] = $(GLKMatrix3Identity);
}

- (void)createDrawingContext {
  LTVertexArray *vertexArray = [self createVertexArray];
  NSDictionary *textures = @{[LTPassthroughShaderFsh sourceTexture]: self.texture};
  self.context = [[LTDrawingContext alloc] initWithProgram:self.program
                                               vertexArray:vertexArray
                                          uniformToTexture:textures];
}

- (LTVertexArray *)createVertexArray {
  self.arrayBuffer = [self createArrayBuffer];
  
  LTVertexArray *vertexArray = [[LTVertexArray alloc]
                                initWithAttributes:@[@"position", @"texcoord"]];
  LTVertexArrayElement *element = [self createVertexArrayElementWithArrayBuffer:self.arrayBuffer];
  [vertexArray addElement:element];
  return vertexArray;
}

- (LTVertexArrayElement *)createVertexArrayElementWithArrayBuffer:(LTArrayBuffer *)arrayBuffer {
  return [[LTVertexArrayElement alloc]
          initWithStructName:@"LTCropDrawerVertex"
          arrayBuffer:arrayBuffer
          attributeMap:@{@"position": @"position",
                         @"texcoord": @"texcoord"}];
}

- (LTArrayBuffer *)createArrayBuffer {
  return [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                       usage:LTArrayBufferUsageStreamDraw];
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)drawRect:(LTCropDrawerRect)targetRect inFramebuffer:(LTFbo *)fbo
        fromRect:(LTCropDrawerRect)sourceRect {
  [fbo bindAndDraw:^{
    [self drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
  }];
}

- (void)drawRect:(LTCropDrawerRect)targetRect inFramebufferWithSize:(CGSize)size
        fromRect:(LTCropDrawerRect)sourceRect {
  // In case of a screen framebuffer, we're using a flipped projection matrix so the original order
  // of the vertices will generate a back-faced polygon, as the test is performed on the projected
  // coordinates. Therefore we use the clockwise front facing polygon mode when drawing to a
  // \c LTScreenFbo.
  BOOL screenTarget = [LTGLContext currentContext].renderingToScreen;
  [self updateArrayBufferWithTargetRect:targetRect sourceRect:sourceRect];
  self.program[[LTPassthroughShaderVsh projection]] = screenTarget ?
      $(GLKMatrix4MakeOrtho(0, size.width, size.height, 0, -1, 1)) :
      $(GLKMatrix4MakeOrtho(0, size.width, 0, size.height, -1, 1));
  
  LTGLContext *context = [LTGLContext currentContext];
  [context executeAndPreserveState:^{
    context.faceCullingEnabled = NO;
    context.clockwiseFrontFacingPolygons = screenTarget;
    [self.context drawWithMode:LTDrawingContextDrawModeTriangles];
  }];
}

- (void)updateArrayBufferWithTargetRect:(LTCropDrawerRect)targetRect
                             sourceRect:(LTCropDrawerRect)sourceRect {
  LTVector2 v0 = targetRect.topLeft;
  LTVector2 v1 = targetRect.topRight;
  LTVector2 v2 = targetRect.bottomRight;
  LTVector2 v3 = targetRect.bottomLeft;
  
  sourceRect /= LTVector2(self.texture.size);
  LTVector2 t0 = sourceRect.topLeft;
  LTVector2 t1 = sourceRect.topRight;
  LTVector2 t2 = sourceRect.bottomRight;
  LTVector2 t3 = sourceRect.bottomLeft;

  std::array<LTCropDrawerVertex, 6> vertices{{
    {.position = v0, .texcoord = t0},
    {.position = v1, .texcoord = t1},
    {.position = v2, .texcoord = t2},
    {.position = v2, .texcoord = t2},
    {.position = v3, .texcoord = t3},
    {.position = v0, .texcoord = t0}
  }};

  NSData *data = [NSData dataWithBytesNoCopy:vertices.data()
                                      length:vertices.size() * sizeof(vertices[0]) freeWhenDone:NO];
  [self.arrayBuffer setData:data];
}

@end
