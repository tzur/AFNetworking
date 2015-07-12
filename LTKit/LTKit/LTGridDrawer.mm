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
#import "LTShaderStorage+LTGridDrawerVsh.h"
#import "LTShaderStorage+LTGridDrawerFsh.h"
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
  return vertexData;
}

/// Creates the vertices for the horizontal grid lines according to the grid size. See comment above
/// (\c verticesForVerticalGridLines) for more details.
- (std::vector<LTGridDrawerVertex>) verticesForHorizontalGridLines {
  std::vector<LTGridDrawerVertex> vertexData;
  CGFloat gridSpacing = 1.0;
  GLfloat width = self.size.width;
  for (GLfloat y = 0; y <= self.size.height; y += gridSpacing) {
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
