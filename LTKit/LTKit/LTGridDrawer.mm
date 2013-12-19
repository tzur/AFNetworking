// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTGridDrawer.h"

#import "LTArrayBuffer.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTGPUStruct.h"
#import "LTLogger.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTGridDrawerVsh.h"
#import "LTShaderStorage+LTGridDrawerFsh.h"
#import "LTVertexArray.h"

/// Holds the position of each grid line vertex.
LTGPUStructMake(LTGridDrawerVertex,
                GLKVector2, position,
                GLKVector2, offset);

@interface LTGridDrawer ()

/// Program to use when drawing the rect.
@property (strong, nonatomic) LTProgram *program;

/// Context holding the geometry and program.
@property (strong, nonatomic) LTDrawingContext *context;

/// Size of the grid.
@property (nonatomic) CGSize size;

@end

@implementation LTGridDrawer

// Default grid drawer color.
static const GLKVector4 kDefaultColor = GLKVector4Make(1, 1, 1, 1);
// Default grid drawer opacity.
static const CGFloat kDefaultOpacity = 1.0;
// Default width of the grid.
static const CGFloat kDefaultWidth = 1.0;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (id)initWithSize:(CGSize)size {
  if (self = [super init]) {
    [self setDefaults];
    self.size = size;
    self.program = [self createProgram];
    self.context = [self createDrawingContext];
  }
  return self;
}

- (void)setDefaults {
  self.color = kDefaultColor;
  self.opacity = kDefaultOpacity;
  self.width = kDefaultWidth;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTShaderStorage LTGridDrawerVsh]
                                  fragmentSource:[LTShaderStorage LTGridDrawerFsh]];
}

- (LTDrawingContext *)createDrawingContext {
  LTAssert(self.program, @"Program must be initialized before creating the drawing context");
  LTVertexArray *vertexArray = [self createVertexArray];
  LTDrawingContext *context = [[LTDrawingContext alloc] initWithProgram:self.program
                                                            vertexArray:vertexArray
                                                       uniformToTexture:nil];
  return context;
}

- (LTVertexArray *)createVertexArray {
  LTArrayBuffer *arrayBuffer = [self createArrayBuffer];
  LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithAttributes:@[@"position", @"offset"]];
  LTVertexArrayElement *element = [self createVertexArrayElementWithArrayBuffer:arrayBuffer];
  [vertexArray addElement:element];
  
  return vertexArray;
}

- (LTVertexArrayElement *)createVertexArrayElementWithArrayBuffer:(LTArrayBuffer *)arrayBuffer {
  return [[LTVertexArrayElement alloc] initWithStructName:@"LTGridDrawerVertex"
                                              arrayBuffer:arrayBuffer
                                             attributeMap:@{@"position": @"position",
                                                            @"offset": @"offset"}];
}

- (LTArrayBuffer *)createArrayBuffer {
  std::vector<LTGridDrawerVertex> vLines = [self verticesForVerticalGridLines];
  std::vector<LTGridDrawerVertex> hLines = [self verticesForHorizontalGridLines];
  vLines.insert(vLines.cend(), hLines.cbegin(), hLines.cend());
  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                             usage:LTArrayBufferUsageStaticDraw];
  [arrayBuffer setData:[NSData dataWithBytesNoCopy:&vLines[0]
                                            length:vLines.size() * sizeof(LTGridDrawerVertex)
                                      freeWhenDone:NO]];
  return arrayBuffer;
}

