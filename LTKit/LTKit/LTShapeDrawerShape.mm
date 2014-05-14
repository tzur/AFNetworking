// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerShape.h"

#import "LTArrayBuffer.h"
#import "LTDrawingContext.h"
#import "LTProgram.h"
#import "LTPropertyMacros.h"
#import "LTShaderStorage+LTShapeDrawerShapeVsh.h"
#import "LTShapeDrawerParams.h"
#import "LTVertexArray.h"

#pragma mark -
#pragma mark Common Utility Methods
#pragma mark -

LTGPUStructImplement(LTShapeDrawerVertex,
                     GLKVector2, position,
                     GLKVector2, offset,
                     GLKVector4, lineBounds,
                     GLKVector4, shadowBounds,
                     GLKVector4, color,
                     GLKVector4, shadowColor);

@interface LTCommonDrawableShape () {
  LTShapeDrawerVertices _strokeVertices;
  LTShapeDrawerVertices _shadowVertices;
}

@property (strong, nonatomic) LTShapeDrawerParams *params;
@property (strong, nonatomic) LTProgram *program;
@property (strong, nonatomic) LTDrawingContext *context;
@property (strong, nonatomic) LTArrayBuffer *arrayBuffer;

@end

@implementation LTCommonDrawableShape

LTBoundedPrimitivePropertyImplement(CGFloat, opacity, Opacity, 0, 1, 1);

/// Strores the programs used for each type of shape, to reuse them instead of reallocating them
/// every time.
///
/// @note This is a temporary solution until the \c LTShaderCache is implemented. This solution does
/// not support working with multiple \c LTGLContexts.
static NSMutableDictionary *cachedPrograms;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithParams:(LTShapeDrawerParams *)params {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cachedPrograms = [NSMutableDictionary dictionary];
  });
  
  if (self = [super init]) {
    self.params = params ? [params copy] : [[LTShapeDrawerParams alloc] init];
    self.opacity = self.defaultOpacity;
    self.program = [self cachedProgram];
    self.arrayBuffer = [self createArrayBuffer];
    self.context = [self createDrawingContext];
  }
  return self;
}

- (LTProgram *)cachedProgram {
  if (!cachedPrograms[[self class]]) {
    cachedPrograms[[self class]] = [self createProgram];
  }
  return cachedPrograms[[self class]];
}

- (LTDrawingContext *)createDrawingContext {
  LTAssert(self.program, @"Program must be initialized before creating the drawing context");
  LTVertexArray *vertexArray = [self createVertexArray];
  return [[LTDrawingContext alloc] initWithProgram:self.program vertexArray:vertexArray
                                  uniformToTexture:nil];
}

- (LTVertexArray *)createVertexArray {
  LTAssert(self.arrayBuffer, @"Array buffer must be initialized before creating the vertex array");
  LTVertexArray *vertexArray = [[LTVertexArray alloc]
                                initWithAttributes:[self vertexShaderAttributes]];
  LTVertexArrayElement *element = [self createVertexArrayElementWithArrayBuffer:self.arrayBuffer];
  [vertexArray addElement:element];
  return vertexArray;
}

- (LTVertexArrayElement *)createVertexArrayElementWithArrayBuffer:(LTArrayBuffer *)arrayBuffer {
  return [[LTVertexArrayElement alloc]
          initWithStructName:[self vertexShaderStructName] arrayBuffer:arrayBuffer
          attributeMap:[self attributeMapFromArray:[self vertexShaderAttributes]]];
}

- (NSDictionary *)attributeMapFromArray:(NSArray *)attributes {
  NSMutableDictionary *map = [NSMutableDictionary dictionary];
  for (NSString *attribute in attributes) {
    map[attribute] = attribute;
  }
  return [map copy];
}

- (LTArrayBuffer *)createArrayBuffer {
  return [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                       usage:LTArrayBufferUsageStreamDraw];
}

#pragma mark -
#pragma mark Protected Interface
#pragma mark -

- (LTProgram *)createProgram {
  LTMethodNotImplemented();
}

- (NSString *)vertexShaderStructName {
  return @"LTShapeDrawerVertex";
}

- (NSArray *)vertexShaderAttributes {
  return @[@"position", @"offset", @"lineBounds", @"shadowBounds", @"color", @"shadowColor"];
}

- (void)updateBuffer {
  NSUInteger numVertices = self.strokeVertices.size() + self.shadowVertices.size();
  NSMutableData *data = [NSMutableData dataWithLength:numVertices * sizeof(LTShapeDrawerVertex)];
  if (!self.shadowVertices.empty()) {
    memcpy(data.mutableBytes, &self.shadowVertices[0],
           self.shadowVertices.size() * sizeof(LTShapeDrawerVertex));
  }
  if (!self.strokeVertices.empty()) {
    memcpy((char *)data.mutableBytes + self.shadowVertices.size() * sizeof(LTShapeDrawerVertex),
           &self.strokeVertices[0], self.strokeVertices.size() * sizeof(LTShapeDrawerVertex));
  }
  [self.arrayBuffer setData:data];
}

#pragma mark -
#pragma mark For Testing
#pragma mark -

+ (void)clearPrograms {
  [cachedPrograms removeAllObjects];
}

@end
