// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUResource.h"

@class LTArrayBuffer;
@class LTGPUStruct;

/// Coordinator which connects three entities:
///
/// - \c LTGPUStruct object, which gives metadata on structs that can be placed on the GPU.
///
/// - \c LTArrayBuffer, which holds an array of the \c LTGPUStruct on the GPU.
///
/// - Mapping between attribute name which is defined in a program to its corresponding \c
/// LTGPUStructField.
///
/// A single \c LTVertexArrayElement element contains all the data needed to correctly map a data
/// structure of a specific \c LTGPUStruct to the GPU memory using OpenGL.
@interface LTVertexArrayElement : NSObject

/// Initializes a new vertex array element, after verifying that there's a 1-to-1 mapping between
/// struct fields and attributes.
///
/// @param structName name of GPU struct that composes the element. The struct must be defined as an
/// \c LTGPUStruct beforehand.
/// @param arrayBuffer array buffer that contains data in the \c LTGPUStruct format. The array
/// buffer must be of type \c LTArrayBufferTypeGeneric.
/// @param attributeMap mapping between attribute name (\c NSString) to \c LTGPUStruct field name
/// (\c NSString)
- (instancetype)initWithStructName:(NSString *)structName
                       arrayBuffer:(LTArrayBuffer *)arrayBuffer
                      attributeMap:(NSDictionary *)attributeMap;

/// GPU struct that composes the element.
@property (readonly, nonatomic) LTGPUStruct *gpuStruct;

/// Array buffer that contains data in the \c LTGPUStruct format.
@property (readonly, nonatomic) LTArrayBuffer *arrayBuffer;

/// Mapping between attribute name (\c NSString) to its corresponding \c LTGPUStructField.
@property (readonly, nonatomic) NSDictionary *attributeToField;

@end

/// Immutable object representing an OpenGL vertex array object. The vertex array object is composed
/// of multiple \c LTVertexArrayElements, enabling the use of multiple \c LTGPUStruct objects in a
/// single vertex array. This makes program binding easy, since all the vertex attribute data
/// required to map buffer arrays to program attributes are contained in this class.
@interface LTVertexArray : NSObject <LTGPUResource>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c elements. The \c elements must contain at least one element. The
/// \c name of the \c LTGPUStruct object of an element must be different from the \c name of
/// \c LTGPUStruct object of any other element. Analogously, the attribute names of an element must
/// be different from the attribute names of any other element.
- (instancetype)initWithElements:(NSSet<LTVertexArrayElement *> *)elements
    NS_DESIGNATED_INITIALIZER;

/// Subscript getter that returns an already added \c LTVertexArrayElement that corresponds to the
/// given struct name. If the given name is not mapped to an \c LTVertexArrayElement, \c nil will
/// be returned.
- (id)objectForKeyedSubscript:(NSString *)key;

/// Attaches the receiver to concrete vertex attribute indices, using the given attribute to index
/// mapping. The given \c attributeToIndex dictionary must have the same set of attributes as the
/// receiver, and the receiver must be complete (see \c complete) before attaching.
- (void)attachAttributesToIndices:(NSDictionary *)attributeToIndex;

/// Retrieves number of vertices defined by this vertex array.
///
/// @note this method verifies that the element count in each attached \c LTArrayBuffer is equal,
/// and that each buffer size is an integer multiplication of it's corresponding struct size.
- (GLsizei)count;

/// Returns all \c LTVertexArrayElement objects in this vertex array.
@property (readonly, nonatomic) NSSet<LTVertexArrayElement *> *elements;

/// Vertex attributes that are being used in this vertex array.
@property (readonly, nonatomic) NSSet<NSString *> *attributes;

@end
