// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTVertexArray.h"

#import "LTArrayBuffer.h"
#import "LTGPUStruct.h"
#import "LTProgram.h"

LTGPUStructMake(SingleFieldStruct,
                GLKVector4, intensity);

LTGPUStructMake(MultipleFieldsStruct,
                GLKVector2, position,
                GLKVector2, texcoord);

static LTVertexArrayElement *LTArrayElementForMultipleFieldsStruct() {
  NSDictionary *attributeMap = @{@"position": @"position", @"texcoord": @"texcoord"};
  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                             usage:LTArrayBufferUsageStaticDraw];

  LTVertexArrayElement *element = [[LTVertexArrayElement alloc]
                                   initWithStructName:@"MultipleFieldsStruct"
                                   arrayBuffer:arrayBuffer
                                   attributeMap:attributeMap];

  return element;
}

static LTVertexArrayElement *LTArrayElementForSingleFieldsStruct() {
  NSDictionary *attributeMap = @{@"intensity": @"intensity"};
  LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                             usage:LTArrayBufferUsageStaticDraw];

  return [[LTVertexArrayElement alloc]
          initWithStructName:@"SingleFieldStruct"
          arrayBuffer:arrayBuffer
          attributeMap:attributeMap];
}

static LTVertexArray *LTVertexArrayWithTwoStructs() {
  LTVertexArrayElement *singleFieldElement = LTArrayElementForSingleFieldsStruct();
  LTVertexArrayElement *multipleFieldsElement = LTArrayElementForMultipleFieldsStruct();

  NSSet *attributes = [[NSSet setWithArray:singleFieldElement.attributeToField.allKeys]
                       setByAddingObjectsFromArray:multipleFieldsElement.attributeToField.allKeys];

  LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithAttributes:attributes];
  [vertexArray addElement:singleFieldElement];
  [vertexArray addElement:multipleFieldsElement];

  return vertexArray;
}

typedef void (^LTVertexArrayEnumerationBlock)(NSString *attribute, LTGPUStruct *gpuStruct,
                                              LTGPUStructField *field);

static void LTEnumerateVertexArray(LTVertexArray *vertexArray, NSArray *structNames,
                                   LTVertexArrayEnumerationBlock block) {
  NSMutableArray *elements = [NSMutableArray array];
  for (NSString *structName in structNames) {
    [elements addObject:vertexArray[structName]];
  }

  [vertexArray bindAndExecute:^{
    for (LTVertexArrayElement *element in elements) {
      for (NSString *attribute in element.attributeToField.allKeys) {
        if (block) {
          block(attribute, element.gpuStruct, element.attributeToField[attribute]);
        }
      }
    }
  }];
}

SpecBegin(LTVertexArrayElement)

context(@"initialization", ^{
  NSDictionary *attributeMap = @{@"position": @"position", @"texcoord": @"texcoord"};

  it(@"should initialize with a valid configuration", ^{
    LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                               usage:LTArrayBufferUsageStaticDraw];

    LTVertexArrayElement *element = [[LTVertexArrayElement alloc]
                                     initWithStructName:@"MultipleFieldsStruct"
                                     arrayBuffer:arrayBuffer
                                     attributeMap:attributeMap];

    expect(element.gpuStruct.name).equal(@"MultipleFieldsStruct");
    expect(element.arrayBuffer).equal(arrayBuffer);
    expect(element.attributeToField.allKeys).equal(attributeMap.allKeys);
  });

  it(@"should not initialize with element buffer", ^{
    LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeElement
                                                               usage:LTArrayBufferUsageStaticDraw];

    expect(^{
      __unused LTVertexArrayElement *element = [[LTVertexArrayElement alloc]
                                                initWithStructName:@"MultipleFieldsStruct"
                                                arrayBuffer:arrayBuffer
                                                attributeMap:attributeMap];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should not initialize with incomplete attribute map", ^{
    LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeElement
                                                               usage:LTArrayBufferUsageStaticDraw];

    expect(^{
      __unused LTVertexArrayElement *element = [[LTVertexArrayElement alloc]
                                                initWithStructName:@"MultipleFieldsStruct"
                                                arrayBuffer:arrayBuffer
                                                attributeMap:@{@"position": @"position"}];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should not initialize with overcomplete attribute map", ^{
    LTArrayBuffer *arrayBuffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeElement
                                                               usage:LTArrayBufferUsageStaticDraw];

    NSMutableDictionary *overComplete = [NSMutableDictionary dictionaryWithDictionary:attributeMap];
    overComplete[@"field"] = @"field";

    expect(^{
      __unused LTVertexArrayElement *element = [[LTVertexArrayElement alloc]
                                                initWithStructName:@"MultipleFieldsStruct"
                                                arrayBuffer:arrayBuffer
                                                attributeMap:overComplete];
    }).to.raise(NSInternalInconsistencyException);
  });
});

