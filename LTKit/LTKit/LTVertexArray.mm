// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTVertexArray.h"

#import "LTArrayBuffer.h"
#import "LTGLContext.h"
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

    NSSet *gpuStructFields = [NSSet setWithArray:gpuStruct.fields.allKeys];
    NSSet *attributeFields = [NSSet setWithArray:attributeMap.allValues];
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
@property (strong, nonatomic) NSSet *attributes;

/// Vertex attributes the are left unattached. For the vertex array to be complete, this set needs
/// to be empty.
@property (strong, nonatomic) NSSet *unattachedAttributes;

/// Maps struct name to an \c LTVertexArrayElement.
@property (strong, nonatomic) NSMutableDictionary *structNameToElement;

/// Set to the previously bound vertex array, or \c 0 if the vertex array is not bound.
@property (nonatomic) GLint previousVertexArray;

/// YES if the texture is currently bound.
@property (nonatomic) BOOL bound;

/// OpenGL name of the vertex array.
@property (readwrite, nonatomic) GLuint name;

@end

@implementation LTVertexArray

#pragma mark -
#pragma mark Initialization and destruction
#pragma mark -

- (instancetype)initWithAttributes:(NSArray *)attributes {
  if (self = [super init]) {
    LTAssert(attributes.count, @"Given attributes set must contain at least one attribute");
    
    self.attributes = [NSSet setWithArray:attributes];
    self.unattachedAttributes = self.attributes;
    self.structNameToElement = [NSMutableDictionary dictionary];

    [[LTGLContext currentContext] executeForOpenGLES2:^{
      glGenVertexArraysOES(1, &_name);
    } openGLES3:^{
      glGenVertexArrays(1, &_name);
    }];
    LTGLCheck(@"Failed generating vertex array");
  }
  return self;
}

- (void)dealloc {
  [self unbind];
  [[LTGLContext currentContext] executeForOpenGLES2:^{
    glDeleteVertexArraysOES(1, &_name);
  } openGLES3:^{
    glDeleteVertexArrays(1, &_name);
  }];
  LTGLCheck(@"Failed deleting vertex array");
}

#pragma mark -
#pragma mark Elements
#pragma mark -

- (void)addElement:(LTVertexArrayElement *)element {
  LTAssert(!self.structNameToElement[element.gpuStruct.name], @"Given struct name '%@' already "
           "added to this vertex array", element.gpuStruct.name);

  NSSet *attributes = [NSSet setWithArray:element.attributeToField.allKeys];
  LTAssert([attributes isSubsetOfSet:self.unattachedAttributes],
           @"Given attributes are not a subset of the unattached array attributes (%@ vs. %@)",
           attributes, self.unattachedAttributes);

  self.structNameToElement[element.gpuStruct.name] = element;

  // Remove given attributes from the set of the unattached attributes.
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSString *attribute,
                                                                 NSDictionary *) {
    return ![attributes containsObject:attribute];
  }];
  self.unattachedAttributes = [self.unattachedAttributes filteredSetUsingPredicate:predicate];
}

- (LTVertexArrayElement *)elementForStructName:(NSString *)name {
  return self.structNameToElement[name];
}

- (id)objectForKeyedSubscript:(NSString *)key {
  return [self elementForStructName:key];
}

#pragma mark -
#pragma mark Binding and unbinding
#pragma mark -

- (void)bind {
  if (self.bound) {
    return;
  }

  [[LTGLContext currentContext] executeForOpenGLES2:^{
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &_previousVertexArray);
    glBindVertexArrayOES(self.name);
  } openGLES3:^{
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &_previousVertexArray);
    glBindVertexArray(self.name);
  }];

  self.bound = YES;
}

- (void)unbind {
  if (!self.bound) {
    return;
  }

  [[LTGLContext currentContext] executeForOpenGLES2:^{
    glBindVertexArrayOES(self.previousVertexArray);
  } openGLES3:^{
    glBindVertexArray(self.previousVertexArray);
  }];
  self.previousVertexArray = 0;

  self.bound = NO;
}

- (void)bindAndExecute:(LTVoidBlock)block {
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
  LTAssert(self.complete, @"Vertex array must be complete before attaching a program");

  NSSet *attributes = [NSSet setWithArray:[attributeToIndex allKeys]];
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
                                field.componentType, GL_FALSE, stride, (GLvoid *)field.offset);
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

- (BOOL)complete {
  return !self.unattachedAttributes.count;
}

- (NSArray *)elements {
  return [self.structNameToElement allValues];
}

@end
