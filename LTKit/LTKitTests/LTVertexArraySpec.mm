// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTVertexArray.h"

#import "LTArrayBuffer.h"
#import "LTGPUResourceExamples.h"
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

  NSArray *attributes = [singleFieldElement.attributeToField.allKeys
      arrayByAddingObjectsFromArray:multipleFieldsElement.attributeToField.allKeys];

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

LTSpecBegin(LTVertexArray)

it(@"should fail initializing with empty attribute", ^{
  expect(^{
    __unused LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithAttributes:@[]];
  }).to.raise(NSInternalInconsistencyException);
});

context(@"binding", ^{
  __block LTVertexArray *vertexArray;

  beforeEach(^{
    vertexArray = [[LTVertexArray alloc] initWithAttributes:@[@"foo"]];
  });

  afterEach(^{
    vertexArray = nil;
  });

  itShouldBehaveLike(kLTResourceExamples, ^{
    return @{kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:vertexArray],
             kLTResourceExamplesOpenGLParameterName: @GL_VERTEX_ARRAY_BINDING_OES};
  });
});

context(@"adding elements", ^{
  it(@"should be initially incomplete", ^{
    LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithAttributes:@[@"dummy"]];
    expect(vertexArray.complete).toNot.beTruthy();
  });

  it(@"should fail when adding an existing struct", ^{
    LTVertexArrayElement *element = LTArrayElementForSingleFieldsStruct();
    LTVertexArray *vertexArray = [[LTVertexArray alloc]
                                  initWithAttributes:element.attributeToField.allKeys];
    [vertexArray addElement:element];

    expect(^{
      [vertexArray addElement:element];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should fail when adding element with unknown attribute", ^{
    LTVertexArrayElement *element = LTArrayElementForSingleFieldsStruct();
    LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithAttributes:@[@"dummy"]];

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
    vertexArray = [[LTVertexArray alloc] initWithAttributes:element.attributeToField.allKeys];
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

  it(@"should retrieve element list", ^{
    expect(vertexArray.elements).to.equal(@[vertexArray[@"SingleFieldStruct"]]);
  });
});

context(@"one struct single field", ^{
  it(@"should become complete", ^{
    LTVertexArrayElement *element = LTArrayElementForSingleFieldsStruct();
    LTVertexArray *vertexArray = [[LTVertexArray alloc]
                                  initWithAttributes:element.attributeToField.allKeys];
    [vertexArray addElement:element];

    expect(vertexArray.complete).to.beTruthy();
  });
});

context(@"one struct multiple fields", ^{
  it(@"should become complete", ^{
    LTVertexArrayElement *element = LTArrayElementForMultipleFieldsStruct();
    LTVertexArray *vertexArray = [[LTVertexArray alloc]
                                  initWithAttributes:element.attributeToField.allKeys];
    [vertexArray addElement:element];

    expect(vertexArray.complete).to.beTruthy();
  });
});

context(@"multiple structs multiple fields", ^{
  __block LTVertexArrayElement *singleFieldElement;
  __block LTVertexArrayElement *multipleFieldsElement;
  __block LTVertexArray *vertexArray;

  beforeEach(^{
    singleFieldElement = LTArrayElementForSingleFieldsStruct();
    multipleFieldsElement = LTArrayElementForMultipleFieldsStruct();

    NSArray *attributes =
        [singleFieldElement.attributeToField.allKeys
         arrayByAddingObjectsFromArray:multipleFieldsElement.attributeToField.allKeys];
    vertexArray = [[LTVertexArray alloc] initWithAttributes:attributes];
  });

  it(@"should not become complete when adding single element", ^{
    [vertexArray addElement:singleFieldElement];
    expect(vertexArray.complete).toNot.beTruthy();
  });

  it(@"should become complete after adding all elements", ^{
    [vertexArray addElement:singleFieldElement];
    [vertexArray addElement:multipleFieldsElement];
    expect(vertexArray.complete).to.beTruthy();
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
  NSDictionary * const kAttributeToIndex = @{
    @"position": @(0),
    @"texcoord": @(1),
    @"intensity": @(2)
  };

  __block LTVertexArray *vertexArray;

  beforeEach(^{
    vertexArray = LTVertexArrayWithTwoStructs();

    NSMutableData *singleFieldData =
        [NSMutableData dataWithLength:kElementCount * sizeof(SingleFieldStruct)];
    [[vertexArray[@"SingleFieldStruct"] arrayBuffer] setData:singleFieldData];

    NSMutableData *multipleFieldsData =
        [NSMutableData dataWithLength:kElementCount * sizeof(MultipleFieldsStruct)];
    [[vertexArray[@"MultipleFieldsStruct"] arrayBuffer] setData:multipleFieldsData];

    [vertexArray attachAttributesToIndices:kAttributeToIndex];
  });

  afterEach(^{
    vertexArray = nil;
  });

  it(@"should enable all shader attributes", ^{
    [vertexArray bindAndExecute:^{
      for (NSString *attribute in kAttributeToIndex) {
        GLint vertexAttribArrayEnabled = 0;
        glGetVertexAttribiv([kAttributeToIndex[attribute] unsignedIntValue],
                            GL_VERTEX_ATTRIB_ARRAY_ENABLED, &vertexAttribArrayEnabled);

        expect(vertexAttribArrayEnabled).toNot.equal(0);
      }
    }];
  });

  it(@"should set correct element size", ^{
    LTEnumerateVertexArray(vertexArray, @[@"SingleFieldStruct", @"MultipleFieldsStruct"],
      ^(NSString *attribute, LTGPUStruct *, LTGPUStructField *field) {
       GLint arraySize = 0;
       glGetVertexAttribiv([kAttributeToIndex[attribute] unsignedIntValue],
                           GL_VERTEX_ATTRIB_ARRAY_SIZE, &arraySize);

       expect(arraySize).to.equal(field.componentCount);
    });
  });

  it(@"should set correct type", ^{
    LTEnumerateVertexArray(vertexArray, @[@"SingleFieldStruct", @"MultipleFieldsStruct"],
      ^(NSString *attribute, LTGPUStruct *, LTGPUStructField *field) {
       GLint arrayStride = 0;
       glGetVertexAttribiv([kAttributeToIndex[attribute] unsignedIntValue],
                           GL_VERTEX_ATTRIB_ARRAY_TYPE, &arrayStride);

       expect(arrayStride).to.equal(field.componentType);
    });
  });

  it(@"should set correct stride", ^{
    LTEnumerateVertexArray(vertexArray, @[@"SingleFieldStruct", @"MultipleFieldsStruct"],
      ^(NSString *attribute, LTGPUStruct *gpuStruct, LTGPUStructField *) {
       GLint arrayStride = 0;
       glGetVertexAttribiv([kAttributeToIndex[attribute] unsignedIntValue],
                           GL_VERTEX_ATTRIB_ARRAY_STRIDE, &arrayStride);

       expect(arrayStride).to.equal(gpuStruct.size);
    });
  });

  it(@"should not require field normalization", ^{
    LTEnumerateVertexArray(vertexArray, @[@"SingleFieldStruct", @"MultipleFieldsStruct"],
      ^(NSString *attribute, LTGPUStruct *, LTGPUStructField *) {
       GLint arrayNormalize = 0;
       glGetVertexAttribiv([kAttributeToIndex[attribute] unsignedIntValue],
                           GL_VERTEX_ATTRIB_ARRAY_NORMALIZED, &arrayNormalize);

       expect(arrayNormalize).to.equal(GL_FALSE);
    });
  });
});

LTSpecEnd