/// Creates the vertices for the vertical grid lines according to the grid size.
/// Ideally, we would use two degenerate triangles for each grid line, and the vertex shader would
/// update their values according to the offset, pixel size, and width to create a rectangle with
/// the desired width.
/// However, since openGL automatically discards degenerate triangles a hack was necessary, adding
/// the offset to the position as well, with the vertex shader subtracting it before applying the
/// modelview and projection transformations.
- (std::vector<LTGridDrawerVertex>) verticesForVerticalGridLines {
  std::vector<LTGridDrawerVertex> vertexData;
  CGFloat gridSpacing = 1.0;
  GLfloat height = self.size.height;
  for (GLfloat x = 0; x <= self.size.width; x += gridSpacing) {
    LTGridDrawerVertex topLeft = {.position = {{x - 1, 0}}, .offset = {{-1, 0}}};
    LTGridDrawerVertex topRight = {.position = {{x + 1, 0}}, .offset = {{1, 0}}};
    LTGridDrawerVertex bottomLeft = {.position = {{x - 1, height}}, .offset = {{-1, 0}}};
    LTGridDrawerVertex bottomRight = {.position = {{x + 1, height}}, .offset = {{1, 0}}};
    vertexData.push_back(topLeft);
    vertexData.push_back(topRight);
    vertexData.push_back(bottomLeft);
    vertexData.push_back(topRight);
    vertexData.push_back(bottomRight);
    vertexData.push_back(bottomLeft);
  }
  return vertexData;
}

/// Creates the vertices for the horizontal grid lines according to the grid size. See comment above
/// (\c verticesForVerticalGridLines) for more details.
- (std::vector<LTGridDrawerVertex>) verticesForHorizontalGridLines {
  std::vector<LTGridDrawerVertex> vertexData;
  CGFloat gridSpacing = 1.0;
  GLfloat width = self.size.width;
  for (GLfloat y = 0; y <= self.size.height; y += gridSpacing) {
    LTGridDrawerVertex topLeft = {.position = {{0, y - 1}}, .offset = {{0, -1}}};
    LTGridDrawerVertex topRight = {.position = {{width, y - 1}}, .offset = {{0, -1}}};
    LTGridDrawerVertex bottomLeft = {.position = {{0, y + 1}}, .offset = {{0, 1}}};
    LTGridDrawerVertex bottomRight = {.position = {{width, y + 1}}, .offset = {{0, 1}}};
    vertexData.push_back(topLeft);
    vertexData.push_back(topRight);
    vertexData.push_back(bottomLeft);
    vertexData.push_back(topRight);
    vertexData.push_back(bottomRight);
    vertexData.push_back(bottomLeft);
  }
  return vertexData;
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)drawSubGridInRegion:(CGRect)region inFrameBuffer:(LTFbo *)fbo {
  [fbo bindAndExecute:^{
    [self drawSubGridInRegion:region inFrameBufferWithSize:fbo.size];
  }];
}

- (void)drawSubGridInRegion:(CGRect)region inFrameBufferWithSize:(CGSize)size {
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0.0, size.width, 0.0, size.height, -1.0, 1.0);
  GLKMatrix4 modelview = [self modelviewForGridRegion:region targetSize:size];
  
  self.program[@"width"] = @(self.width);
  self.program[@"color"] = [NSValue valueWithGLKVector4:self.color * self.opacity];
  self.program[@"modelview"] = [NSValue valueWithGLKMatrix4:modelview];
  self.program[@"projection"] = [NSValue valueWithGLKMatrix4:projection];
  self.program[@"pixelSize"] =
      [NSValue valueWithGLKVector2:GLKVector2Make(2 / size.width, 2 / size.height)];

  // TODO:(amit) update to LTGLContext when ready.
  glEnable(GL_BLEND);
  glBlendEquation(GL_FUNC_ADD);
  glBlendFuncSeparate(GL_ONE, GL_ONE_MINUS_SRC_ALPHA, GL_ONE_MINUS_DST_ALPHA, GL_ONE);
  [self.context drawWithMode:LTDrawingContextDrawModeTriangles];
  glDisable(GL_BLEND);
}

/// Returns the modelview matrix according to the desired region and target framebuffer size.
- (GLKMatrix4)modelviewForGridRegion:(CGRect)region targetSize:(CGSize)targetSize {
  CGFloat scaleX = targetSize.width / region.size.width;
  CGFloat scaleY = targetSize.height / region.size.height;
  GLKMatrix4 modelview = GLKMatrix4MakeScale(scaleX, scaleY, 1.0);
  return GLKMatrix4Translate(modelview, -region.origin.x, -region.origin.y, 0.0);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setOpacity:(CGFloat)opacity {
  _opacity = MIN(MAX(opacity, 0), 1);
}

@end
