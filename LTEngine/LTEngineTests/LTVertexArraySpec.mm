// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTVertexArray.h"

#import <LTKit/NSArray+NSSet.h>

#import "LTArrayBuffer.h"
#import "LTGLContext.h"
#import "LTGPUResourceExamples.h"
#import "LTGPUStruct.h"
#import "LTProgram.h"

LTGPUStructMake(SingleFieldStruct,
                LTVector4, intensity);

LTGPUStructMake(AnotherSingleFieldStruct,
                LTVector4, color);

LTGPUStructMakeNormalized(MultipleFieldsStruct,
                          LTVector2, position, NO,
                          LTVector2, texcoord, NO,
                          GLbyte, byteValue, NO,
                          GLubyte, unsignedByteValue, YES);

static LTArrayBuffer *LTDummyArrayBuffer() {
  return [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                       usage:LTArrayBufferUsageStaticDraw];
}

static LTVertexArrayElement *LTArrayElementForMultipleFieldsStruct() {
  NSDictionary *attributeMap = @{
    @"position": @"position",
    @"texcoord": @"texcoord",
    @"byteValue": @"byteValue",
    @"unsignedByteValue": @"unsignedByteValue"
  };

  LTVertexArrayElement *element = [[LTVertexArrayElement alloc]
                                   initWithStructName:@"MultipleFieldsStruct"
                                   arrayBuffer:LTDummyArrayBuffer()
                                   attributeMap:attributeMap];

  return element;
}

static LTVertexArrayElement *LTArrayElementForSingleFieldsStruct() {
  NSDictionary *attributeMap = @{@"intensity": @"intensity"};

  return [[LTVertexArrayElement alloc]
          initWithStructName:@"SingleFieldStruct"
          arrayBuffer:LTDummyArrayBuffer()
          attributeMap:attributeMap];
}

static LTVertexArray *LTVertexArrayWithTwoStructs() {
  LTVertexArrayElement *singleFieldElement = LTArrayElementForSingleFieldsStruct();
  LTVertexArrayElement *multipleFieldsElement = LTArrayElementForMultipleFieldsStruct();

  return [[LTVertexArray alloc] initWithElements:[NSSet setWithArray:@[singleFieldElement,
                                                                       multipleFieldsElement]]];
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
  NSDictionary *attributeMap = @{
    @"position": @"position",
    @"texcoord": @"texcoord",
    @"byteValue": @"byteValue",
    @"unsignedByteValue": @"unsignedByteValue"
  };

  it(@"should initialize with a valid configuration", ^{
    LTArrayBuffer *arrayBuffer = LTDummyArrayBuffer();

    LTVertexArrayElement *element = [[LTVertexArrayElement alloc]
                                     initWithStructName:@"MultipleFieldsStruct"
                                     arrayBuffer:arrayBuffer
                                     attributeMap:attributeMap];

    expect(element.gpuStruct.name).equal(@"MultipleFieldsStruct");
    expect(element.arrayBuffer).equal(arrayBuffer);
    expect(element.attributeToField.allKeys.lt_set).equal(attributeMap.allKeys.lt_set);
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

context(@"initialization", ^{
  it(@"should fail initializing with empty attribute", ^{
    expect(^{
      __unused LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithElements:[NSSet set]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initializing with elements with identical gpu struct names", ^{
    LTVertexArrayElement *element = LTArrayElementForSingleFieldsStruct();
    NSDictionary<NSString *, NSString *> *attributeMap =
        @{@"anotherAttribute": @"intensity"};
    LTVertexArrayElement *anotherElement =
        [[LTVertexArrayElement alloc] initWithStructName:element.gpuStruct.name
                                             arrayBuffer:LTDummyArrayBuffer()
                                            attributeMap:attributeMap];
    NSSet<LTVertexArrayElement *> *elements = [NSSet setWithArray:@[element, anotherElement]];

    expect(^{
      __unused LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithElements:elements];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initializing with elements with overlapping attributes", ^{
    LTVertexArrayElement *element = LTArrayElementForSingleFieldsStruct();
    LTVertexArrayElement *anotherElement =
        [[LTVertexArrayElement alloc] initWithStructName:@"AnotherSingleFieldStruct"
                                             arrayBuffer:LTDummyArrayBuffer()
                                            attributeMap:@{@"intensity": @"color"}];
    NSSet<LTVertexArrayElement *> *elements = [NSSet setWithArray:@[element, anotherElement]];

    expect(^{
      __unused LTVertexArray *vertexArray = [[LTVertexArray alloc] initWithElements:elements];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"binding", ^{
  __block LTVertexArray *vertexArray;

  beforeEach(^{
    LTVertexArrayElement *element = LTArrayElementForSingleFieldsStruct();
    vertexArray = [[LTVertexArray alloc] initWithElements:[NSSet setWithObject:element]];
  });

  afterEach(^{
    vertexArray = nil;
  });

  itShouldBehaveLike(kLTResourceExamples, ^{
    return @{
      kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:vertexArray],
      kLTResourceExamplesOpenGLParameterName: @GL_VERTEX_ARRAY_BINDING,
      kLTResourceExamplesIsResourceFunction:
          [NSValue valueWithPointer:(const void *)glIsVertexArray]
    };
  });
});

context(@"retrieving elements", ^{
  __block LTVertexArray *vertexArray;
  __block LTVertexArrayElement *element;

  beforeEach(^{
    element = LTArrayElementForSingleFieldsStruct();
    vertexArray = [[LTVertexArray alloc] initWithElements:[NSSet setWithObject:element]];
  });

  it(@"should retrieve element with correct struct name", ^{
    expect(vertexArray[@"SingleFieldStruct"]).to.equal(element);
  });

  it(@"should return nil with invalid struct name", ^{
    expect(vertexArray[@"Foo"]).to.beNil();
  });

  it(@"should retrieve element list", ^{
    expect(vertexArray.elements)
        .to.equal([NSSet setWithObject:vertexArray[@"SingleFieldStruct"]]);
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
    @"byteValue": @(2),
    @"unsignedByteValue": @(3),
    @"intensity": @(4)
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

  it(@"should correctly require or not require field normalization", ^{
    LTEnumerateVertexArray(vertexArray, @[@"SingleFieldStruct", @"MultipleFieldsStruct"],
      ^(NSString *attribute, LTGPUStruct *, LTGPUStructField *field) {
       GLint arrayNormalize = 0;

       glGetVertexAttribiv([kAttributeToIndex[attribute] unsignedIntValue],
                           GL_VERTEX_ATTRIB_ARRAY_NORMALIZED, &arrayNormalize);

        GLint expectedValue =
            [field.name isEqualToString:@"unsignedByteValue"] ? GL_TRUE : GL_FALSE;

       expect(arrayNormalize).to.equal(expectedValue);
    });
  });
});

SpecEnd
