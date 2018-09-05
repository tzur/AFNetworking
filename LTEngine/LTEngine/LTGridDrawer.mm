// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTGridDrawer.h"

#import "LTArrayBuffer.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTGPUStruct.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTGridDrawerFsh.h"
#import "LTShaderStorage+LTGridDrawerVsh.h"
#import "LTVertexArray.h"

/// Holds the position of each grid line vertex.
LTGPUStructMake(LTGridDrawerVertex,
                LTVector2, position,
                LTVector2, offset);

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
static const LTVector4 kDefaultColor = LTVector4(1, 1, 1, 1);
// Default grid drawer opacity.
static const CGFloat kDefaultOpacity = 1.0;
// Default width of the grid.
static const CGFloat kDefaultWidth = 1.0;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithSize:(CGSize)size {
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
  return [[LTProgram alloc] initWithVertexSource:[LTGridDrawerVsh source]
                                  fragmentSource:[LTGridDrawerFsh source]];
}

- (LTDrawingContext *)createDrawingContext {
  LTAssert(self.program, @"Program must be initialized before creating the drawing context");
  LTVertexArray *vertexArray = [self createVertexArray];
  LTDrawingContext *context = [[LTDrawingContext alloc] initWithProgram:self.program
                                                            vertexArray:vertexArray
                                                       uniformToTexture:@{}];
  return context;
}

- (LTVertexArray *)createVertexArray {
  LTArrayBuffer *arrayBuffer = [self createArrayBuffer];

  NSSet<LTVertexArrayElement *> *elements =
      [NSSet setWithObject:[self createVertexArrayElementWithArrayBuffer:arrayBuffer]];

  return [[LTVertexArray alloc] initWithElements:elements];
}

- (LTVertexArrayElement *)createVertexArrayElementWithArrayBuffer:(LTArrayBuffer *)arrayBuffer {
  return [[LTVertexArrayElement alloc] initWithStructName:@"LTGridDrawerVertex"
                                              arrayBuffer:arrayBuffer
                                             attributeMap:@{@"position": @"position",
                                                            @"offset": @"offset"}];
}

- (LTArrayBuffer *)createArrayBuffer {
  std::vector<LTGridDrawerVertex> lines = [self verticesForGridLines];
  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                             usage:LTArrayBufferUsageStaticDraw];
  [arrayBuffer setData:[NSData dataWithBytesNoCopy:&lines[0]
                                            length:lines.size() * sizeof(LTGridDrawerVertex)
                                      freeWhenDone:NO]];
  return arrayBuffer;
}

/// Creates the vertices for the vertical and horizontal grid lines according to the grid size.
/// Ideally, we would use two degenerate triangles for each grid line, and the vertex shader would
/// update their values according to the offset, pixel size, and width to create a rectangle with
/// the desired width.
///
/// However, since OpenGL automatically discards degenerate triangles, a hack was necessary, adding
/// the offset to the position as well, with the vertex shader subtracting it before applying the
/// modelview and projection transformations.
- (std::vector<LTGridDrawerVertex>)verticesForGridLines {
  // Spacing, in content pixels, between each grid.
  static const CGFloat kGridSpacing = 1;

  GLfloat height = self.size.height;
  GLfloat width = self.size.width;

  size_t widthRects = std::floor(width / kGridSpacing) + 1;
  size_t heightRects = std::floor(height / kGridSpacing) + 1;

  static const size_t kVerticesPerGridLine = 6;
  std::vector<LTGridDrawerVertex> vertexData;
  vertexData.reserve((widthRects + heightRects) * kVerticesPerGridLine);

  for (GLfloat x = 0; x <= width; x += kGridSpacing) {
    LTGridDrawerVertex topLeft = {
      .position = LTVector2(x - 1, 0), .offset = LTVector2(-1, 0)
    };
    LTGridDrawerVertex topRight = {
      .position = LTVector2(x + 1, 0), .offset = LTVector2(1, 0)
    };
    LTGridDrawerVertex bottomLeft = {
      .position = LTVector2(x - 1, height), .offset = LTVector2(-1, 0)
    };
    LTGridDrawerVertex bottomRight = {
      .position = LTVector2(x + 1, height), .offset = LTVector2(1, 0)
    };
    vertexData.push_back(topLeft);
    vertexData.push_back(topRight);
    vertexData.push_back(bottomLeft);
    vertexData.push_back(topRight);
    vertexData.push_back(bottomRight);
    vertexData.push_back(bottomLeft);
  }

  for (GLfloat y = 0; y <= height; y += kGridSpacing) {
    LTGridDrawerVertex topLeft = {
      .position = LTVector2(0, y - 1), .offset = LTVector2(0, -1)
    };
    LTGridDrawerVertex topRight = {
      .position = LTVector2(width, y - 1), .offset = LTVector2(0, -1)
    };
    LTGridDrawerVertex bottomLeft = {
      .position = LTVector2(0, y + 1), .offset = LTVector2(0, 1)
    };
    LTGridDrawerVertex bottomRight = {
      .position = LTVector2(width, y + 1), .offset = LTVector2(0, 1)
    };
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

- (void)drawSubGridInRegion:(CGRect)region inFramebuffer:(LTFbo *)fbo {
  [fbo bindAndDraw:^{
    [self drawSubGridInRegion:region inFramebufferWithSize:fbo.size];
  }];
}

- (void)drawSubGridInRegion:(CGRect)region inFramebufferWithSize:(CGSize)size {
  [self setUniformsForGridRegion:region framebufferSize:size];
  if ([LTGLContext currentContext].renderingToScreen) {
    [self setProjectionAndPixelSizeForScreenFramebufferWithSize:size];
    [self drawWithClockwiseFrontFacingPolygons:YES];
  } else {
    [self setProjectionAndPixelSizeForFramebufferWithSize:size];
    [self drawWithClockwiseFrontFacingPolygons:NO];
  }
}

- (void)drawWithClockwiseFrontFacingPolygons:(BOOL)cwffPolygons {
  [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
    context.clockwiseFrontFacingPolygons = cwffPolygons;
    [self.context drawWithMode:LTDrawingContextDrawModeTriangles];
  }];
}

- (void)setProjectionAndPixelSizeForFramebufferWithSize:(CGSize)size {
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, 0, size.height, -1, 1);
  self.program[@"projection"] = $(projection);
  self.program[@"pixelSize"] = $(LTVector2(2 / size.width, 2 / size.height));
}

/// Since we're using a flipped projection matrix, the original order of vertices will generate a
/// back-faced polygon by default, as the test is performed on the projected coordinates.
/// a pixel size with negative y value is used since these values are added to the projected
/// coordinates inside the shader, and we would like to flip them to be consistent with the
/// projection. This way, when we use clockwise front facing polygons mode while drawing, we get
/// the desired results.
- (void)setProjectionAndPixelSizeForScreenFramebufferWithSize:(CGSize)size {
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, size.height, 0, -1, 1);
  self.program[@"projection"] = $(projection);
  self.program[@"pixelSize"] = $(LTVector2(2 / size.width, -2 / size.height));
}

- (void)setUniformsForGridRegion:(CGRect)region framebufferSize:(CGSize)size {
  self.program[@"modelview"] = $([self modelviewForGridRegion:region targetSize:size]);
  self.program[@"width"] = @(self.width);
  self.program[@"color"] = $(self.color * self.opacity);
}

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
