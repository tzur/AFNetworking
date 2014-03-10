// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTSingleRectDrawer.h"

#import "LTArrayBuffer.h"
#import "LTCGExtensions.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTGPUStruct.h"
#import "LTProgram.h"
#import "LTRectMapping.h"
#import "LTRotatedRect.h"
#import "LTVertexArray.h"

/// Holds the position and texture coordinate of each of the rect's corners.
LTGPUStructMake(LTSingleRectDrawerVertex,
                GLKVector2, position,
                GLKVector2, texcoord);

@interface LTTextureDrawer ()
@property (strong, nonatomic) LTProgram *program;
@property (strong, nonatomic) LTDrawingContext *context;
@property (strong, nonatomic) NSMutableDictionary *uniformToTexture;
@end

@interface LTSingleRectDrawer ()

/// Context holding the geometry and program.
@property (strong, nonatomic) LTDrawingContext *context;

@end

@implementation LTSingleRectDrawer

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
  LTArrayBuffer *arrayBuffer = [self createArrayBuffer];
  
  LTVertexArray *vertexArray = [[LTVertexArray alloc]
                                initWithAttributes:@[@"position", @"texcoord"]];
  LTVertexArrayElement *element = [self createVertexArrayElementWithArrayBuffer:arrayBuffer];
  [vertexArray addElement:element];
  
  return vertexArray;
}

- (LTVertexArrayElement *)createVertexArrayElementWithArrayBuffer:(LTArrayBuffer *)arrayBuffer {
  return [[LTVertexArrayElement alloc]
          initWithStructName:@"LTSingleRectDrawerVertex"
          arrayBuffer:arrayBuffer
          attributeMap:@{@"position": @"position",
                         @"texcoord": @"texcoord"}];
}

- (LTArrayBuffer *)createArrayBuffer {
  std::vector<LTSingleRectDrawerVertex> vertexData{
    {.position = {{0, 0}}, .texcoord = {{0, 0}}},
    {.position = {{1, 0}}, .texcoord = {{1, 0}}},
    {.position = {{0, 1}}, .texcoord = {{0, 1}}},
    {.position = {{1, 1}}, .texcoord = {{1, 1}}},
  };
  
  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                             usage:LTArrayBufferUsageStaticDraw];
  NSData *data = [NSData dataWithBytesNoCopy:&vertexData[0]
                                      length:vertexData.size() * sizeof(LTSingleRectDrawerVertex)
                                freeWhenDone:NO];
  [arrayBuffer setData:data];
  return arrayBuffer;
}

#pragma mark -
#pragma mark Drawing (CGRect)
#pragma mark -

- (void)drawRect:(CGRect)targetRect inFramebuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect {
  [fbo bindAndDraw:^{
    [self drawRect:targetRect inBoundFramebufferWithSize:fbo.size fromRect:sourceRect];
  }];
}

- (void)drawRect:(CGRect)targetRect inBoundFramebufferWithSize:(CGSize)size
        fromRect:(CGRect)sourceRect {
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, 0, size.height, -1, 1);
  self.program[@"projection"] = $(projection);
  [self drawRect:targetRect fromRect:sourceRect];
}

- (void)drawRect:(CGRect)targetRect inScreenFramebufferWithSize:(CGSize)size
        fromRect:(CGRect)sourceRect {
  // Since we're using a flipped projection matrix, the original order of vertices will generate
  // a back-faced polygon by default, as the test is performed on the projected coordinates.
  // therefore we use the clockwise front facing polygons mode while drawing.
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, size.height, 0, -1, 1);
  self.program[@"projection"] = $(projection);
  LTGLContext *context = [LTGLContext currentContext];
  [context executeAndPreserveState:^{
    context.clockwiseFrontFacingPolygons = YES;
    [self drawRect:targetRect fromRect:sourceRect];
  }];
}

- (void)drawRect:(CGRect)targetRect fromRect:(CGRect)sourceRect {
  GLKMatrix4 modelview = LTMatrix4ForRect(targetRect);
  self.program[@"modelview"] = $(modelview);

  CGSize textureSize = [(LTTexture *)self.uniformToTexture[kSourceTextureUniform] size];
  GLKMatrix3 texture = LTTextureMatrix3ForRect(sourceRect, textureSize);
  self.program[@"texture"] = $(texture);
  
  [self.context drawWithMode:LTDrawingContextDrawModeTriangleStrip];
}

#pragma mark -
#pragma mark Drawing (LTRotatedRect)
#pragma mark -

- (void)drawRotatedRect:(LTRotatedRect *)targetRect inFramebuffer:(LTFbo *)fbo
        fromRotatedRect:(LTRotatedRect *)sourceRect {
  [fbo bindAndDraw:^{
    [self drawRotatedRect:targetRect inBoundFramebufferWithSize:fbo.size
          fromRotatedRect:sourceRect];
  }];
}

- (void)drawRotatedRect:(LTRotatedRect *)targetRect inBoundFramebufferWithSize:(CGSize)size
        fromRotatedRect:(LTRotatedRect *)sourceRect {
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, 0, size.height, -1, 1);
  self.program[@"projection"] = $(projection);
  [self drawRotatedRect:targetRect fromRotatedRect:sourceRect];
}

- (void)drawRotatedRect:(LTRotatedRect *)targetRect inScreenFramebufferWithSize:(CGSize)size
        fromRotatedRect:(LTRotatedRect *)sourceRect {
  // Since we're using a flipped projection matrix, the original order of vertices will generate
  // a back-faced polygon by default, as the test is performed on the projected coordinates.
  // therefore we use the clockwise front facing polygons mode while drawing.
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, size.height, 0, -1, 1);
  self.program[@"projection"] = $(projection);
  LTGLContext *context = [LTGLContext currentContext];
  [context executeAndPreserveState:^{
    context.clockwiseFrontFacingPolygons = YES;
    [self drawRotatedRect:targetRect fromRotatedRect:sourceRect];
  }];
}

- (void)drawRotatedRect:(LTRotatedRect *)targetRect fromRotatedRect:(LTRotatedRect *)sourceRect {
  GLKMatrix4 modelview = LTMatrix4ForRotatedRect(targetRect);
  self.program[@"modelview"] = $(modelview);

  CGSize textureSize = [(LTTexture *)self.uniformToTexture[kSourceTextureUniform] size];
  GLKMatrix3 texture = LTTextureMatrix3ForRotatedRect(sourceRect, textureSize);
  self.program[@"texture"] = $(texture);
  
  [self.context drawWithMode:LTDrawingContextDrawModeTriangleStrip];
}

#pragma mark -
#pragma mark Drawing (NSArray)
#pragma mark -

- (void)drawRotatedRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo
        fromRotatedRects:(NSArray *)sourceRects {
  LTParameterAssert(targetRects.count == sourceRects.count);
  LogDebug(@"Using LTSingleRectDrawer for drawing an array of rects, "
           "consider using LTMultiRectDrawer instead for improved performance, as it uses a single "
           "draw call for drawing all the rectangles");
  [fbo bindAndDraw:^{
    for (NSUInteger i = 0; i < targetRects.count; ++i) {
      [self drawRotatedRect:targetRects[i] inBoundFramebufferWithSize:fbo.size
            fromRotatedRect:sourceRects[i]];
    }
  }];
}

@end
