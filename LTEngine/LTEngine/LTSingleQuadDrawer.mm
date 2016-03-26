// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSingleQuadDrawer.h"

#import "LTArrayBuffer.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGPUStruct.h"
#import "LTProgram.h"
#import "LTQuad.h"
#import "LTQuadMapping.h"
#import "LTTexture.h"
#import "LTVertexArray.h"

/// Holds the position and texture coordinate of each of the quad's corners.
LTGPUStructMake(LTSingleQuadDrawerVertex,
                LTVector2, position,
                LTVector2, texcoord);

@interface LTTextureDrawer ()
@property (strong, nonatomic) LTDrawingContext *context;
@property (strong, nonatomic) LTProgram *program;
@property (strong, nonatomic) NSMutableDictionary *uniformToTexture;
@end

@implementation LTSingleQuadDrawer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (LTDrawingContext *)createDrawingContext {
  LTVertexArray *vertexArray = [self createVertexArray];

  return [[LTDrawingContext alloc] initWithProgram:self.program
                                       vertexArray:vertexArray
                                  uniformToTexture:self.uniformToTexture];
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
          initWithStructName:@"LTSingleQuadDrawerVertex"
          arrayBuffer:arrayBuffer
          attributeMap:@{@"position": @"position",
                         @"texcoord": @"texcoord"}];
}

- (LTArrayBuffer *)createArrayBuffer {
  std::vector<LTSingleQuadDrawerVertex> vertexData{
    {.position = LTVector2(0, 0), .texcoord = LTVector2(0, 0)},
    {.position = LTVector2(1, 0), .texcoord = LTVector2(1, 0)},
    {.position = LTVector2(0, 1), .texcoord = LTVector2(0, 1)},
    {.position = LTVector2(1, 1), .texcoord = LTVector2(1, 1)},
  };

  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                             usage:LTArrayBufferUsageStaticDraw];
  NSData *data = [NSData dataWithBytesNoCopy:&vertexData[0]
                                      length:vertexData.size() * sizeof(LTSingleQuadDrawerVertex)
                                freeWhenDone:NO];
  [arrayBuffer setData:data];
  return arrayBuffer;
}

#pragma mark -
#pragma mark Drawing (CGRect)
#pragma mark -

- (void)drawRect:(CGRect)targetRect inFramebuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect {
  LTQuad *targetQuad = [LTQuad quadFromRect:targetRect];
  LTQuad *sourceQuad = [LTQuad quadFromRect:sourceRect];
  [self drawQuad:targetQuad inFramebuffer:fbo fromQuad:sourceQuad];
}

- (void)drawRect:(CGRect)targetRect inFramebufferWithSize:(CGSize)size fromRect:(CGRect)sourceRect {
  LTQuad *targetQuad = [LTQuad quadFromRect:targetRect];
  LTQuad *sourceQuad = [LTQuad quadFromRect:sourceRect];
  [self drawQuad:targetQuad inFramebufferWithSize:size fromQuad:sourceQuad];
}

#pragma mark -
#pragma mark Drawing (LTQuad)
#pragma mark -

- (void)framebufferWithSize:(CGSize)size drawBlock:(LTVoidBlock)block {
  LTParameterAssert(block);

  // In case of a screen framebuffer, we're using a flipped projection matrix so the original order
  // of the vertices will generate a back-faced polygon, as the test is performed on the projected
  // coordinates. Therefore we use the clockwise front facing polygon mode when drawing to a
  // \c LTScreenFbo.
  BOOL screenTarget = [LTGLContext currentContext].renderingToScreen;
  self.program[@"projection"] = screenTarget ?
      $(GLKMatrix4MakeOrtho(0, size.width, size.height, 0, -1, 1)) :
      $(GLKMatrix4MakeOrtho(0, size.width, 0, size.height, -1, 1));

  [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
    context.clockwiseFrontFacingPolygons = screenTarget;
    block();
  }];
}

- (void)drawQuad:(LTQuad *)targetQuad inFramebuffer:(LTFbo *)fbo fromQuad:(LTQuad *)sourceQuad {
  [fbo bindAndDraw:^{
    [self drawQuad:targetQuad inFramebufferWithSize:fbo.size fromQuad:sourceQuad];
  }];
}

- (void)drawQuad:(LTQuad *)targetQuad inFramebufferWithSize:(CGSize)size
        fromQuad:(LTQuad *)sourceQuad {
  [self framebufferWithSize:size drawBlock:^{
    GLKMatrix4 modelview = LTMatrix4ForQuad(targetQuad);
    self.program[@"modelview"] = $(modelview);

    CGSize textureSize = [(LTTexture *)self.uniformToTexture[kLTSourceTextureUniform] size];
    GLKMatrix3 texture = LTTextureMatrix3ForQuad(sourceQuad, textureSize);
    self.program[@"texture"] = $(texture);

    [self.context drawWithMode:LTDrawingContextDrawModeTriangleStrip];
  }];
}

#pragma mark -
#pragma mark Drawing (NSArray)
#pragma mark -

- (void)drawQuads:(NSArray *)targetQuads inFramebuffer:(LTFbo *)fbo
        fromQuads:(NSArray *)sourceQuads {
  LTParameterAssert(targetQuads.count == sourceQuads.count);
  // TODO:(Rouven) Implement LTMultiQuadDrawer.
  LogDebug(@"Using LTSingleQuadDrawer for drawing an array of quads, consider implementing "
           "LTMultiQuadDrawer instead for improved performance, as it uses a single draw call for "
           "drawing all the quadrilaterals");
  [fbo bindAndDraw:^{
    for (NSUInteger i = 0; i < targetQuads.count; ++i) {
      [self drawQuad:targetQuads[i] inFramebufferWithSize:fbo.size fromQuad:sourceQuads[i]];
    }
  }];
}

@end