SpecEnd

SpecBegin(LTVertexArray)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

it(@"should fail initializing with empty attribute", ^{
  expect(^{
    __unused LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithAttributes:[NSSet set]];
  }).to.raise(NSInternalInconsistencyException);
});

context(@"binding", ^{
  __block LTVertexArray *vertexArray;

  beforeEach(^{
    vertexArray = [[LTVertexArray alloc] initWithAttributes:[NSSet setWithArray:@[@"foo"]]];
  });

  afterEach(^{
    vertexArray = nil;
  });

  it(@"should bind", ^{
    [vertexArray bind];

    GLint boundedArray;
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &boundedArray);

    expect(boundedArray).to.equal(vertexArray.name);
  });

  it(@"should unbind", ^{
    [vertexArray bind];
    [vertexArray unbind];

    GLint boundedArray;
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &boundedArray);

    expect(boundedArray).to.equal(0);
  });

  it(@"should conform binding scope of bindAndExecute", ^{
    __block GLint boundedArray;
    [vertexArray bindAndExecute:^{
      glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &boundedArray);
      expect(boundedArray).to.equal(vertexArray.name);
    }];

    glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &boundedArray);
    expect(boundedArray).to.equal(0);
  });
});

context(@"adding elements", ^{
  it(@"should be initially incomplete", ^{
    NSSet *attributes = [NSSet setWithArray:@[@"dummy"]];
    LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithAttributes:attributes];
    expect(vertexArray.isComplete).toNot.beTruthy();
  });

  it(@"should fail when adding an existing struct", ^{
    LTVertexArrayElement *element = LTArrayElementForSingleFieldsStruct();
    NSSet *attributes = [NSSet setWithArray:element.attributeToField.allKeys];

    LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithAttributes:attributes];
    [vertexArray addElement:element];

    expect(^{
      [vertexArray addElement:element];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should fail when adding element with unknown attribute", ^{
    LTVertexArrayElement *element = LTArrayElementForSingleFieldsStruct();
    NSSet *attributes = [NSSet setWithArray:@[@"dummy"]];

    LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithAttributes:attributes];

    expect(^{
      [vertexArray addElement:element];
    }).to.raise(NSInternalInconsistencyException);
  });
});

context(@"retrieving elements", ^{
  __block LTVertexArray *vertexArray;
  __block LTVertexArrayElement *element;

  beforeEach(^{
    element = LTArrayElementForSingleFieldsStruct();
    NSSet *attributes = [NSSet setWithArray:element.attributeToField.allKeys];

    vertexArray = [[LTVertexArray alloc] initWithAttributes:attributes];
    [vertexArray addElement:element];
  });

  it(@"should retrieve element with correct struct name", ^{
    expect([vertexArray elementForStructName:@"SingleFieldStruct"]).to.equal(element);
    expect(vertexArray[@"SingleFieldStruct"]).to.equal(element);
  });

  it(@"should return nil with invalid struct name", ^{
    expect([vertexArray elementForStructName:@"Foo"]).to.beNil();
    expect(vertexArray[@"Foo"]).to.beNil();
  });
});

