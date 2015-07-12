// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUStructsMacros.h"

/// @class LTGPUStructField
///
/// Holds data about a single member of a GPU struct.
@interface LTGPUStructField : NSObject

/// Initializes with field name, offset in struct, type as string and the field's size.
- (instancetype)initWithName:(NSString *)name type:(NSString *)type size:(size_t)size
                   andOffset:(size_t)offset;

/// Name of the field.
@property (readonly, nonatomic) NSString *name;

/// Type of the field, as string.
@property (readonly, nonatomic) NSString *type;

/// Size of the field in bytes.
@property (readonly, nonatomic) size_t size;

/// Offset of the field in the struct.
@property (readonly, nonatomic) size_t offset;

/// OpenGL component type (such as \c GL_FLOAT, \c GL_UNSIGNED_SHORT) matching the field's \c type.
@property (readonly, nonatomic) GLenum componentType;

/// OpenGL number of components (will be in the range [1, 4]).
@property (readonly, nonatomic) GLint componentCount;

@end

/// @class LTGPUStruct
///
/// Holds data about a struct that can be placed on the GPU.
@interface LTGPUStruct : NSObject

/// Initializes with struct name, size in bytes and \c NSArray of \c LTGPUStructField objects.
- (instancetype)initWithName:(NSString *)name size:(size_t)size andFields:(NSArray *)fields;

/// Name of the struct.
@property (readonly, nonatomic) NSString *name;

/// Size of the struct in bytes.
@property (readonly, nonatomic) size_t size;

/// Dictionary of field name to its corresponding \c LTGPUStructField object.
@property (readonly, nonatomic) NSDictionary *fields;

@end

/// @class LTGPUStructRegistry
///
/// Registry of all structs that need to be represented on the GPU using LTKit.
@interface LTGPUStructRegistry : NSObject

/// Retrieves the singleton instance.
+ (instancetype)sharedInstance;

/// Registers a GPU struct in the repository.
- (void)registerStruct:(LTGPUStruct *)gpuStruct;

/// Returns struct field information for the given struct name. If the struct doesn't exist in the
/// repository, \c nil is returned.
- (LTGPUStruct *)structForName:(NSString *)name;

@end
