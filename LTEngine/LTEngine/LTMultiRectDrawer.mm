// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTMultiRectDrawer.h"

#import "LTArrayBuffer.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTGPUStruct.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"
#import "LTVertexArray.h"

/// Holds the position and texture coordinate of each of the rect's corners. Notice that the
/// position attribute is a \c LTVector3, meaning the z coordinate is set and passed to the shader.
/// This allows some GPUs to optimize the drawing of overlapping rectangles, and drawing only the
/// top one.
LTGPUStructMake(LTMultiRectDrawerVertex,
                LTVector3, position,
                LTVector2, texcoord);

@interface LTTextureDrawer ()
@property (strong, nonatomic) LTProgram *program;
@property (strong, nonatomic) LTDrawingContext *context;
@property (strong, nonatomic) NSMutableDictionary *uniformToTexture;
@end

@interface LTMultiRectDrawer ()

/// Array buffer holding the geometry.
@property (strong, nonatomic) LTArrayBuffer *arrayBuffer;

@end

@implementation LTMultiRectDrawer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (LTDrawingContext *)createDrawingContext {
  LTVertexArray *vertexArray = [self createVertexArray];
  
  LTDrawingContext *context = [[LTDrawingContext alloc] initWithProgram:self.program
                                                            vertexArray:vertexArray
                                                       uniformToTexture:self.uniformToTexture];
  return context;
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
          initWithStructName:@"LTMultiRectDrawerVertex"
          arrayBuffer:arrayBuffer
          attributeMap:@{@"position": @"position",
                         @"texcoord": @"texcoord"}];
}

- (LTArrayBuffer *)createArrayBuffer {
  return [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                       usage:LTArrayBufferUsageStreamDraw];
}

#pragma mark -
#pragma mark Drawing (NSArray)
#pragma mark -

- (void)drawRotatedRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo
        fromRotatedRects:(NSArray *)sourceRects {
  [fbo bindAndDraw:^{
    [self drawRotatedRects:targetRects inFramebufferWithSize:fbo.size fromRotatedRects:sourceRects];
  }];
}

- (void)drawRotatedRects:(NSArray *)targetRects inFramebufferWithSize:(CGSize)size
        fromRotatedRects:(NSArray *)sourceRects {
  LTParameterAssert(targetRects.count == sourceRects.count);
  if (!targetRects.count) {
    return;
  }
  
  // In case of a screen framebuffer, we're using a flipped projection matrix so the original order
  // of the vertices will generate a back-faced polygon, as the test is performed on the projected
  // coordinates. Therefore we use the clockwise front facying polygon mode when drawing to a
  // \c LTScreenFbo.
  BOOL screenTarget = [LTGLContext currentContext].renderingToScreen;
  [self updateArrayBufferWithTargetRects:targetRects sourceRects:sourceRects];
  self.program[@"modelview"] = $(GLKMatrix4Identity);
  self.program[@"texture"] = $(GLKMatrix3Identity);
  self.program[@"projection"] = screenTarget ?
      $(GLKMatrix4MakeOrtho(0, size.width, size.height, 0, -1, 1)) :
      $(GLKMatrix4MakeOrtho(0, size.width, 0, size.height, -1, 1));
  
  [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
    context.clockwiseFrontFacingPolygons = screenTarget;
    [self.context drawWithMode:LTDrawingContextDrawModeTriangles];
  }];
}

- (void)updateArrayBufferWithTargetRects:(NSArray *)targetRects sourceRects:(NSArray *)sourceRects {
  LTParameterAssert(targetRects.count);

  CGSize sourceSize = [(LTTexture *)self.uniformToTexture[kLTSourceTextureUniform] size];
  std::vector<LTMultiRectDrawerVertex> triangles;
  CGFloat z = 0;
  for (NSUInteger i = 0; i < targetRects.count; ++i) {
    [self addTrianglesTo:&triangles withZCoordinate:z fromTargetRect:targetRects[i]
              sourceRect:sourceRects[i] usingSourceSize:sourceSize];
    z += 1.0 / targetRects.count;
  }
  NSData *data = [NSData dataWithBytesNoCopy:&triangles[0]
                                      length:triangles.size() * sizeof(LTMultiRectDrawerVertex)
                                freeWhenDone:NO];
  [self.arrayBuffer setData:data];
}

- (void)addTrianglesTo:(std::vector<LTMultiRectDrawerVertex> *)triangles withZCoordinate:(CGFloat)z
        fromTargetRect:(LTRotatedRect *)targetRect sourceRect:(LTRotatedRect *)sourceRect
       usingSourceSize:(CGSize)sourceSize {
  CGPoint v0 = targetRect.v0;
  CGPoint v1 = targetRect.v1;
  CGPoint v2 = targetRect.v2;
  CGPoint v3 = targetRect.v3;
  
  CGPoint t0 = sourceRect.v0 / sourceSize;
  CGPoint t1 = sourceRect.v1 / sourceSize;
  CGPoint t2 = sourceRect.v2 / sourceSize;
  CGPoint t3 = sourceRect.v3 / sourceSize;
  
  triangles->push_back({.position = LTVector3(v0.x, v0.y, z),
                        .texcoord = LTVector2(t0.x, t0.y)});
  triangles->push_back({.position = LTVector3(v1.x, v1.y, z),
                        .texcoord = LTVector2(t1.x, t1.y)});
  triangles->push_back({.position = LTVector3(v2.x, v2.y, z),
                        .texcoord = LTVector2(t2.x, t2.y)});
  triangles->push_back({.position = LTVector3(v2.x, v2.y, z),
                        .texcoord = LTVector2(t2.x, t2.y)});
  triangles->push_back({.position = LTVector3(v3.x, v3.y, z),
                        .texcoord = LTVector2(t3.x, t3.y)});
  triangles->push_back({.position = LTVector3(v0.x, v0.y, z),
                        .texcoord = LTVector2(t0.x, t0.y)});
}

#pragma mark -
#pragma mark Drawing (Single Rect)
#pragma mark -

- (void)drawRect:(CGRect)targetRect inFramebufferWithSize:(CGSize)size fromRect:(CGRect)sourceRect {
  LogWarning(@"Using LTMultiRectDrawer for drawing a single rect, "
             "consider using LTSingleRectDrawer instead for improved performance, as it uses a "
             "static geometry for drawing");
  [self drawRotatedRects:@[[LTRotatedRect rect:targetRect]] inFramebufferWithSize:size
        fromRotatedRects:@[[LTRotatedRect rect:sourceRect]]];
}

@end