context(@"one struct single field", ^{
  it(@"should become complete", ^{
    LTVertexArrayElement *element = LTArrayElementForSingleFieldsStruct();
    NSSet *attributes = [NSSet setWithArray:element.attributeToField.allKeys];

    LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithAttributes:attributes];
    [vertexArray addElement:element];

    expect(vertexArray.isComplete).to.beTruthy();
  });
});

context(@"one struct multiple fields", ^{
  it(@"should become complete", ^{
    LTVertexArrayElement *element = LTArrayElementForMultipleFieldsStruct();
    NSSet *attributes = [NSSet setWithArray:element.attributeToField.allKeys];

    LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithAttributes:attributes];
    [vertexArray addElement:element];

    expect(vertexArray.isComplete).to.beTruthy();
  });
});

context(@"multiple structs multiple fields", ^{
  __block LTVertexArrayElement *singleFieldElement;
  __block LTVertexArrayElement *multipleFieldsElement;
  __block LTVertexArray *vertexArray;

  beforeEach(^{
    singleFieldElement = LTArrayElementForSingleFieldsStruct();
    multipleFieldsElement = LTArrayElementForMultipleFieldsStruct();

    NSSet *attributes =
        [[NSSet setWithArray:singleFieldElement.attributeToField.allKeys]
         setByAddingObjectsFromArray:multipleFieldsElement.attributeToField.allKeys];
    vertexArray = [[LTVertexArray alloc] initWithAttributes:attributes];
  });

  it(@"should not become complete when adding single element", ^{
    [vertexArray addElement:singleFieldElement];
    expect(vertexArray.isComplete).toNot.beTruthy();
  });

  it(@"should become complete after adding all elements", ^{
    [vertexArray addElement:singleFieldElement];
    [vertexArray addElement:multipleFieldsElement];
    expect(vertexArray.isComplete).to.beTruthy();
  });
});

