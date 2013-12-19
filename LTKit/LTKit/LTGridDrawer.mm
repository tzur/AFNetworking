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
#import "LTVertexArray.h"

// Shaders used for drawing the pixel grid.
static NSString * const kVertexShaderSource =
    @"uniform highp mat4 modelview;"
     "uniform highp mat4 projection;"
     "uniform highp vec2 pixelSize;"
     "uniform highp float width;"
     "attribute highp vec4 position;"
     "attribute highp vec2 offset;"
     "void main() {"
        "highp vec4 new_position = position - vec4(offset, 0.0, 0.0);"
        "new_position = projection * modelview * new_position;"
        "new_position.xy += (offset * pixelSize * width * new_position.w);"
        "gl_Position = new_position;"
     "}";
static NSString * const kFragmentShaderSource =
    @"uniform mediump vec4 color;"
     "void main() {gl_FragColor = color;}";

/// Holds the position of each grid line vertex.
LTGPUStructMake(LTGridDrawerVertex, GLKVector2, position, GLKVector2, offset);

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
static UIColor * const kDefaultColor = [UIColor colorWithWhite:1.0 alpha:1.0];
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
  return [[LTProgram alloc] initWithVertexSource:kVertexShaderSource
                                  fragmentSource:kFragmentShaderSource];
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
  // Create the vertices for the grid lines according to the grid size.
  // Ideally, we would use two degenerate triangles for each grid line, and the vertex shader would
  // update their values according to the offset, pixel size, and width to create a rectangle with
  // the desired width.
  // However, since openGL automatically discards degenerate triangles a hack was necessary, adding
  // the offset to the position as well, with the vertex shader subtracting it before applying the
  // modelview and projection transformations.
  std::vector<LTGridDrawerVertex> vertexData;
  CGFloat jump = 1.0;
  GLfloat height = self.size.height;
  GLfloat width = self.size.width;
  for (GLfloat x = 0; x <= self.size.width; x += jump) {
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
  for (GLfloat y = 0; y <= self.size.height; y += jump) {
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
  
  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                             usage:LTArrayBufferUsageStaticDraw];
  [arrayBuffer setData:[NSData dataWithBytesNoCopy:&vertexData[0]
                                            length:vertexData.size() * sizeof(LTGridDrawerVertex)
                                      freeWhenDone:NO]];
  return arrayBuffer;
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

  // Calculate the modelview matrix according to the desired region and framebuffer size.
  CGFloat scaleX = size.width / region.size.width;
  CGFloat scaleY = size.height / region.size.height;
  GLKMatrix4 modelview = GLKMatrix4MakeScale(scaleX, scaleY, 1.0);
  modelview = GLKMatrix4Translate(modelview, -region.origin.x, -region.origin.y, 0.0);
  
  self.program[@"width"] = @(self.width);
  self.program[@"modelview"] = [NSValue valueWithGLKMatrix4:modelview];
  self.program[@"projection"] = [NSValue valueWithGLKMatrix4:projection];
  self.program[@"pixelSize"] =
      [NSValue valueWithGLKVector2:GLKVector2Make(2 / size.width, 2 / size.height)];
  [self updateProgramColor];

  glEnable(GL_BLEND);
  glBlendEquation(GL_FUNC_ADD);
  glBlendFuncSeparate(GL_ONE, GL_ONE_MINUS_SRC_ALPHA, GL_ONE_MINUS_DST_ALPHA, GL_ONE);
  [self.context drawWithMode:LTDrawingContextDrawModeTriangles];
  glDisable(GL_BLEND);
}

#pragma mark -
#pragma mark Utility
#pragma mark -

/// Updates the shader's color uniform according to the grid's color and opacity.
- (void)updateProgramColor {
  CGFloat r,g,b,a;
  GLKVector4 color;
  if ([self.color getRed:&r green:&g blue:&b alpha:&a]) {
    color = GLKVector4Make(r, g, b, a);
  } else if ([self.color getWhite:&r alpha:&a]) {
    color = GLKVector4Make(r, r, r, a);
  } else {
    LogError(@"Could not set grid color, invalid color: %@", self.color);
    return;
  }
  
  // Premultiply the opacity, and set the uniform.
  self.program[@"color"] =
      [NSValue valueWithGLKVector4:GLKVector4MultiplyScalar(color, self.opacity)];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setOpacity:(CGFloat)opacity {
  _opacity = MIN(MAX(opacity, 0), 1);
}

@end
