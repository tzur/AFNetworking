// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUResource.h"

@class LTArrayBuffer;
@class LTGPUStruct;

/// @class LTVertexArrayElement
///
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
- (id)initWithStructName:(NSString *)structName
             arrayBuffer:(LTArrayBuffer *)arrayBuffer
            attributeMap:(NSDictionary *)attributeMap;

/// GPU struct that composes the element.
@property (readonly, nonatomic) LTGPUStruct *gpuStruct;

/// Array buffer that contains data in the \c LTGPUStruct format.
@property (readonly, nonatomic) LTArrayBuffer *arrayBuffer;

/// Mapping between attribute name (\c NSString) to its corresponding \c LTGPUStructField.
@property (readonly, nonatomic) NSDictionary *attributeToField;

@end

/// @class LTVertexArray
///
/// Encapsulates an OpenGL vertex array object. The vertex array object is composed of multiple
/// \c LTVertexArrayElements, enabling the use of multiple \c LTGPUStruct objects in a single vertex
/// array. This makes program binding easy, since all the vertex attribute data required to map
/// buffer arrays to program attributes are contained in this class.
@interface LTVertexArray : NSObject <LTGPUResource>

/// Initializes a vertex array with a set of attributes. The array should contain at least one
/// attribute. Duplicate attributes will be ignored. Before drawing, all the given attributes must
/// be defined using \c addElement:.
- (id)initWithAttributes:(NSArray *)attributes;

/// Adds the given \c LTVertexArrayElement as an element in this vertex array. The element must
/// contain a GPU struct that don't exist in this vertex array, and attributes that are defined in
/// the initializer.
- (void)addElement:(LTVertexArrayElement *)element;

/// Returns an already added \c LTVertexArrayElement that corresponds to the given struct name. If
/// the given name is not mapped to an \c LTVertexArrayElement, \c nil will be returned.
- (LTVertexArrayElement *)elementForStructName:(NSString *)name;

/// Subscript getter that returns the matching \c LTVertexArrayElement for a given struct name.
///
/// @see elementForStructName: for more information.
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

/// Returns \c YES if the added elements contains a complete representation of this vertex array's
/// attributes.
@property (readonly, nonatomic) BOOL complete;

/// Returns all \c LTVertexArrayElement objects in this vertex array.
@property (readonly, nonatomic) NSArray *elements;

/// Vertex attributes that are being used in this vertex array.
@property (readonly, nonatomic) NSSet *attributes;

@end