context(@"element count", ^{
  const NSUInteger kElementCount = 4;

  __block LTVertexArray *vertexArray;

  beforeEach(^{
    vertexArray = LTVertexArrayWithTwoStructs();
  });

  afterEach(^{
    vertexArray = nil;
  });

  it(@"should return correct element count", ^{
    NSMutableData *singleFieldData =
        [NSMutableData dataWithLength:kElementCount * sizeof(SingleFieldStruct)];
    [[vertexArray[@"SingleFieldStruct"] arrayBuffer] setData:singleFieldData];

    NSMutableData *multipleFieldsData =
        [NSMutableData dataWithLength:kElementCount * sizeof(MultipleFieldsStruct)];
    [[vertexArray[@"MultipleFieldsStruct"] arrayBuffer] setData:multipleFieldsData];

    expect(vertexArray.count).to.equal(kElementCount);
  });

  it(@"should raise when array buffer size is not aligned with struct size", ^{
    NSMutableData *singleFieldData =
        [NSMutableData dataWithLength:kElementCount * sizeof(SingleFieldStruct) - 1];
    [[vertexArray[@"SingleFieldStruct"] arrayBuffer] setData:singleFieldData];

    NSMutableData *multipleFieldsData =
        [NSMutableData dataWithLength:kElementCount * sizeof(MultipleFieldsStruct)];
    [[vertexArray[@"MultipleFieldsStruct"] arrayBuffer] setData:multipleFieldsData];

    expect(^{
      [vertexArray count];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should raise when array buffers element count are not equal", ^{
    NSMutableData *singleFieldData =
        [NSMutableData dataWithLength:(kElementCount - 1) * sizeof(SingleFieldStruct)];
    [[vertexArray[@"SingleFieldStruct"] arrayBuffer] setData:singleFieldData];

    NSMutableData *multipleFieldsData =
        [NSMutableData dataWithLength:kElementCount * sizeof(MultipleFieldsStruct)];
    [[vertexArray[@"MultipleFieldsStruct"] arrayBuffer] setData:multipleFieldsData];

    expect(^{
      [vertexArray count];
    }).to.raise(NSInternalInconsistencyException);
  });
});

context(@"vertex attrib configuration", ^{
  const NSUInteger kElementCount = 4;

  __block LTVertexArray *vertexArray;
  __block LTProgram *program;

  beforeEach(^{
    vertexArray = LTVertexArrayWithTwoStructs();

    NSMutableData *singleFieldData =
        [NSMutableData dataWithLength:kElementCount * sizeof(SingleFieldStruct)];
    [[vertexArray[@"SingleFieldStruct"] arrayBuffer] setData:singleFieldData];

    NSMutableData *multipleFieldsData =
        [NSMutableData dataWithLength:kElementCount * sizeof(MultipleFieldsStruct)];
    [[vertexArray[@"MultipleFieldsStruct"] arrayBuffer] setData:multipleFieldsData];

    NSString *vertexSource = @"attribute highp vec2 position; "
        "attribute highp vec2 texcoord; "
        "attribute highp vec4 intensity; "
        "void main() { position; texcoord; intensity; gl_Position = vec4(0.0); }";
    NSString *fragmentSource = @"void main() { gl_FragColor = vec4(0.0); }";

    program = [[LTProgram alloc] initWithVertexSource:vertexSource fragmentSource:fragmentSource];
  });

  afterEach(^{
    vertexArray = nil;
  });

  it(@"should enable all shader attributes", ^{
    [vertexArray attachToProgram:program];

    [vertexArray bindAndExecute:^{
      for (NSString *attribute in program.attributes) {
        GLint vertexAttribArrayEnabled = 0;
        glGetVertexAttribiv([program attributeForName:attribute], GL_VERTEX_ATTRIB_ARRAY_ENABLED,
                            &vertexAttribArrayEnabled);

        expect(vertexAttribArrayEnabled).toNot.equal(0);
      }
    }];
  });

  it(@"should set correct element size", ^{
    [vertexArray attachToProgram:program];

    LTEnumerateVertexArray(vertexArray, @[@"SingleFieldStruct", @"MultipleFieldsStruct"],
      ^(NSString *attribute, LTGPUStruct *, LTGPUStructField *field) {
       GLint arraySize = 0;
       glGetVertexAttribiv([program attributeForName:attribute], GL_VERTEX_ATTRIB_ARRAY_SIZE,
                           &arraySize);

       expect(arraySize).to.equal(field.componentCount);
    });
  });

  it(@"should set correct type", ^{
    [vertexArray attachToProgram:program];

    LTEnumerateVertexArray(vertexArray, @[@"SingleFieldStruct", @"MultipleFieldsStruct"],
      ^(NSString *attribute, LTGPUStruct *, LTGPUStructField *field) {
       GLint arrayStride = 0;
       glGetVertexAttribiv([program attributeForName:attribute], GL_VERTEX_ATTRIB_ARRAY_TYPE,
                           &arrayStride);

       expect(arrayStride).to.equal(field.componentType);
    });
  });

  it(@"should set correct stride", ^{
    [vertexArray attachToProgram:program];

    LTEnumerateVertexArray(vertexArray, @[@"SingleFieldStruct", @"MultipleFieldsStruct"],
      ^(NSString *attribute, LTGPUStruct *gpuStruct, LTGPUStructField *) {
       GLint arrayStride = 0;
       glGetVertexAttribiv([program attributeForName:attribute], GL_VERTEX_ATTRIB_ARRAY_STRIDE,
                           &arrayStride);

       expect(arrayStride).to.equal(gpuStruct.size);
    });
  });

  it(@"should not require field normalization", ^{
    LTEnumerateVertexArray(vertexArray, @[@"SingleFieldStruct", @"MultipleFieldsStruct"],
      ^(NSString *attribute, LTGPUStruct *, LTGPUStructField *) {
       GLint arrayNormalize = 0;
       glGetVertexAttribiv([program attributeForName:attribute], GL_VERTEX_ATTRIB_ARRAY_NORMALIZED,
                           &arrayNormalize);

       expect(arrayNormalize).to.equal(GL_FALSE);
    });
  });
});

SpecEnd
