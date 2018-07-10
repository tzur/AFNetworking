// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTVertexArray.h"

#import "LTArrayBuffer.h"
#import "LTGLContext+Internal.h"
#import "LTGPUResourceProxy.h"
#import "LTGPUStruct.h"
#import "LTProgram.h"

#pragma mark -
#pragma mark LTVertexArrayElement
#pragma mark -

@interface LTVertexArrayElement ()

@property (readwrite, nonatomic) LTGPUStruct *gpuStruct;
@property (readwrite, nonatomic) LTArrayBuffer *arrayBuffer;
@property (readwrite, nonatomic) NSDictionary *attributeToField;

@end

@implementation LTVertexArrayElement

- (instancetype)initWithStructName:(NSString *)structName arrayBuffer:(LTArrayBuffer *)arrayBuffer
                      attributeMap:(NSDictionary *)attributeMap {
  if (self = [super init]) {
    LTAssert(arrayBuffer.type == LTArrayBufferTypeGeneric, @"Vertex array element can be only "
             "composed from generic array buffers");

    LTGPUStruct *gpuStruct = [[LTGPUStructRegistry sharedInstance] structForName:structName];
    LTAssert(gpuStruct, @"Given struct name '%@' is not registered as a GPU struct", structName);

    NSSet<NSString *> *gpuStructFields = [NSSet setWithArray:gpuStruct.fields.allKeys];
    NSSet<NSString *> *attributeFields = [NSSet setWithArray:attributeMap.allValues];
    LTAssert([gpuStructFields isEqualToSet:attributeFields], @"GPU struct fields must match the "
             "fields that are mapped from the given attribute list (%@ vs %@", gpuStructFields,
             attributeFields);

    self.gpuStruct = gpuStruct;
    self.arrayBuffer = arrayBuffer;

    // Create attribute name -> LTGPUStructField mapping.
    NSMutableDictionary *attributeToField = [NSMutableDictionary dictionary];
    for (NSString *attribute in attributeMap) {
      attributeToField[attribute] = gpuStruct.fields[attributeMap[attribute]];
    }
    self.attributeToField = attributeToField;
  }
  return self;
}

@end

#pragma mark -
#pragma mark LTVertexArray
#pragma mark -

@interface LTVertexArray ()

/// Vertex attributes that are being used in this vertex array.
@property (strong, nonatomic) NSSet<NSString *> *attributes;

/// Vertex attributes that are being used in this vertex array.
@property (strong, nonatomic) NSSet<LTVertexArrayElement *> *elements;

/// Maps struct name to an \c LTVertexArrayElement.
@property (strong, nonatomic) NSDictionary<NSString *, LTVertexArrayElement *> *structNameToElement;

/// Set to the previously bound vertex array, or \c 0 if the vertex array is not bound.
@property (nonatomic) GLint previousVertexArray;

/// YES if the texture is currently bound.
@property (nonatomic) BOOL bound;

/// OpenGL name of the vertex array.
@property (readwrite, nonatomic) GLuint name;

@end

@implementation LTVertexArray

@synthesize context = _context;

#pragma mark -
#pragma mark Initialization and destruction
#pragma mark -

- (instancetype)initWithElements:(NSSet<LTVertexArrayElement *> *)elements {
  LTParameterAssert(elements.count,
                    @"Given vertex array element set must contain at least one element");
  LTGPUResourceProxy * _Nullable proxy = nil;
  if (self = [super init]) {
    _context = [LTGLContext currentContext];

    [self validateElements:elements];
    [self setupWithElements:elements];

    [self.context executeForOpenGLES2:^{
      glGenVertexArraysOES(1, &self->_name);
    } openGLES3:^{
      glGenVertexArrays(1, &self->_name);
    }];
    LTGLCheck(@"Failed generating vertex array");
    proxy = [[LTGPUResourceProxy alloc] initWithResource:self];
    [self.context addResource:nn((typeof(self))proxy)];
  }
  return (typeof(self))proxy;
}

- (void)dealloc {
  [self dispose];
}

- (void)dispose {
  if (!self.name || !self.context) {
    return;
  }

  [self.context removeResource:self];
  [self unbind];
  [self.context executeForOpenGLES2:^{
    glDeleteVertexArraysOES(1, &self->_name);
  } openGLES3:^{
    glDeleteVertexArrays(1, &self->_name);
  }];
  LTGLCheck(@"Failed deleting vertex array");
  _name = 0;
}

