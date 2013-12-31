// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectDrawer.h"

#import "LTArrayBuffer.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTGPUStruct.h"
#import "LTProgram.h"
#import "LTVertexArray.h"
#import "LTTexture.h"

/// Holds the position and texture coordinate of each of the rect's corners.
LTGPUStructMake(LTRectDrawerVertex,
                GLKVector2, position,
                GLKVector2, texcoord);

@interface LTRectDrawer ()

/// Program to use when drawing the rect.
@property (strong, nonatomic) LTProgram *program;

/// Context holding the geometry and program.
@property (strong, nonatomic) LTDrawingContext *context;

/// Source texture to draw from.
@property (strong, nonatomic) LTTexture *texture;

/// Set of mandatory uniforms that must exist in the given program.
@property (readonly, nonatomic) NSSet *mandatoryUniforms;

@end

@implementation LTRectDrawer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (id)initWithProgram:(LTProgram *)program {
  return [self initWithProgram:program sourceTexture:nil];
}

- (id)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture {
  if (self = [super init]) {
    LTAssert([self.mandatoryUniforms isSubsetOfSet:program.uniforms], @"At least one of the "
             "required uniforms %@ doesn't exist in the given program", self.mandatoryUniforms);

    self.texture = texture;
    self.program = program;
    self.context = [self createDrawingContext];
  }
  return self;
}

- (LTDrawingContext *)createDrawingContext {
  LTVertexArray *vertexArray = [self createVertexArray];

  NSDictionary *uniformToTexture = self.texture ? @{@"sourceTexture": self.texture} : nil;
  LTDrawingContext *context = [[LTDrawingContext alloc] initWithProgram:self.program
                                                            vertexArray:vertexArray
                                                       uniformToTexture:uniformToTexture];
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
          initWithStructName:@"LTRectDrawerVertex"
          arrayBuffer:arrayBuffer
          attributeMap:@{@"position": @"position",
                         @"texcoord": @"texcoord"}];
}

- (LTArrayBuffer *)createArrayBuffer {
  std::vector<LTRectDrawerVertex> vertexData{
    {.position = {{0, 0}}, .texcoord = {{0, 0}}},
    {.position = {{1, 0}}, .texcoord = {{1, 0}}},
    {.position = {{0, 1}}, .texcoord = {{0, 1}}},
    {.position = {{1, 1}}, .texcoord = {{1, 1}}},
  };

  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                             usage:LTArrayBufferUsageStaticDraw];
  [arrayBuffer setData:[NSData dataWithBytesNoCopy:&vertexData[0]
                                            length:vertexData.size() * sizeof(LTRectDrawerVertex)
                                      freeWhenDone:NO]];

  return arrayBuffer;
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)drawRect:(CGRect)targetRect inFramebuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect {
  [fbo bindAndExecute:^{
    GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, fbo.size.width, 0, fbo.size.height, -1, 1);
    self.program[@"projection"] = [NSValue valueWithGLKMatrix4:projection];
    [self drawRect:targetRect fromRect:sourceRect];
  }];
}

- (void)drawRect:(CGRect)targetRect inScreenFramebufferWithSize:(CGSize)size
        fromRect:(CGRect)sourceRect {
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, size.height, 0, -1, 1);
  self.program[@"projection"] = [NSValue valueWithGLKMatrix4:projection];
  [self drawRect:targetRect fromRect:sourceRect];
}

- (void)drawRect:(CGRect)targetRect fromRect:(CGRect)sourceRect {
  LTAssert(self.texture, @"Source texture was not set prior to drawing");

  GLKMatrix4 modelview = [self matrix4ForRect:targetRect];
  self.program[@"modelview"] = [NSValue valueWithGLKMatrix4:modelview];

  GLKMatrix3 texture = [self matrix3ForTextureRect:sourceRect];
  self.program[@"texture"] = [NSValue valueWithGLKMatrix3:texture];

  [self.context drawWithMode:LTDrawingContextDrawModeTriangleStrip];
}

- (GLKMatrix3)matrix3ForTextureRect:(CGRect)rect {
  CGRect normalizedRect = CGRectMake(rect.origin.x / self.texture.size.width,
                                     rect.origin.y / self.texture.size.height,
                                     rect.size.width / self.texture.size.width,
                                     rect.size.height / self.texture.size.height);
  return [self matrix3ForRect:normalizedRect];
}

- (GLKMatrix3)matrix3ForRect:(CGRect)rect {
  GLKMatrix3 scale = GLKMatrix3MakeScale(rect.size.width, rect.size.height, 1);
  GLKMatrix3 translate = GLKMatrix3MakeTranslation(rect.origin.x, rect.origin.y);
  return GLKMatrix3Multiply(translate, scale);
}

- (GLKMatrix4)matrix4ForRect:(CGRect)rect {
  GLKMatrix4 scale = GLKMatrix4MakeScale(rect.size.width, rect.size.height, 1);
  GLKMatrix4 translate = GLKMatrix4MakeTranslation(rect.origin.x, rect.origin.y, 0);
  return GLKMatrix4Multiply(translate, scale);
}

#pragma mark -
#pragma mark Uniforms
#pragma mark -

- (void)setSourceTexture:(LTTexture *)texture {
  if ([self.texture isEqual:texture]) {
    return;
  }

  self.texture = texture;
  [self.context attachUniform:@"sourceTexture" toTexture:texture];
}

- (void)setUniform:(NSString *)name withValue:(id)value {
  LTAssert(![name isEqualToString:@"position"] &&
           ![name isEqualToString:@"texcoord"], @"Uniform name cannot be one of %@",
           self.mandatoryUniforms);

  self.program[name] = value;
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
  [self setUniform:key withValue:obj];
}

- (NSSet *)mandatoryUniforms {
  static NSSet *uniforms;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    uniforms = [NSSet setWithArray:@[@"projection", @"modelview", @"texture"]];
  });

  return uniforms;
}

@end