- (void)validateElements:(NSSet<LTVertexArrayElement *> *)elements {
  NSMutableSet<NSString *> *gpuStructNames = [NSMutableSet setWithCapacity:elements.count];
  NSMutableSet<NSString *> *attributes = [NSMutableSet set];

  for (LTVertexArrayElement *element in elements) {
    LTParameterAssert(![gpuStructNames containsObject:element.gpuStruct.name],
                      @"At least two GPU structs with equal name (%@) found",
                      element.gpuStruct.name);
    [gpuStructNames addObject:element.gpuStruct.name];

    NSSet<NSString *> *additionalAttributes = [NSSet setWithArray:element.attributeToField.allKeys];
    LTParameterAssert(![additionalAttributes intersectsSet:attributes], @"Attributes (%@) of "
                      "element (%@) intersect with attributes (%@) of previous elements",
                      additionalAttributes, element, attributes);

    [attributes addObjectsFromArray:[additionalAttributes allObjects]];
  }
}

- (void)setupWithElements:(NSSet<LTVertexArrayElement *> *)elements {
  NSMutableDictionary<NSString *, LTVertexArrayElement *> *mapping =
      [NSMutableDictionary dictionary];
  NSMutableSet<NSString *> *attributes = [NSMutableSet set];

  for (LTVertexArrayElement *element in elements) {
    mapping[element.gpuStruct.name] = element;
    [attributes addObjectsFromArray:element.attributeToField.allKeys];
  }

  self.attributes = [attributes copy];
  self.elements = [elements copy];
  self.structNameToElement = [mapping copy];
}

#pragma mark -
#pragma mark Keyed Subscript
#pragma mark -

- (id)objectForKeyedSubscript:(NSString *)key {
  return self.structNameToElement[key];
}

#pragma mark -
#pragma mark Binding and unbinding
#pragma mark -

- (void)bind {
  if (self.bound) {
    return;
  }

  [self.context executeForOpenGLES2:^{
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &self->_previousVertexArray);
    glBindVertexArrayOES(self.name);
  } openGLES3:^{
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &self->_previousVertexArray);
    glBindVertexArray(self.name);
  }];

  self.bound = YES;
}

- (void)unbind {
  if (!self.bound) {
    return;
  }

  [self.context executeForOpenGLES2:^{
    glBindVertexArrayOES(self.previousVertexArray);
  } openGLES3:^{
    glBindVertexArray(self.previousVertexArray);
  }];
  self.previousVertexArray = 0;

  self.bound = NO;
}

- (void)bindAndExecute:(NS_NOESCAPE LTVoidBlock)block {
  LTParameterAssert(block);
  if (self.bound) {
    block();
  } else {
    [self bind];
    block();
    [self unbind];
  }
}

- (void)attachAttributesToIndices:(NSDictionary *)attributeToIndex {
  NSSet<NSString *> *attributes = [NSSet setWithArray:[attributeToIndex allKeys]];
  LTAssert([attributes isEqualToSet:self.attributes],
           @"Program contains different set of attibutes than the ones specified in the vertex "
           "array (%@ vs %@)", attributes, self.attributes);

  [self bindAndExecute:^{
    for (LTVertexArrayElement *element in self.elements) {
      [element.arrayBuffer bindAndExecute:^{
        for (NSString *attribute in element.attributeToField) {
          GLuint index = [attributeToIndex[attribute] unsignedIntValue];
          glEnableVertexAttribArray(index);

          // Struct with single element is always tightly packed.
          GLsizei stride = (GLsizei)(element.gpuStruct.fields.count == 1
                                     ? 0 : element.gpuStruct.size);

          LTGPUStructField *field = element.attributeToField[attribute];
          glVertexAttribPointer(index, field.componentCount,
                                field.componentType,
                                field.normalized ? GL_TRUE : GL_FALSE,
                                stride, (GLvoid *)field.offset);
          LTGLCheckDbg(@"Error while setting vertex attrib pointer");
        }
      }];
    }
  }];

  LTGLCheckDbg(@"Error while binding vertex array to attributes");
}

- (GLsizei)count {
  GLsizei elementCount = 0;

  for (NSString *structName in self.structNameToElement) {
    LTVertexArrayElement *element = self.structNameToElement[structName];

    LTAssert(element.arrayBuffer.size % element.gpuStruct.size == 0,
             @"Array buffer size includes a fractional struct (buffer size: %lu, struct size: %lu",
             (unsigned long)element.arrayBuffer.size, element.gpuStruct.size);

    GLsizei thisElementCount = (GLsizei)(element.arrayBuffer.size / element.gpuStruct.size);
    if (!elementCount) {
      elementCount = thisElementCount;
    }

    LTAssert(elementCount == thisElementCount, @"Array buffer holds a different number of elements "
             "than previous registered buffers (%d vs %d)", thisElementCount, elementCount);
  }

  return elementCount;
}

@end
